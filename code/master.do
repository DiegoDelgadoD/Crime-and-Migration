*=====================================================================
* master.do - Venezuelan immigration and crime in Peru (PI: D. Delgado)
*
* Run from the repository root, in batch mode:
*   cd "C:/Users/DDelgado/Documents/GitHub/Crime-and-Migration"
*   MSYS_NO_PATHCONV=1 "C:/Program Files/Stata18/StataSE-64.exe" /e do code/master.do  (Git Bash)
* Then check the logs:
*   grep for error lines (pattern in code/utils/check_logs.do) in
*   master.log and in every file in the output/logs folder
*
* Design: .claude/2026-09-29_analysis_plan.md
*=====================================================================
version 18
clear all
set more off
set varabbrev off
set type double
set linesize 120
set maxvar 10000
set seed 20260929
set sortseed 20260929

*---------------- Paths (relative to the repository root) ------------
global root "`c(pwd)'"
capture confirm file "$root/code/master.do"
if _rc {
    display as error "Run master.do from the repository root (see header)."
    exit 601
}
global code "$root/code"
global data "$root/data"          // READ-ONLY
global raw  "$root/data/raw"      // READ-ONLY
global der  "$root/data/derived"
global tmp  "$der/tmp"            // git-ignored
global gis  "$der/gis"            // Python GIS outputs (CSV)
global look "$code/lookups"
global out  "$root/output"
global tab  "$out/tables"
global fig  "$out/figures"
global est  "$out/estimates"
global logs "$out/logs"
global PYTHON "python"

foreach d in der tmp gis out tab fig est logs {
    capture mkdir "${`d'}"
}
foreach s in geo census sinadef sidpol controls instruments analysis {
    capture mkdir "$der/`s'"
}

*---------------- Pinned packages ------------------------------------
* User-written packages live in code/ado/plus (git-ignored); versions are
* recorded in output/logs/package_versions.log by 00_install.do.
capture mkdir "$code/ado"
capture mkdir "$code/ado/plus"
sysdir set PLUS "$code/ado/plus"

*---------------- Stage toggles (1 = run) ----------------------------
* Packages install when missing, or when run as: do code/master.do install
args mode
capture confirm file "$code/ado/plus/i/ivreghdfe.ado"
global RUN_S0 = (_rc != 0) | ("`mode'" == "install")
* "fast" skips the 7-minute SINADEF rebuild when its outputs exist
global FAST = ("`mode'" == "fast")
global RUN_S1 1      // build
global RUN_S2 1      // instruments (Z1 waits for REDATAM 2007)
global RUN_S3 1      // sample assembly (dV provisional until REDATAM 2017)
global RUN_S4 1      // descriptives
global RUN_S5 1      // first stage (no outcomes); 2SLS scripts not yet written
global RUN_S6 0      // event studies, PPML, count IV
global RUN_S7 0      // robustness
global RUN_S8 0      // heterogeneity, imported methods
global RUN_S9 0      // tables and figures
global RUN_PY 0      // 1 = shell out to the Python scripts in code/gis

*---------------- Analysis options -----------------------------------
global YEARS_SIN "2017/2025"      // SINADEF years kept (2026 is partial)
global YEARS_SID "2018/2025"      // SIDPOL years

*---------------- Helpers --------------------------------------------
do "$code/utils/programs.do"

capture program drop have
program define have
    args gname path
    capture confirm file "`path'"
    global `gname' = (_rc == 0)
    display as text "`gname' = ${`gname'}  (`path')"
end
have HAVE_R2017   "$raw/redatam/census2017_district.xlsx"
have HAVE_R2007   "$raw/redatam/census2007_district.xlsx"
have HAVE_PRE2017 "$raw/pre2017_crime/cap200_denuncias_2016.sav"
have HAVE_BOUND   "$raw/inei_boundaries/DISTRITO.gpkg"
have HAVE_PUCP    "$raw/pucp_emergencias/emergencias.xlsx"
have HAVE_RENAMU  "$raw/renamu/renamu_2017_2024.dta"
have HAVE_MIGR    "$raw/migraciones/stocks_district.xlsx"

capture program drop runscript
program define runscript
    args folder file
    local name = subinstr("`file'", ".do", "", .)
    display as text _n "{hline 70}" _n "RUN `folder'/`file'  `c(current_date)' `c(current_time)'"
    log using "$logs/`name'.log", replace text name(L`name')
    capture noisily do "$code/`folder'/`file'"
    local rc = _rc
    capture log close L`name'
    if `rc' {
        display as error "STOP: `folder'/`file' failed with return code `rc'"
        exit `rc'
    }
end

capture program drop pyrun
program define pyrun
    args script outcsv
    if $RUN_PY {
        shell "$PYTHON" "$code/gis/`script'"
    }
    capture confirm file "`outcsv'"
    if _rc {
        display as error "STOP: `outcsv' missing; run code/gis/`script' (or set RUN_PY 1)"
        exit 601
    }
end

*---------------- Stages ---------------------------------------------
if $RUN_S0 runscript 0_setup 00_install.do

if $RUN_S1 {
    runscript 1_build 10_crosswalk.do
    runscript 1_build 11_geo_harmonize.do
    runscript 1_build 12_census2025.do
    if $HAVE_R2017 | $HAVE_R2007 runscript 1_build 13_census_redatam.do
    capture confirm file "$der/sinadef/sinadef_district_year.dta"
    if !($FAST & _rc == 0) runscript 1_build 14_sinadef_panel.do
    runscript 1_build 15_sidpol_panels.do
    runscript 1_build 16_poverty2018.do
    if $HAVE_PRE2017 runscript 1_build 19d_pre2017_crime.do
}

if $RUN_S2 {
    * GIS inputs: code/gis/16_download_gis.py (run once by hand)
    pyrun 17_district_geometry.py "$gis/district_geometry.csv"
    pyrun 22_altitude_popw.py     "$gis/altitude.csv"
    pyrun 21_travel_time_cebaf.py "$gis/travel_time_cebaf.csv"
    runscript 2_instruments 23_import_instruments.do
}

if $RUN_S3 {
    runscript 3_sample 31_assemble_longdiff.do
    runscript 3_sample 32_assemble_panel.do
}

if $RUN_S4 runscript 4_descriptives 41_benchmarks.do

if $RUN_S5 runscript 5_iv 50_first_stage.do

* Stages 6-9 are added as their inputs arrive (see the analysis plan).

do "$code/utils/check_logs.do"
display as text "master.do finished `c(current_date)' `c(current_time)'"
