*=====================================================================
* 31_assemble_longdiff.do - district long-difference sample (spec 1)
*
* Inputs: $der/census/census2025_district.dta
*         $der/census/census2017_district.dta (13_census_redatam.do; optional)
*         $der/sinadef/sinadef_district_year.dta
*         $der/sidpol/sidpol_district_year.dta
*         $der/controls/poverty2018.dta, $der/controls/pre2017_crime_2016.dta
*         $der/instruments/instruments.dta
* Output: $der/analysis/ld_district.dta
*
* dV = Venezuela-born share 2025 minus 2017, in percentage points. Until
* the 2017 REDATAM export exists, dV = the 2025 share (dv_provisional = 1);
* the 2017 stock (47,481; INEI 2018, p. 7) is 5% of the 2025 stock.
* Outcome changes are post-period minus pre-period rates per 100,000,
* both on the 2025 census population, so they measure the change in counts
* scaled by a fixed denominator:
*   SINADEF: 2023-2025 average minus 2017-2018 average
*   SIDPOL : 2023-2024 average minus 2018 (2025 excluded: extraction
*            change, OBNASEC-INDAGA 2026, p. 67)
* Weights: GHSL 2015 population (pre-period).
*=====================================================================
if "$root" == "" exit 198

use ubigeo pop25 ven25 ven25_lb ven25_ub ven_censored vshare25 fbshare25 ///
    hid dept_id prov_id lima_callao tumbes using "$der/census/census2025_district.dta", clear

capture confirm file "$der/census/census2017_district.dta"
if !_rc {
    merge 1:1 ubigeo using "$der/census/census2017_district.dta", keepusing(vshare17) ///
        keep(master match) nogenerate
    generate dv = 100 * (vshare25 - vshare17)
    generate byte dv_provisional = 0
}
else {
    generate dv = 100 * vshare25
    generate byte dv_provisional = 1
}
label variable dv "Change in Venezuela-born share, pp (2017-2025)"

*---- SINADEF changes ------------------------------------------------
preserve
use "$der/sinadef/sinadef_district_year.dta", clear
generate byte pre  = inrange(year, 2017, 2018)
generate byte post = inrange(year, 2023, 2025)
local ys hom hom_fire hom_m1539 suicide traffic nonviol
foreach y of local ys {
    bysort ubigeo: egen `y'_pre  = total(`y' * pre / 2)
    bysort ubigeo: egen `y'_post = total(`y' * post / 3)
}
bysort ubigeo: keep if _n == 1
keep ubigeo *_pre *_post
tempfile sin
save `sin'
restore
merge 1:1 ubigeo using `sin'
check_merge, master(0) using(0)
drop _merge

*---- SIDPOL changes -------------------------------------------------
preserve
use "$der/sidpol/sidpol_district_year.dta", clear
generate byte pre  = year == 2018
generate byte post = inrange(year, 2023, 2024)
local ps sid_extorsion sid_robo sid_hurto sid_estafa sid_homicidio
foreach y of local ps {
    bysort ubigeo: egen `y'_pre  = total(`y' * pre)
    bysort ubigeo: egen `y'_post = total(`y' * post / 2)
}
bysort ubigeo: egen sid_reported_pre = max(reported * pre)
bysort ubigeo: keep if _n == 1
keep ubigeo *_pre *_post
tempfile sid
save `sid'
restore
merge 1:1 ubigeo using `sid'
check_merge, master(0) using(0)
drop _merge

*---- Rates and changes --------------------------------------------
foreach y in hom hom_fire hom_m1539 suicide traffic nonviol sid_extorsion sid_robo ///
    sid_hurto sid_estafa sid_homicidio {
    generate r_`y'_pre  = 1e5 * `y'_pre  / pop25
    generate r_`y'_post = 1e5 * `y'_post / pop25
    generate d_`y' = r_`y'_post - r_`y'_pre
}

*---- Controls and instruments --------------------------------------
merge 1:1 ubigeo using "$der/controls/poverty2018.dta", keepusing(pov18) keep(master match) nogenerate
capture confirm file "$der/controls/pre2017_crime_2016.dta"
if !_rc {
    merge 1:1 ubigeo using "$der/controls/pre2017_crime_2016.dta", keep(master match) nogenerate
}
merge 1:1 ubigeo using "$der/instruments/instruments.dta"
check_merge, master(0) using(0)
drop _merge

generate w = pop_ghsl15
label variable w "Weight: GHSL 2015 population"
isid ubigeo
assert _N == 1893
compress
save "$der/analysis/ld_district.dta", replace
quietly count if !missing(dv, z2_ltt, z3_alt, w)
display as text "31_assemble_longdiff: 1,893 districts; " r(N) " with dV, Z2, Z3 and weights"
