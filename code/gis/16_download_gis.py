"""Download the open GIS inputs for the instruments (run once; skips existing files).

Sources (checked 2026-09-30; logged in data/SOURCES.md):
- INEI district boundaries: https://ide.inei.gob.pe/files/Distrito.rar (RAR5, extracted
  with Windows tar.exe / libarchive) -> data/raw/inei_boundaries/DISTRITO.gpkg
- OpenStreetMap roads, Geofabrik snapshot of 2017-01-01 (pre-inflow network), ODbL:
  https://download.geofabrik.de/south-america/peru-170101-free.shp.zip
- GHSL population 2015 (R2023A, WGS84, 3 arc-seconds), JRC, CC BY 4.0: tiles R10-11 x C10-12
- Copernicus DEM GLO-90 (3 arc-seconds), AWS open data registry: 1x1 degree tiles that
  intersect Peru. Tiles over open ocean do not exist (HTTP 404) and are skipped.

GLO-90 is used instead of GLO-30 to keep the download near 0.5 GB; district-level
population-weighted altitude does not need 30 m resolution.
"""

import math
import subprocess
import zipfile
from pathlib import Path

import geopandas as gpd
import requests
from shapely.geometry import box

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"

GHSL = ("https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/"
        "GHS_POP_E2015_GLOBE_R2023A_4326_3ss/V1-0/tiles/")
DEM = "https://copernicus-dem-90m.s3.amazonaws.com/"


def fetch(url, dest, timeout=600):
    if dest.exists() and dest.stat().st_size > 0:
        return "exists"
    dest.parent.mkdir(parents=True, exist_ok=True)
    r = requests.get(url, stream=True, timeout=timeout)
    if r.status_code == 404:
        return "404"
    r.raise_for_status()
    with open(dest, "wb") as f:
        for chunk in r.iter_content(1 << 20):
            f.write(chunk)
    return "ok"


def main():
    # Boundaries
    rar = RAW / "inei_boundaries" / "Distrito.rar"
    fetch("https://ide.inei.gob.pe/files/Distrito.rar", rar)
    if not (RAW / "inei_boundaries" / "DISTRITO.gpkg").exists():
        subprocess.run([r"C:\Windows\System32\tar.exe", "-xf", str(rar)],
                       cwd=rar.parent, check=True)

    # OSM roads, 2017-01-01
    z = RAW / "osm" / "peru-170101-free.shp.zip"
    fetch("https://download.geofabrik.de/south-america/peru-170101-free.shp.zip", z, 1800)
    out = RAW / "osm" / "peru-170101"
    if not (out / "gis_osm_roads_free_1.shp").exists():
        with zipfile.ZipFile(z) as zz:
            zz.extractall(out, members=[n for n in zz.namelist() if "roads" in n])

    # GHSL 2015 population tiles (R11_C10 is ocean and does not exist)
    for r in (10, 11):
        for c in (10, 11, 12):
            name = f"GHS_POP_E2015_GLOBE_R2023A_4326_3ss_V1_0_R{r}_C{c}"
            status = fetch(GHSL + name + ".zip", RAW / "ghsl" / (name + ".zip"))
            if status != "404" and not (RAW / "ghsl" / (name + ".tif")).exists():
                with zipfile.ZipFile(RAW / "ghsl" / (name + ".zip")) as zz:
                    zz.extractall(RAW / "ghsl")

    # DEM tiles intersecting Peru
    peru = gpd.read_file(RAW / "inei_boundaries" / "DISTRITO.gpkg").union_all()
    xmin, ymin, xmax, ymax = peru.bounds
    counts = {"ok": 0, "exists": 0, "404": 0}
    for lat in range(math.floor(ymin), math.ceil(ymax)):
        for lon in range(math.floor(xmin), math.ceil(xmax)):
            if not peru.intersects(box(lon, lat, lon + 1, lat + 1)):
                continue
            ns = f"{'N' if lat >= 0 else 'S'}{abs(lat):02d}_00"
            ew = f"{'E' if lon >= 0 else 'W'}{abs(lon):03d}_00"
            name = f"Copernicus_DSM_COG_30_{ns}_{ew}_DEM"
            counts[fetch(f"{DEM}{name}/{name}.tif", RAW / "dem_glo90" / f"{name}.tif")] += 1
    print("DEM tiles:", counts)


if __name__ == "__main__":
    main()
