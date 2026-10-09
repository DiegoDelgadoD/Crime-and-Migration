*=====================================================================
* 41_benchmarks.do - SINADEF and SIDPOL homicides against the official
*                    CEIC series
*
* Inputs: $der/sinadef/sinadef_district_year.dta
*         $der/sidpol/sidpol_district_year.dta
*         $der/census/census2025_district.dta
*         $look/ceic_homicides_national.csv   (INEI 2026, p. 7 table)
*         $look/ceic_homicide_rates_2025.csv  (INEI 2026, p. 8 chart)
* Output: $est/bench_national.dta, $est/bench_region2025.dta
*
* CEIC counts deaths from intentional crimes, built mainly from police
* records and cross-checked against SINADEF (INEI 2026, pp. 5-6), so the
* ratio SINADEF / CEIC is a coverage proxy, not an exact completeness rate.
* Regional rates use CEIC's own 2025 rates and census 2025 population for
* SINADEF; the population bases differ (projected vs counted).
*=====================================================================
if "$root" == "" exit 198

*---- National series ------------------------------------------------
use "$der/sinadef/sinadef_district_year.dta", clear
collapse (sum) sinadef_hom = hom, by(year)
tempfile s
save `s'
use "$der/sidpol/sidpol_district_year.dta", clear
collapse (sum) sidpol_hom = sid_homicidio, by(year)
merge 1:1 year using `s', nogenerate
tempfile ss
save `ss'
import delimited "$look/ceic_homicides_national.csv", clear varnames(1)
keep year ceic_homicides ceic_rate
merge 1:1 year using `ss', keep(match) nogenerate
generate ratio_sinadef_ceic = sinadef_hom / ceic_homicides
generate ratio_sidpol_ceic  = sidpol_hom / ceic_homicides
format ratio_* %5.3f
list year ceic_homicides sinadef_hom ratio_sinadef_ceic sidpol_hom ratio_sidpol_ceic, noobs
assert _N == 7
save "$est/bench_national.dta", replace

*---- Regions, 2025 ------------------------------------------------------
use "$der/sinadef/sinadef_district_year.dta", clear
keep if year == 2025
merge 1:1 ubigeo using "$der/census/census2025_district.dta", keepusing(pop25 dept_id prov_id)
check_merge, master(0) using(0)
drop _merge
generate str4 region_code = dept_id
replace region_code = "1501" if prov_id == "1501"
replace region_code = "15xx" if dept_id == "15" & prov_id != "1501"
collapse (sum) hom pop25, by(region_code)
generate sinadef_rate = hom / pop25 * 1e5
tempfile r
save `r'
import delimited "$look/ceic_homicide_rates_2025.csv", clear varnames(1) stringcols(2)
replace region_code = "0" + region_code if strlen(region_code) == 1
merge 1:1 region_code using `r'
check_merge, master(0) using(0)
drop _merge
generate ratio = sinadef_rate / rate_2025
format sinadef_rate ratio %6.2f
gsort -rate_2025
list region rate_2025 sinadef_rate ratio hom, noobs
correlate rate_2025 sinadef_rate
display as text "Correlation of regional rates, CEIC vs SINADEF (2025): " %5.3f r(rho)
spearman rate_2025 sinadef_rate
display as text "Rank correlation: " %5.3f r(rho)
assert _N == 26
save "$est/bench_region2025.dta", replace
display as text "41_benchmarks: done"
