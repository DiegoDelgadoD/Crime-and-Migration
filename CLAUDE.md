# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Crime-and-Migration asks whether Venezuelan immigration caused the rise in crime in Peru, as public narratives claim (including the claim that migrants "imported" new criminal methods such as extortion and sicariato). PI: Diego Delgado (IPA), development economist. Licensed under MIT (2026, Diego Delgado).

Kick-off: 2026-09-24, after the release of the 2025 census district tables.

## Proposed design (under discussion, not settled)

- **Unit:** district (1,893 districts in the 2025 census).
- **Outcomes:** homicide and violent-death rates from SINADEF; police crime reports (denuncias) by type of crime.
- **Endogenous regressor:** Venezuelan migrant share of district population, and levels.
- **Instrument proposed by Diego:** district altitude, on the argument that Venezuelans come from low-altitude places and settle in similar ones. Alternatives under evaluation: 2007-census Venezuelan settlement × time (shift-share with a single origin), and distance or travel time from the Tumbes border crossing (CEBAF).
- SINADEF covers 2017–2026, so a district panel is possible, not only a 2025 cross-section.
- **Proposed plan (2026-09-29, pending Diego's confirmation):** see `.claude/2026-09-29_analysis_plan.md`.
  - The census measures the Venezuelan share only in 2017 and 2025, so the core IV is a 2017→2025 long difference, with annual event-study reduced forms.
  - Altitude enters only as an over-identifying instrument, with fixed effects.
  - The headline inference is the Anderson–Rubin confidence set.

Do not treat any of these choices as final until Diego confirms them.

## Repository Structure

- **code/** - Analysis scripts and source code
- **data/** - Input datasets. Every file is logged in `data/SOURCES.md` with source, download date and caveats.
  - **data/raw/** - Downloaded datasets, one subfolder per source.
- **output/** - Generated results, figures, and reports
- **.claude/** - Claude reports (audits, checks, research notes) and project memory (`.claude/memory/`, git-ignored)

## Data notes

- **SINADEF** (`data/SINADEF_DATOS_ABIERTOS.csv`, 647 MB, MINSA open data): one row per death. `MUERTE_VIOLENTA == "HOMICIDIO"` gives 677 deaths in 2017 and 2,253 in 2025. `COD_UBIGEO_DOMICILIO` is RENIEC-coded in the format `92-33-DD-PP-dd-000` (Lima = 14, Callao = 24), not INEI-coded. Merge to census data through `data/raw/ubigeo_crosswalk/ubigeo_distrito.csv` (`reniec` → `inei`). Records with residence abroad appear as `EXTRANJERO`. `PAIS_DOMICILIO` is country of residence, not nationality.
- **Census 2025 tables** (INEI "Consulta de población", Excel): header rows 1–6 and footnotes at the bottom must be skipped. Ubigeo is INEI-coded. The immigrant table counts all foreign-born, not Venezuelans specifically. Department labels split Lima into "Lima Metropolitana" and "Región Lima", and Callao appears as "Prov. Const. del Callao".
- **SINADEF, further limits:**
  - There is no nationality or country-of-birth field.
  - Place of death (`*_FALLECIMIENTO`) is stored as names only, with no ubigeo.
  - ICD-10 `CAUSA_A_CIEX` is missing for 79% of homicides. Classify firearm homicides from the free-text `DEBIDO_CAUSA_*` fields instead.
  - Criminologists consider SINADEF fit for trends, not levels (Mujica & Campos-Vásquez 2026, p. 12).
- **SIDPOL:**
  - 2025 counts use a new extraction with duplicate filtering, so they are not comparable with 2018–2024 (OBNASEC-INDAGA 2026, p. 67).
  - The xlsx and the open-data CSV are different series. Use the xlsx.
  - Sicariato appears only in the 2024–2025 modality sheets (35 and 33 cases), too few for a district outcome.
- Raw data files are read-only. Clean them in `code/` and write derived files to a separate folder.
- **Git policy (decided 2026-09-29):** the GitHub repo is public. Data files are committed except those over 50 MB, which are listed in `.gitignore` (currently only the SINADEF CSV) and must be re-downloaded from the URLs in `data/SOURCES.md`. The `.claude/` folder is committed, except `.claude/memory/` and `.claude/settings.local.json`.

## Current Status

- **Analysis language (decided 2026-09-29):** Stata 18 SE, run in batch through `code/master.do` (`stata -b do code/master.do`). Python is used only for API fetches and GIS, in `code/gis/`.
- **Documents:**
  - Literature review, citing only papers read in full text: `.claude/2026-09-29_literature_review.md`.
  - Analysis plan, with the pipeline and missing data: `.claude/2026-09-29_analysis_plan.md`.
- **Code (2026-09-30):** these stages run clean:
  - Stage 1 build: crosswalk, census 2025, SINADEF, SIDPOL, poverty 2018, and 2016 police reports.
  - Stage 2 GIS instruments (Python in `code/gis/`): Z2 travel time on OSM 2017, Z3 GHSL-weighted altitude.
  - Stage 3 samples, stage 4 benchmarks, and stage 5 first stage.
  - Run with `MSYS_NO_PATHCONV=1 "C:/Program Files/Stata18/StataSE-64.exe" /e do code/master.do` from Git Bash. Add the `fast` argument to skip the 7-minute SINADEF rebuild.
- **Blocking inputs:**
  - REDATAM 2007 and 2017 district exports, for Z1 and ΔV (Diego's task).
  - The five information requests in `.claude/2026-09-30_solicitudes_informacion.md`.
- **2016 police reports** (`data/raw/pre2017_crime/`): the file holds address-like fields and a person ID. Load only district, year and crime-type variables, as `19d_pre2017_crime.do` does.
