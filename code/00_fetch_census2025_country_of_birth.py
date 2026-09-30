"""Fetch 2025 census counts of foreign-born population by country of birth, by district.

Source: INEI, Censos Nacionales 2025, results platform (censos2025.inei.gob.pe),
dashboard "Inmigración extranjera". The public API returns, for each district, the
six most frequent countries of birth among the foreign-born (indicators 301-306)
and the foreign-born total (indicator 131). The API geography ID is "9" followed
by the INEI ubigeo.

Caveat: only the top six countries are reported. If Venezuela is not among them,
its count is not returned; this happens only in districts with very few immigrants.

Output: data/raw/census2025/census2025_foreign_born_top6_by_district.csv (long format)
"""

import time
from pathlib import Path

import pandas as pd
import requests

ROOT = Path(__file__).resolve().parents[1]
DISTRICTS = ROOT / "data" / "Consulta de población por Sexo, según nivel Distrital.xlsx"
OUT = ROOT / "data" / "raw" / "census2025" / "census2025_foreign_born_top6_by_district.csv"
API = "https://censos2025.inei.gob.pe/api/v1/resultados"


def get(url, params, tries=4):
    for i in range(tries):
        try:
            r = requests.get(url, params=params, timeout=30)
            r.raise_for_status()
            return r.json()["data"]
        except Exception:
            time.sleep(2 * (i + 1))
    raise RuntimeError(f"failed: {url} {params}")


def main():
    d = pd.read_excel(DISTRICTS, header=None, skiprows=6, dtype={1: str})
    ubigeos = d.loc[d[1].str.fullmatch(r"\d{6}", na=False), 1].tolist()

    rows = []
    for k, ub in enumerate(ubigeos, 1):
        gid = "9" + ub
        top = get(f"{API}/etiqueta-indicadores",
                  {"idIndicador": "301,302,303,304,305,306", "idTiempo": 2025, "idGeografia": gid})
        tot = get(f"{API}/dashboard-kpis",
                  {"idTiempo": 2025, "idGeografia": gid, "indicadores": 131})
        total = tot[0]["vAbsolutoSinFormt"] if tot else None
        top = [t for t in top if t["nombTema"]]
        if not top:
            rows.append({"ubigeo": ub, "rank": None, "country": None, "country_code": None,
                         "count": None, "pct_of_foreign_born": None, "foreign_born_total": total})
        for t in top:
            rows.append({"ubigeo": ub, "rank": t["idIndicador"] - 300, "country": t["nombTema"],
                         "country_code": t["codTema"], "count": t["vAbsoluto"],
                         "pct_of_foreign_born": t["vPorcentaje"], "foreign_born_total": total})
        if k % 100 == 0:
            print(f"{k}/{len(ubigeos)}", flush=True)
        time.sleep(0.15)

    pd.DataFrame(rows).to_csv(OUT, index=False)
    print("wrote", OUT, len(rows), "rows")


if __name__ == "__main__":
    main()
