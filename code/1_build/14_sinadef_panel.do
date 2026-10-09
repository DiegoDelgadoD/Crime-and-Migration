*=====================================================================
* 14_sinadef_panel.do - SINADEF deaths to district-year and month panels
*
* Input : data/SINADEF_DATOS_ABIERTOS.csv (647 MB, MINSA open data)
*         $der/geo/crosswalk_reniec_inei.dta, $der/geo/geo_harmonized.dta
* Output: $der/sinadef/sinadef_district_year.dta   (residence, 2017-2025)
*         $der/sinadef/sinadef_district_month.dta  (residence)
*         $der/sinadef/sinadef_pod_district_year.dta (place of death)
*         $der/sinadef/sinadef_match_report.dta
*
* The CSV is read in chunks (varnames(nonames), columns v1-v36) and each
* chunk is collapsed to counts before appending, so no record-level
* file is saved. Column positions follow the CSV header:
*   v2-v4 place of death (names only), v7 SEXO, v8 TIEMPO_EDAD, v9 EDAD,
*   v13 COD_UBIGEO_DOMICILIO (92-33-DD-PP-dd-000), v14 PAIS_DOMICILIO,
*   v15-v17 residence names, v19 ANIO, v20 MES, v23 MUERTE_VIOLENTA,
*   v25 v27 v29 v31 v33 v35 DEBIDO_CAUSA_A-F (free text).
* Firearm homicides are classified from the free text because ICD-10
* codes are missing for 79% of homicides (analysis plan, missing data).
*=====================================================================
if "$root" == "" exit 198

local csv   "$data/SINADEF_DATOS_ABIERTOS.csv"
local chunk 300000
local start 2
local k 0
local fire "PROYECTIL|ARMA DE FUEGO|\bPAF\b|\bBALA|DISPARO"

while 1 {
    local end = `start' + `chunk' - 1
    capture import delimited using "`csv'", clear varnames(nonames) ///
        stringcols(_all) encoding("utf-8") rowrange(`start':`end')
    if _rc | _N == 0 continue, break
    local ++k
    display as text "chunk `k': rows `start'-`end', N = " _N
    assert c(k) == 36

    generate int  year   = real(v19)
    generate byte month  = real(v20)
    generate byte death  = 1
    generate byte hom     = v23 == "HOMICIDIO"
    generate byte suicide = v23 == "SUICIDIO"
    generate byte traffic = v23 == "ACCIDENTE DE TRANSITO"
    generate byte nonviol = v23 == "SIN REGISTRO"
    generate byte m1539   = v7 == "MASCULINO" & v8 == "AÑOS" & inrange(real(v9), 15, 39)
    generate byte hom_m1539 = hom & m1539
    generate strL causes = ustrupper(v25 + " " + v27 + " " + v29 + " " + v31 + " " + v33 + " " + v35)
    generate byte hom_fire  = hom & ustrregexm(causes, "`fire'")
    generate byte abroad    = v14 != "PERU"

    * RENIEC residence code: digits DD PP dd of 92-33-DD-PP-dd-000
    generate str6 reniec = substr(v13, 7, 2) + substr(v13, 10, 2) + substr(v13, 13, 2) ///
        if strlen(v13) == 18
    rename (v2 v3 v4 v15 v16 v17) (dep_f prov_f dist_f dep_d prov_d dist_d)

    local ys "death hom suicide traffic nonviol hom_m1539 hom_fire"
    preserve
    collapse (sum) `ys', by(reniec dep_d prov_d dist_d abroad year month)
    save "$tmp/sinadef_res_`k'.dta", replace
    restore
    collapse (sum) `ys', by(dep_f prov_f dist_f year)
    save "$tmp/sinadef_pod_`k'.dta", replace

    local start = `end' + 1
}
assert `k' >= 5

*---- Residence panel --------------------------------------------------
clear
forvalues j = 1/`k' {
    append using "$tmp/sinadef_res_`j'.dta"
}
collapse (sum) death hom suicide traffic nonviol hom_m1539 hom_fire, ///
    by(reniec dep_d prov_d dist_d abroad year month)

* Raw totals before any drop (CLAUDE.md: 677 in 2017, 2,253 in 2025)
quietly summarize hom if year == 2017
assert r(sum) == 677
quietly summarize hom if year == 2025
assert r(sum) == 2253
preserve
collapse (sum) death hom hom_fire, by(year)
generate fire_share = hom_fire / hom
list, noobs
restore

drop if abroad
drop abroad

* Match RENIEC codes to INEI
merge m:1 reniec using "$der/geo/crosswalk_reniec_inei.dta", keepusing(inei) ///
    keep(master match)
generate byte matched_code = _merge == 3
drop _merge

* Name-based fallback for codes absent from the crosswalk
normname dep_d,  generate(k_dep)
normname prov_d, generate(k_prov)
normname dist_d, generate(k_dist)
* Name keys: crosswalk names, plus 2025 census names for districts that
* the crosswalk lacks (e.g., 130112 Alto Trujillo)
preserve
use "$der/geo/crosswalk_reniec_inei.dta", clear
keep inei departamento provincia distrito
rename (inei departamento provincia distrito) (inei_name nd np nt)
tempfile cwnames
save `cwnames'
use "$der/geo/geo_harmonized.dta", clear
keep ubigeo dep_name prov_name dist_name
rename (ubigeo dep_name prov_name dist_name) (inei_name nd np nt)
merge 1:1 inei_name using `cwnames', keep(master) nogenerate
display as text "Census-only districts added to the name keys: " _N
append using `cwnames'
normname nd, generate(k_dep)
normname np, generate(k_prov)
normname nt, generate(k_dist)
keep inei_name k_dep k_prov k_dist
duplicates tag k_dep k_prov k_dist, generate(dup)
drop if dup
drop dup
tempfile names
save `names'
restore
merge m:1 k_dep k_prov k_dist using `names', keep(master match) keepusing(inei_name)
replace inei = inei_name if missing(inei) & _merge == 3
generate byte matched_name = missing(inei_name) == 0 & matched_code == 0 & _merge == 3
drop _merge inei_name

preserve
generate byte unmatched = missing(inei)
collapse (sum) hom death, by(unmatched)
list, noobs
save "$der/sinadef/sinadef_match_report.dta", replace
restore
quietly summarize hom
local tot = r(sum)
quietly summarize hom if !missing(inei)
display as text "Residence match rate (homicides): " %6.4f r(sum)/`tot'
assert r(sum) / `tot' >= 0.995
display as text "Unmatched residence records (by code, all deaths):"
quietly count if missing(inei) & !missing(reniec)
if r(N) tab reniec if missing(inei) & !missing(reniec), sort
drop if missing(inei)

rename inei ubigeo
collapse (sum) death hom suicide traffic nonviol hom_m1539 hom_fire, by(ubigeo year month)
keep if inrange(year, 2017, 2025)
merge m:1 ubigeo using "$der/geo/geo_harmonized.dta", keepusing(ubigeo) keep(master match using)
quietly count if _merge == 1
display as text "Residence cells with an ubigeo outside the 2025 list: " r(N)
drop if _merge == 1
drop _merge
replace year = 2017 if missing(year)
replace month = 1 if missing(month)
fillin ubigeo year month
foreach v in death hom suicide traffic nonviol hom_m1539 hom_fire {
    replace `v' = 0 if missing(`v')
}
drop _fillin
isid ubigeo year month
assert _N == 1893 * 9 * 12
compress
save "$der/sinadef/sinadef_district_month.dta", replace

