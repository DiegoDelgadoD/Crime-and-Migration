"""District geometry: area and geometric centroid.

Input : data/raw/inei_boundaries/DISTRITO.gpkg (INEI IDE, 1,890 districts)
Output: data/derived/gis/district_geometry.csv
        (ubigeo, area_km2, lat_geo, lon_geo, dist_lima_km_gc)

Areas use the South America Albers equal-area projection (ESRI:102033).
Districts in the 2025 census but not in this file (three) are handled in
Stata (23_import_instruments.do) with the crosswalk capital coordinates.
"""

from pathlib import Path

import geopandas as gpd
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "data" / "raw" / "inei_boundaries" / "DISTRITO.gpkg"
OUT = ROOT / "data" / "derived" / "gis" / "district_geometry.csv"
LIMA = (-12.0464, -77.0428)   # Plaza de Armas de Lima


def haversine_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(np.radians, (lat1, lon1, lat2, lon2))
    a = np.sin((lat2 - lat1) / 2) ** 2 + np.cos(lat1) * np.cos(lat2) * np.sin((lon2 - lon1) / 2) ** 2
    return 6371.0 * 2 * np.arcsin(np.sqrt(a))


def main():
    g = gpd.read_file(SRC)[["ubigeo", "geometry"]]
    g["geometry"] = g.geometry.make_valid()
    g = g.dissolve(by="ubigeo", as_index=False)
    assert g.ubigeo.str.fullmatch(r"\d{6}").all()
    assert g.ubigeo.is_unique

    g["area_km2"] = g.to_crs("ESRI:102033").area / 1e6
    pt = g.geometry.representative_point()
    g["lat_geo"], g["lon_geo"] = pt.y, pt.x
    g["dist_lima_km_gc"] = haversine_km(g.lat_geo, g.lon_geo, *LIMA)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    g.drop(columns="geometry").to_csv(OUT, index=False, float_format="%.6f")
    print(f"17_district_geometry: {len(g)} districts, total area {g.area_km2.sum():,.0f} km2")


if __name__ == "__main__":
    main()
