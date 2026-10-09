*=====================================================================
* 12_census2025.do - 2025 census district file
*
* Inputs: data/Consulta de población por Sexo, según nivel Distrital.xlsx
*         data/Consulta de población por Población inmigrante extranjera
*              por grandes grupos edad, según nivel Distrital.xlsx
*         $raw/census2025/census2025_foreign_born_top6_by_district.csv
*              (code/00_fetch_census2025_country_of_birth.py)
* Output: $der/census/census2025_district.dta
*
* Populations are censused persons (not including the 1.45 million
* omitted persons that INEI adds in Indicadores_demograficos INDDEM01).
* Venezuela-born counts come from the top-six country list; where
* Venezuela is not listed, the count is censored and bounded.
*=====================================================================
if "$root" == "" exit 198

*---- Population by sex -----------------------------------------------
import excel using "$data/Consulta de población por Sexo, según nivel Distrital.xlsx", ///
    clear allstring
keep if ustrregexm(B, "^[0-9]{6}$")
keep B F G H
rename (B F G H) (ubigeo pop25 male25 female25)
* INEI prints "-" for zero
foreach v in pop25 male25 female25 {
    replace `v' = "0" if ustrtrim(`v') == "-"
}
destring pop25 male25 female25, replace
assert pop25 == male25 + female25
isid ubigeo
assert _N == 1893
quietly summarize pop25
assert r(sum) == 32706028
tempfile pop
save `pop'

*---- Foreign-born by age group ---------------------------------------
import excel using "$data/Consulta de población por Población inmigrante extranjera por grandes grupos edad, según nivel Distrital.xlsx", ///
    clear allstring
keep if ustrregexm(B, "^[0-9]{6}$")
keep B F G H I
rename (B F G H I) (ubigeo fb25 fb25_0014 fb25_1559 fb25_60p)
foreach v of varlist fb25* {
    replace `v' = "0" if ustrtrim(`v') == "-"
}
destring fb25*, replace
assert fb25 == fb25_0014 + fb25_1559 + fb25_60p
isid ubigeo
quietly summarize fb25
assert r(sum) == 1052977
merge 1:1 ubigeo using `pop'
check_merge, master(0) using(0)
drop _merge
tempfile fb
save `fb'

*---- Venezuela-born from the top-six list ----------------------------
import delimited "$raw/census2025/census2025_foreign_born_top6_by_district.csv", ///
    clear varnames(1) stringcols(1) encoding("utf-8")
assert ustrregexm(ubigeo, "^[0-9]{6}$")
bysort ubigeo: egen n_listed   = total(!missing(country))
bysort ubigeo: egen sum_listed = total(count)
bysort ubigeo: egen rank6_cnt  = total(cond(rank == 6, count, 0))
generate byte is_ven = country == "Venezuela"
bysort ubigeo: egen ven_listed = total(cond(is_ven, count, 0))
bysort ubigeo: egen any_ven    = max(is_ven)
bysort ubigeo: keep if _n == 1
keep ubigeo foreign_born_total n_listed sum_listed rank6_cnt ven_listed any_ven
isid ubigeo
assert _N == 1893

* Venezuela censored only if six countries are listed and it is not one
generate byte ven_censored = (any_ven == 0 & n_listed == 6)
generate ven25 = ven_listed if !ven_censored
generate ven25_lb = cond(ven_censored, 0, ven25)
generate ven25_ub = cond(ven_censored, min(rank6_cnt, foreign_born_total - sum_listed), ven25)
label variable ven25        "Venezuela-born, 2025 census (missing if censored)"
label variable ven_censored "Venezuela not in the district's top six countries"
label variable ven25_lb "Venezuela-born, lower bound"
label variable ven25_ub "Venezuela-born, upper bound"
quietly summarize ven_listed
assert r(sum) == 909684

merge 1:1 ubigeo using `fb'
check_merge, master(0) using(0)
drop _merge
assert foreign_born_total == fb25
drop foreign_born_total n_listed sum_listed rank6_cnt ven_listed any_ven

generate vshare25    = ven25 / pop25
generate vshare25_lb = ven25_lb / pop25
generate vshare25_ub = ven25_ub / pop25
generate fbshare25   = fb25 / pop25
assert inrange(vshare25_lb, 0, 1) & vshare25_lb <= vshare25_ub
label variable vshare25  "Venezuela-born share of population, 2025"
label variable fbshare25 "Foreign-born share of population, 2025"

merge 1:1 ubigeo using "$der/geo/geo_harmonized.dta", keepusing(hid dept_id prov_id lima_callao tumbes)
check_merge, master(0) using(0)
drop _merge

compress
isid ubigeo
save "$der/census/census2025_district.dta", replace

quietly count if ven_censored
display as text "12_census2025: " _N " districts; Venezuela censored in " r(N)
quietly summarize ven25_ub if ven_censored
display as text "  upper bound on Venezuela-born in censored districts: " r(sum)
