# Data sources

Log of every dataset in `data/`, with where it came from and when it was downloaded.
Raw files are read-only: clean them in `code/` and write derived files elsewhere.

## Provided by Diego (data/)

| File | Source | Notes |
|---|---|---|
| `SINADEF_DATOS_ABIERTOS.csv` | MINSA, SINADEF open data | Death-level records, 2017–2026. `MUERTE_VIOLENTA` has a `HOMICIDIO` category. `COD_UBIGEO_DOMICILIO` uses RENIEC coding in the format `92-33-DD-PP-dd-000` (Lima = 14, Callao = 24), not INEI coding. |
| `Consulta de población por Sexo, según nivel Distrital.xlsx` | INEI, Censos Nacionales 2025, "Consulta de población" | Total population by sex, 1,893 districts. Data as of 15 July 2026. Uses INEI ubigeo. Department labels split Lima into "Lima Metropolitana" and "Región Lima"; Callao appears as "Prov. Const. del Callao". |
| `Consulta de población por Población inmigrante extranjera por grandes grupos edad, según nivel Distrital.xlsx` | INEI, Censos Nacionales 2025 | All foreign-born immigrants (not Venezuelan only) by age group, district level. National total 1,052,977. |

## Downloaded (data/raw/)

| Folder | Source | Downloaded | Notes |
|---|---|---|---|
| `raw/ubigeo_crosswalk/ubigeo_*.csv` | Castagnetto, J. M., "ubigeo-peru-aumentado", GitHub, commit a783fa6 (24 Jan 2022), MIT license. https://github.com/jmcastagnetto/ubigeo-peru-aumentado | 2026-09-24 | RENIEC ↔ INEI ubigeo equivalence at district, province and department level (1,895 districts). Also carries capital altitude, lat/long, area, 2020 density, IDH 2019 and poverty rates. The README does not document the source of the altitude and poverty fields; treat them as a first proxy and replace with INEI originals. Missing relative to the 2025 census: 120307 Sangani, 130112 Alto Trujillo, 160405 Santa Rosa de Loreto, 180107 San Antonio (per data-inventory check, to be confirmed in code). |
| `raw/ubigeo_crosswalk/concytec_*` | CONCYTEC, "ubigeo-peru", GitHub (last updated May 2021). https://github.com/CONCYTEC/ubigeo-peru | 2026-09-24 | INEI ↔ RENIEC ↔ SUNAT equivalence, 1,876 districts. Latin-1 encoded. Second source to cross-check the Castagnetto table. |
| `raw/census2025/Indicadores_demograficos.xlsx` | INEI, Censos Nacionales 2025, tabulados. https://proyectos.inei.gob.pe/dir-segmentacion-ci/postcensal/prod/adjuntos/censos-2025/descarga_datos/tabulados/00/poblacion/Indicadores_demográficos.xlsx | 2026-09-24 | INDDEM01: population by district. INDDEM08: place of birth by department, foreign-born as a single total. |
| `raw/census2025/census2025_foreign_born_top6_by_district.csv` | INEI census 2025 results platform, public JSON API (`https://censos2025.inei.gob.pe/api/v1/resultados/etiqueta-indicadores`, indicators 301–306; `dashboard-kpis`, indicator 131). Produced by `code/00_fetch_census2025_country_of_birth.py`. | 2026-09-24 | Top six countries of birth of the foreign-born, with counts, for each of the 1,893 districts, plus the foreign-born total. Foreign-born is defined by the mother's residence at the time of birth (country of birth, not nationality). Venezuela is returned only where it ranks in the district's top six. The API is undocumented and may change. |
| `raw/sidpol/Base_datos_SIDPOL_diciembre_2025.xlsx` (and original `.zip`) | MININTER, "Base de datos del SIDPOL a diciembre del 2025" (14 Jan 2026). https://www.gob.pe/institucion/mininter/informes-publicaciones/7620286-base-de-datos-del-sidpol-a-diciembre-del-2025 | 2026-09-24 | Police crime reports (denuncias). Sheets Temp5/Temp5.2: year × month × district of occurrence (`UBIGEO_HECHO`) × crime type or modality (Estafa, Extorsión, Homicidio, Hurto, Robo, Otros), 2018–2025, with `DIST_EMERGENCIA` flag. Temp6/Temp7: detailed modality (e.g., SICARIATO, HOMICIDIO POR PAF) for 2024–2025. District coverage grows over time (about 1,426 districts with any record in 2018, about 1,700 in 2022–2024). |
| `raw/sidpol/DATASET_Denuncias_Policiales_Ene_2018_a_Julio_2026.csv` | MININTER via Plataforma Nacional de Datos Abiertos, "Denuncias Policiales". https://www.datosabiertos.gob.pe/dataset/denuncias-policiales | 2026-09-24 | District × month × 7 categories (Estafa, Extorsión, Hurto, Robo, Secuestro, Violencia contra la mujer, Otros), Jan 2018–Jul 2026. Homicide is not separated (falls under "Otros"). INEI ubigeo with the leading zero dropped. No victim or offender nationality. |
| `raw/sinadef/Diccionario_Datos_SINADEF.xlsx` | MINSA via datosabiertos.gob.pe. https://www.datosabiertos.gob.pe/sites/default/files/Diccionario_Datos_SINADEF.xlsx | 2026-09-24 | Data dictionary for SINADEF. Note the dictionary lists fewer fields than the CSV (the CSV also has `*_FALLECIMIENTO` place-of-death fields). |
| `raw/ceic_homicidios/informe-tecnico-homicidios-2022-2025.pdf` | INEI/CEIC, "Informe Técnico: Evolución de la tasa de homicidios e indicadores de seguridad ciudadana, 2022–2025" (Jan 2026). https://www.gob.pe/institucion/inei/informes-publicaciones/7648859 | 2026-09-24 | Official homicide series 2019–2025 (national and department rates), extortion complaints, ENAPRES victimization. Benchmark for SINADEF coverage. |
| `raw/inpe/informe_estadistico_setiembre_2025.pdf` | INPE, Informe Estadístico, September 2025. https://siep.inpe.gob.pe/Archivos/2025/Informes%20estadisticos/informe_estadistico_setiembre_2025.pdf | 2026-09-24 | Prison population by nationality (national) and foreign inmates by prison. 4,328 Venezuelan inmates of 103,342 (per research agent; page 20 and Anexo 16). |
| `raw/poverty_map_2018/Anexo_Estadistico.xlsx` | INEI, "Mapa de pobreza provincial y distrital 2018" (Feb 2020). https://www.gob.pe/institucion/inei/informes-publicaciones/3204872-mapa-de-pobreza-provincial-y-distrital-2018 | 2026-09-24 | District poverty estimates (2017 census + ENAHO 2017–18). Pre-treatment control. |

