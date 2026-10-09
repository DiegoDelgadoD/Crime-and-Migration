"""Road travel time and distance from the CEBAF Tumbes border post (instrument Z2).

Inputs: data/raw/osm/peru-170101/gis_osm_roads_free_1.shp (OSM, Geofabrik 2017-01-01)
        data/derived/gis/altitude.csv (population-weighted centroids, from 22)
        data/raw/ubigeo_crosswalk/ubigeo_distrito.csv (capital coordinates for the
        three census districts that the INEI boundary file lacks)
Output: data/derived/gis/travel_time_cebaf.csv
        (ubigeo, tt_cebaf_h, km_cebaf, tt_lima_h, km_gc_cebaf, snap_km, point_source)

Method. Every OSM way is split into vertex-to-vertex segments; ways that share
an OSM node share a coordinate, which keeps the network connected. Segment
time = length / speed by road class (below). The graph is undirected (one-way
restrictions ignored) and restricted to its largest connected component. Each
district point is snapped to the nearest network vertex; the snap distance is
added at 20 km/h. Travel time is the fastest path; km_cebaf is the length of
the shortest path (a separate run). The 2017-01-01 network predates the
inflow, so road building after 2017 cannot respond to it. Loreto districts
with no road link to the national network get large snap distances; they are
flagged by snap_km.

CEBAF Tumbes (Complejo Fronterizo de Zarumilla, km 1292 of the Panamericana
Norte, Aguas Verdes): -3.48466, -80.26082 (Wikipedia, checked 2026-09-29).
"""

from pathlib import Path

import geopandas as gpd
import numpy as np
import pandas as pd
import shapely
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components, dijkstra
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parents[2]
ROADS = ROOT / "data" / "raw" / "osm" / "peru-170101" / "gis_osm_roads_free_1.shp"
PTS = ROOT / "data" / "derived" / "gis" / "altitude.csv"
XWALK = ROOT / "data" / "raw" / "ubigeo_crosswalk" / "ubigeo_distrito.csv"
OUT = ROOT / "data" / "derived" / "gis" / "travel_time_cebaf.csv"

CEBAF = (-3.48466, -80.26082)
LIMA = (-12.0464, -77.0428)
OFFROAD_KMH = 20.0
SPEED = {  # km/h by Geofabrik fclass
    "motorway": 90, "trunk": 80, "primary": 70, "secondary": 55, "tertiary": 45,
    "motorway_link": 70, "trunk_link": 60, "primary_link": 55, "secondary_link": 45,
    "tertiary_link": 35, "unclassified": 35, "residential": 25, "living_street": 15,
    "service": 20, "unknown": 25, "track": 20, "track_grade1": 20, "track_grade2": 18,
    "track_grade3": 15, "track_grade4": 12, "track_grade5": 10,
}


def haversine_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(np.radians, (lat1, lon1, lat2, lon2))
    a = np.sin((lat2 - lat1) / 2) ** 2 + np.cos(lat1) * np.cos(lat2) * np.sin((lon2 - lon1) / 2) ** 2
    return 6371.0 * 2 * np.arcsin(np.sqrt(a))


def planar_km(lat, lon, lat0=-9.0):
    return np.column_stack([np.asarray(lon) * 111.32 * np.cos(np.radians(lat0)),
                            np.asarray(lat) * 110.57])


def main():
    roads = gpd.read_file(ROADS, columns=["fclass"])
    roads = roads[roads.fclass.isin(SPEED)].explode(index_parts=False).reset_index(drop=True)
    coords, idx = shapely.get_coordinates(roads.geometry.values, return_index=True)
    key = np.round(coords, 7)
    uniq, node = np.unique(key, axis=0, return_inverse=True)
    node = node.ravel()
    same = idx[1:] == idx[:-1]                       # consecutive vertices of one way
    a, b = node[:-1][same], node[1:][same]
    km = haversine_km(coords[:-1, 1][same], coords[:-1, 0][same],
                      coords[1:, 1][same], coords[1:, 0][same])
    speed = roads.fclass.map(SPEED).to_numpy()[idx[:-1][same]]
    keep = a != b
    a, b, km, hrs = a[keep], b[keep], km[keep], (km / speed)[keep]
    n = len(uniq)

    def graph(w):
        m = coo_matrix((np.r_[w, w], (np.r_[a, b], np.r_[b, a])), shape=(n, n)).tocsr()
        m.sum_duplicates()
        return m

    g_time, g_km = graph(hrs), graph(km)
    ncomp, lab = connected_components(g_time, directed=False)
    big = np.bincount(lab).argmax()
    in_big = lab == big
    print(f"network: {n:,} vertices, {len(a):,} segments, {ncomp:,} components; "
          f"largest has {in_big.sum():,} vertices")

    big_ids = np.nonzero(in_big)[0]
    tree = cKDTree(planar_km(uniq[big_ids, 1], uniq[big_ids, 0]))

    def snap(lat, lon):
        d, j = tree.query(planar_km(lat, lon))
        return big_ids[j], d

    # District points: population-weighted centroids, crosswalk capitals as fallback
    p = pd.read_csv(PTS, dtype={"ubigeo": str})[["ubigeo", "lat_popw", "lon_popw"]]
    p.columns = ["ubigeo", "lat", "lon"]
    p["point_source"] = "ghsl_popw_centroid"
    x = pd.read_csv(XWALK, dtype={"inei": str})[["inei", "latitude", "longitude"]]
    x = x[x.inei.str.fullmatch(r"\d{6}", na=False)]
    x.columns = ["ubigeo", "lat", "lon"]
    extra = x[~x.ubigeo.isin(p.ubigeo)].assign(point_source="crosswalk_capital")
    pts = pd.concat([p, extra], ignore_index=True).dropna(subset=["lat", "lon"])

    src_c, snap_c = snap(np.array([CEBAF[0]]), np.array([CEBAF[1]]))
    src_l, snap_l = snap(np.array([LIMA[0]]), np.array([LIMA[1]]))
    print(f"CEBAF snapped at {snap_c[0]:.2f} km, Lima at {snap_l[0]:.2f} km")
    t_c = dijkstra(g_time, directed=False, indices=src_c[0])
    d_c = dijkstra(g_km, directed=False, indices=src_c[0])
    t_l = dijkstra(g_time, directed=False, indices=src_l[0])

    nid, sd = snap(pts.lat.to_numpy(), pts.lon.to_numpy())
    pts["snap_km"] = sd
    pts["tt_cebaf_h"] = t_c[nid] + (sd + snap_c[0]) / OFFROAD_KMH
    pts["km_cebaf"] = d_c[nid] + sd + snap_c[0]
    pts["tt_lima_h"] = t_l[nid] + (sd + snap_l[0]) / OFFROAD_KMH
    pts["km_gc_cebaf"] = haversine_km(pts.lat, pts.lon, *CEBAF)
    assert np.isfinite(pts[["tt_cebaf_h", "km_cebaf", "tt_lima_h"]]).all().all()
    assert pts.ubigeo.is_unique

    OUT.parent.mkdir(parents=True, exist_ok=True)
    pts.to_csv(OUT, index=False, float_format="%.4f")
    print(f"21_travel_time_cebaf: {len(pts)} districts; median {pts.tt_cebaf_h.median():.1f} h "
          f"to CEBAF; snap > 5 km in {(pts.snap_km > 5).sum()} districts")


if __name__ == "__main__":
    main()
