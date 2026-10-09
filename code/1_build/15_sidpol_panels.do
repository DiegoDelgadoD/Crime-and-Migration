*=====================================================================
* 15_sidpol_panels.do - SIDPOL police reports to district panels
*
* Input : $raw/sidpol/Base_datos_SIDPOL_diciembre_2025.xlsx
*           Temp5.2: year x month x district x modality (Estafa, Extorsión,
*                    Homicidio, Hurto, Robo, Otros), with DIST_EMERGENCIA
*           Temp6/Temp7: detailed modality, 2024 and 2025
*         $raw/sidpol/DATASET_Denuncias_Policiales_Ene_2018_a_Julio_2026.csv
*           (open-data series; used only for the comparison below)
* Output: $der/sidpol/sidpol_district_month.dta
*         $der/sidpol/sidpol_district_year.dta
*         $der/sidpol/sidpol_emergency_dm.dta
*         $der/sidpol/sidpol_modalities_2024_2025.dta
*         $der/sidpol/sidpol_xlsx_vs_csv.dta
*
* The xlsx is the analysis series. The CSV is a different extraction
* (analysis plan, missing data), so the comparison is reported, not
* asserted. 2025 counts use a new extraction with duplicate filtering
* (OBNASEC-INDAGA 2026, p. 67); break2025 flags those years.
*=====================================================================
if "$root" == "" exit 198

local xlsx "$raw/sidpol/Base_datos_SIDPOL_diciembre_2025.xlsx"

*---- Temp5.2: modalities by district-month ----------------------------
import excel using "`xlsx'", sheet("Temp5.2") firstrow clear allstring
rename (ANIO MES UBIGEO_HECHO P_MODALIDADES n_dist_ID_DGC DIST_EMERGENCIA) ///
    (year month ubigeo_raw modality n emerg)
destring year month n emerg, replace
fix_ubigeo ubigeo_raw, generate(ubigeo)
drop ubigeo_raw
normname modality, generate(mod)
tab mod
generate str10 y = ""
replace y = "estafa"    if mod == "ESTAFA"
replace y = "extorsion" if mod == "EXTORSION"
replace y = "homicidio" if mod == "HOMICIDIO"
replace y = "hurto"     if mod == "HURTO"
replace y = "robo"      if mod == "ROBO"
replace y = "otros"     if mod == "OTROS"
assert y != ""

preserve
collapse (max) emerg, by(ubigeo year month)
isid ubigeo year month
save "$der/sidpol/sidpol_emergency_dm.dta", replace
restore

collapse (sum) n, by(ubigeo year month y)
reshape wide n, i(ubigeo year month) j(y) string
rename n* sid_*
foreach v of varlist sid_* {
    replace `v' = 0 if missing(`v')
}
generate byte reported = 1
merge m:1 ubigeo using "$der/geo/geo_harmonized.dta", keepusing(ubigeo)
quietly count if _merge == 1
display as text "SIDPOL district codes outside the 2025 list: " r(N)
if r(N) tab ubigeo if _merge == 1
drop if _merge == 1
replace year = 2018 if _merge == 2
replace month = 1 if _merge == 2
drop _merge
fillin ubigeo year month
foreach v of varlist sid_* reported {
    replace `v' = 0 if missing(`v')
}
drop _fillin
isid ubigeo year month
generate byte break2025 = year >= 2025
compress
save "$der/sidpol/sidpol_district_month.dta", replace

collapse (sum) sid_* (max) reported break2025, by(ubigeo year)
label variable reported "District has any SIDPOL report that year (0 = none, not a true zero)"
isid ubigeo year
compress
save "$der/sidpol/sidpol_district_year.dta", replace
tabstat sid_extorsion sid_robo sid_hurto sid_homicidio reported, by(year) stat(sum) format(%12.0fc)

*---- Temp6/Temp7: detailed modalities, 2024-2025 ----------------------
tempfile t6
import excel using "`xlsx'", sheet("Temp6") firstrow clear allstring
save `t6'
import excel using "`xlsx'", sheet("Temp7") firstrow clear allstring
append using `t6'
rename (ANIO UBIGEO_HECHO MODALIDAD SUB_TIPO n_dist_ID_DGC) (year ubigeo_raw modalidad subtipo n)
destring year n, replace
fix_ubigeo ubigeo_raw, generate(ubigeo)
normname modalidad, generate(m)
normname subtipo,   generate(s)
generate byte sicariato  = ustrregexm(m, "SICARIATO")
generate byte hom_paf    = ustrregexm(m, "HOMICIDIO POR PAF")
generate byte extorsion  = ustrregexm(m, "EXTORSION") | ustrregexm(s, "EXTORSION")
generate byte marcaje    = ustrregexm(m, "MARCAJE|REGLAJE")
foreach v in sicariato hom_paf extorsion marcaje {
    generate mod_`v' = n * `v'
}
preserve
collapse (sum) mod_*, by(year)
list, noobs
restore
collapse (sum) mod_*, by(ubigeo year)
isid ubigeo year
compress
save "$der/sidpol/sidpol_modalities_2024_2025.dta", replace

*---- Comparison with the open-data CSV --------------------------------
import delimited "$raw/sidpol/DATASET_Denuncias_Policiales_Ene_2018_a_Julio_2026.csv", ///
    clear varnames(1) stringcols(_all) encoding("utf-8")
destring anio cantidad, replace
normname p_modalidades, generate(mod)
keep if inlist(mod, "ESTAFA", "EXTORSION", "HURTO", "ROBO")
collapse (sum) csv = cantidad, by(anio mod)
rename anio year
tempfile csv
save `csv'
use "$der/sidpol/sidpol_district_year.dta", clear
collapse (sum) sid_estafa sid_extorsion sid_hurto sid_robo, by(year)
reshape long sid_, i(year) j(y) string
generate mod = upper(y)
rename sid_ xlsx
merge 1:1 year mod using `csv', keep(master match) nogenerate
generate gap_pct = 100 * (csv - xlsx) / xlsx
list year mod xlsx csv gap_pct, noobs sepby(year)
save "$der/sidpol/sidpol_xlsx_vs_csv.dta", replace
display as text "15_sidpol_panels: done"