## Identified but not yet downloaded

- Census 2017 and 2007 REDATAM (district counts of Venezuelan-born, Q7 in 2017; residence five years earlier, Q6): https://censos2017.inei.gob.pe/redatam/ and https://censos.inei.gob.pe/Censos2007/redatam/. Online queries; needs manual export.
- INEI Directorio Nacional de Centros Poblados 2017 (altitude and population of 94,922 populated centres), 4 PDF volumes: https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1541/index.htm. Needed for population-weighted altitude; look for a GIS/tabular version first.
- INEI IDE district boundaries 2023 (GPKG): https://ide.inei.gob.pe/
- GHSL population raster and Copernicus GLO-30 DEM (population-weighted altitude). Avoid WorldPop for this purpose: its model uses elevation as a covariate.
- MTC road network (distance from CEBAF Tumbes): https://geoportal.mtc.gob.pe/
- Migraciones reports on Venezuelan migration (province stocks; Lima districts): https://www.gob.pe/institucion/migraciones/colecciones/1503-migracion-venezolana-en-el-peru
- RENAMU 2024 (serenazgo, municipal security): https://www.datosabiertos.gob.pe/dataset/registro-nacional-de-municipalidades-renamu-2024-instituto-nacional-de-estad%C3%ADstica-e-0
