*=====================================================================
* 32_assemble_panel.do - district x year panel for event studies (spec 3)
*
* Inputs: $der/sinadef/sinadef_district_year.dta (2017-2025)
*         $der/sidpol/sidpol_district_year.dta   (2018-2025)
*         $der/census/census2025_district.dta, $der/instruments/instruments.dta
*         $der/controls/pre2017_crime_2016.dta   (2016 police reports)
* Output: $der/analysis/panel_dy.dta (1,893 districts x 2016-2025)
*
* 2016 rows carry only the 2016 police-report counts (pre16_*); SINADEF
* starts in 2017 and SIDPOL in 2018. Rates per 100,000 use the 2025 census
* population as a fixed denominator. break2025 flags the SIDPOL extraction
* change (OBNASEC-INDAGA 2026, p. 67).
*=====================================================================
if "$root" == "" exit 198

use "$der/geo/geo_harmonized.dta", clear
keep ubigeo
expand 10
bysort ubigeo: generate int year = 2015 + _n
isid ubigeo year

merge 1:1 ubigeo year using "$der/sinadef/sinadef_district_year.dta", keep(master match)
assert _merge == 3 if inrange(year, 2017, 2025)
generate byte in_sinadef = _merge == 3
drop _merge
merge 1:1 ubigeo year using "$der/sidpol/sidpol_district_year.dta", keep(master match)
assert _merge == 3 if inrange(year, 2018, 2025)
generate byte in_sidpol = _merge == 3
drop _merge

merge m:1 ubigeo using "$der/controls/pre2017_crime_2016.dta", keep(master match) nogenerate
foreach v in hom sicariato extorsion robo hurto {
    generate police16_`v' = pre16_`v' if year == 2016
}
drop pre16_*

merge m:1 ubigeo using "$der/census/census2025_district.dta", ///
    keepusing(pop25 vshare25 dept_id prov_id lima_callao tumbes) keep(master match)
check_merge, using(0)
drop _merge
merge m:1 ubigeo using "$der/instruments/instruments.dta", ///
    keepusing(z2_ltt z3_alt ltt_lima ldens15 lat lon pop_ghsl15 geo_missing) keep(master match)
check_merge, using(0)
drop _merge

foreach v of varlist hom hom_fire hom_m1539 suicide traffic nonviol sid_* police16_* {
    generate r_`v' = 1e5 * `v' / pop25
}
encode dept_id, generate(dept_n)
encode prov_id, generate(prov_n)
egen long did = group(ubigeo)
xtset did year
isid ubigeo year
assert _N == 1893 * 10
compress
save "$der/analysis/panel_dy.dta", replace
display as text "32_assemble_panel: " _N " district-years (2016-2025)"
