*=====================================================================
* 10_crosswalk.do - RENIEC <-> INEI district ubigeo crosswalk
*
* Input : $raw/ubigeo_crosswalk/ubigeo_distrito.csv (Castagnetto, MIT)
*         $raw/ubigeo_crosswalk/concytec_equivalencia-ubigeos-oti-concytec.csv
* Output: $der/geo/crosswalk_reniec_inei.dta (one row per INEI district)
*
* SINADEF residence codes are RENIEC-coded; census and SIDPOL use INEI.
* The four 2025 districts missing here (120307, 130112, 160405, 180107)
* are matched by name in 14_sinadef_panel.do.
*=====================================================================
if "$root" == "" exit 198

*---- Main crosswalk --------------------------------------------------
* Some quoted capital names contain line breaks, hence bindquote(strict)
import delimited "$raw/ubigeo_crosswalk/ubigeo_distrito.csv", clear ///
    varnames(1) stringcols(1 2) encoding("utf-8") bindquote(strict)
assert _N == 1893
keep inei reniec departamento provincia distrito altitude latitude longitude superficie

* Two rows carry "NA" codes in the source (checked 2026-09-30):
* - San Antonio (Mariscal Nieto, Moquegua) has RENIEC 170107 but no INEI
*   code. The 2025 census lists it as INEI 180107, so assign that code.
* - Santa Maria de Huachipa (INEI 150144) has no RENIEC code and is not
*   in the 2025 census district list, so drop it.
assert inei == "NA" if departamento == "MOQUEGUA" & provincia == "MARISCAL NIETO" & distrito == "SAN ANTONIO"
replace inei = "180107" if departamento == "MOQUEGUA" & provincia == "MARISCAL NIETO" & distrito == "SAN ANTONIO"
assert reniec == "NA" if inei == "150144"
drop if inei == "150144"
assert ustrregexm(inei, "^[0-9]{6}$") & ustrregexm(reniec, "^[0-9]{6}$")
isid inei
isid reniec
rename (altitude latitude longitude superficie) (alt_capital lat_capital lon_capital area_km2)
label variable alt_capital "Altitude of district capital, m (Castagnetto; source undocumented)"
tempfile main
save `main'

*---- Cross-check against CONCYTEC ------------------------------------
* Result of the check on 2026-09-30: the two sources differ for 47
* districts. For 46, SINADEF residence records pair the Castagnetto RENIEC
* code with the district's own name, and the CONCYTEC code with no record
* of it. The 47th, 150706 Cuenca (Huarochiri), appears in SINADEF under
* code 140606 with the name of its capital, San Jose de los Chorrillos.
* The differences come from CONCYTEC (last updated May 2021): it has no
* RENIEC code for districts created since, and uses the older INEI
* numbering in Tayacaja and Putumayo. Castagnetto stays the main source.
import delimited "$raw/ubigeo_crosswalk/concytec_equivalencia-ubigeos-oti-concytec.csv", ///
    clear varnames(1) stringcols(_all) encoding("latin1")
keep cod_ubigeo_inei cod_ubigeo_reniec
rename (cod_ubigeo_inei cod_ubigeo_reniec) (inei reniec_concytec)
* Missing codes are written as padded "NA" (e.g., "    NA")
replace inei = ustrtrim(inei)
replace reniec_concytec = ustrtrim(reniec_concytec)
replace inei = "" if inei == "NA"
replace reniec_concytec = "" if reniec_concytec == "NA"
drop if missing(inei)
duplicates drop
* A few INEI codes map to two RENIEC codes in CONCYTEC; list them and
* compare on the first one only (this file is a cross-check, not an input)
duplicates tag inei, generate(multi)
list inei reniec_concytec if multi, noobs sepby(inei)
bysort inei (reniec_concytec): keep if _n == 1
drop multi
isid inei
merge 1:1 inei using `main'
quietly count if _merge == 3 & missing(reniec_concytec)
display as text "Districts with no RENIEC code in CONCYTEC: " r(N)
quietly count if _merge == 3 & !missing(reniec_concytec) & reniec != reniec_concytec
display as text "Districts where the two sources give different RENIEC codes: " r(N)
list inei reniec reniec_concytec distrito if _merge == 3 & !missing(reniec_concytec) ///
    & reniec != reniec_concytec, noobs
tab _merge
keep if inlist(_merge, 2, 3)
drop _merge reniec_concytec

compress
isid inei
save "$der/geo/crosswalk_reniec_inei.dta", replace
display as text "10_crosswalk: " _N " districts saved"
