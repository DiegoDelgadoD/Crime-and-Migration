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
- Raw data files are read-only. Clean them in `code/` and write derived files to a separate folder.
- **Git policy (decided 2026-09-29):** the GitHub repo is public. Data files are committed except those over 50 MB, which are listed in `.gitignore` (currently only the SINADEF CSV) and must be re-downloaded from the URLs in `data/SOURCES.md`. The `.claude/` folder is committed, except `.claude/memory/` and `.claude/settings.local.json`.

## Current Status

Literature and data scoping in progress. No analysis code yet; the analysis language (Stata, R or Python) is not yet chosen.