collapse (sum) death hom suicide traffic nonviol hom_m1539 hom_fire, by(ubigeo year)
isid ubigeo year
assert _N == 1893 * 9
label variable hom       "Homicides, SINADEF, by residence"
label variable hom_fire  "Firearm homicides (cause text classifier)"
label variable hom_m1539 "Homicides of men aged 15-39"
compress
save "$der/sinadef/sinadef_district_year.dta", replace

*---- Place-of-death panel ----------------------------------------------
clear
forvalues j = 1/`k' {
    append using "$tmp/sinadef_pod_`j'.dta"
}
collapse (sum) death hom suicide traffic nonviol hom_m1539 hom_fire, by(dep_f prov_f dist_f year)
keep if inrange(year, 2017, 2025)
normname dep_f,  generate(k_dep)
normname prov_f, generate(k_prov)
normname dist_f, generate(k_dist)
merge m:1 k_dep k_prov k_dist using `names', keep(master match) keepusing(inei_name)
generate byte pod_recorded = !inlist("SIN REGISTRO", k_dep, k_prov, k_dist)
quietly summarize hom
local tot = r(sum)
quietly summarize hom if !pod_recorded
display as text "Homicides with no place of death recorded: " r(sum) " of " `tot'
quietly summarize hom if pod_recorded
local rec = r(sum)
quietly summarize hom if _merge == 3
local mat = r(sum)
display as text "Place-of-death match rate among recorded (homicides): " %6.4f `mat'/`rec'
display as text "Unmatched recorded place names (homicides > 0):"
list k_dep k_prov k_dist hom if _merge == 1 & pod_recorded & hom > 0, noobs
assert `mat' / `rec' >= 0.995
keep if _merge == 3
rename inei_name ubigeo
collapse (sum) death hom suicide traffic nonviol hom_m1539 hom_fire, by(ubigeo year)
fillin ubigeo year
foreach v in death hom suicide traffic nonviol hom_m1539 hom_fire {
    replace `v' = 0 if missing(`v')
}
drop _fillin
isid ubigeo year
rename (death hom suicide traffic nonviol hom_m1539 hom_fire) =_pod
compress
save "$der/sinadef/sinadef_pod_district_year.dta", replace

forvalues j = 1/`k' {
    erase "$tmp/sinadef_res_`j'.dta"
    erase "$tmp/sinadef_pod_`j'.dta"
}
display as text "14_sinadef_panel: done (`k' chunks)"
