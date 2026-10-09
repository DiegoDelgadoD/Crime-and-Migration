"""Population-weighted altitude and population-weighted centroid by district.

Inputs: data/raw/inei_boundaries/DISTRITO.gpkg
        data/raw/ghsl/GHS_POP_E2015_GLOBE_R2023A_4326_3ss_V1_0_R*_C*.tif (GHSL 2015)
        data/raw/dem_glo90/Copernicus_DSM_COG_30_*_DEM.tif (Copernicus GLO-90)
Output: data/derived/gis/altitude.csv
        (ubigeo, pop_ghsl15, alt_popw, alt_mean, alt_median, alt_sd,
         lat_popw, lon_popw, n_cells)

For each district, the GHSL 2015 grid (3 arc-seconds) inside the polygon
defines the cells; the DEM is resampled bilinearly onto that grid. The
weights are GHSL 2015 residential population, from before the Venezuelan
inflow. WorldPop is not used because its model uses elevation as a
covariate (scoping report, section 5). Where GHSL population in a district
is zero, the population-weighted fields fall back to the unweighted mean
and the geometric centroid (flag popw_fallback = 1).
"""

from pathlib import Path

import geopandas as gpd
import numpy as np
import pandas as pd
import rasterio
from rasterio.features import geometry_mask
from rasterio.merge import merge
from rasterio.warp import Resampling, reproject

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "data" / "derived" / "gis" / "altitude.csv"


def open_all(pattern):
    return [rasterio.open(p) for p in sorted((RAW / pattern[0]).glob(pattern[1]))]


def intersecting(srcs, b):
    return [s for s in srcs if not (s.bounds.right <= b[0] or s.bounds.left >= b[2]
                                    or s.bounds.top <= b[1] or s.bounds.bottom >= b[3])]


def main():
    g = gpd.read_file(RAW / "inei_boundaries" / "DISTRITO.gpkg")[["ubigeo", "geometry"]]
    g["geometry"] = g.geometry.make_valid()
    g = g.dissolve(by="ubigeo", as_index=False)
    pops = open_all(("ghsl", "GHS_POP_E2015_*.tif"))
    dems = open_all(("dem_glo90", "Copernicus_DSM_COG_30_*_DEM.tif"))
    assert len(pops) == 5 and len(dems) > 100

    rows = []
    for i, r in enumerate(g.itertuples(index=False), 1):
        b = r.geometry.bounds
        pad = 0.001
        bb = (b[0] - pad, b[1] - pad, b[2] + pad, b[3] + pad)
        pop, tr = merge(intersecting(pops, bb), bounds=bb, nodata=0)
        pop = pop[0].astype("float64")
        pop[pop < 0] = 0
        inside = ~geometry_mask([r.geometry], out_shape=pop.shape, transform=tr, all_touched=False)
        if inside.sum() == 0:   # very small polygon: take touched cells
            inside = ~geometry_mask([r.geometry], out_shape=pop.shape, transform=tr, all_touched=True)

        dem = np.full(pop.shape, np.nan, dtype="float64")
        for s in intersecting(dems, bb):
            tmp = np.full(pop.shape, np.nan, dtype="float64")
            reproject(rasterio.band(s, 1), tmp, dst_transform=tr, dst_crs="EPSG:4326",
                      resampling=Resampling.bilinear, dst_nodata=np.nan)
            dem = np.where(np.isnan(dem), tmp, dem)

        ok = inside & ~np.isnan(dem)
        w = pop[ok]
        z = dem[ok]
        rr, cc = np.nonzero(ok)
        xs, ys = rasterio.transform.xy(tr, rr, cc)
        xs, ys = np.asarray(xs), np.asarray(ys)
        fallback = w.sum() <= 0
        ww = np.ones_like(w) if fallback else w
        rows.append({
            "ubigeo": r.ubigeo,
            "pop_ghsl15": pop[inside].sum(),
            "alt_popw": np.average(z, weights=ww) if z.size else np.nan,
            "alt_mean": z.mean() if z.size else np.nan,
            "alt_median": np.median(z) if z.size else np.nan,
            "alt_sd": z.std() if z.size else np.nan,
            "lat_popw": np.average(ys, weights=ww) if z.size else np.nan,
            "lon_popw": np.average(xs, weights=ww) if z.size else np.nan,
            "n_cells": int(ok.sum()),
            "popw_fallback": int(fallback),
        })
        if i % 200 == 0:
            print(f"{i}/{len(g)}", flush=True)

    out = pd.DataFrame(rows)
    assert out.ubigeo.is_unique and len(out) == len(g)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT, index=False, float_format="%.4f")
    print(f"22_altitude_popw: {len(out)} districts; GHSL 2015 population {out.pop_ghsl15.sum():,.0f}; "
          f"fallback in {out.popw_fallback.sum()}; missing altitude in {out.alt_popw.isna().sum()}")


if __name__ == "__main__":
    main()
