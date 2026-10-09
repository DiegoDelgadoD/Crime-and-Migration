*=====================================================================
* 16_poverty2018.do - INEI district poverty map 2018 (pre-period control)
*
* Input : $raw/poverty_map_2018/Anexo_Estadistico.xlsx, sheet Anexo2
*         (ubigeo, suffix, name, projected 2020 population, 95% interval
*          of total monetary poverty, poverty rank)
* Output: $der/controls/poverty2018.dta
*
* INEI publishes intervals, not point estimates; pov18 is the midpoint.
*=====================================================================
if "$root" == "" exit 198

import excel using "$raw/poverty_map_2018/Anexo_Estadistico.xlsx", sheet("Anexo2") clear allstring
keep if ustrregexm(A, "^[0-9]{6}$") & substr(A, 5, 2) != "00"
keep A B D E F G
rename (A B D E F G) (ubigeo suffix pop2020 pov18_lo pov18_hi pov18_rank)
destring pop2020 pov18_lo pov18_hi pov18_rank, replace
drop if missing(pov18_lo)
generate pov18 = (pov18_lo + pov18_hi) / 2
assert inrange(pov18_lo, 0, 100) & inrange(pov18_hi, 0, 100) & pov18_lo <= pov18_hi
label variable pov18 "Total monetary poverty 2018, % (midpoint of INEI 95% interval)"
duplicates report ubigeo
isid ubigeo

merge 1:1 ubigeo using "$der/geo/geo_harmonized.dta", keepusing(ubigeo)
quietly count if _merge == 2
display as text "2025 districts without a 2018 poverty estimate: " r(N)
if r(N) tab ubigeo if _merge == 2
quietly count if _merge == 1
display as text "2018 poverty districts not in the 2025 list: " r(N)
keep if _merge == 3
drop _merge
compress
save "$der/controls/poverty2018.dta", replace
display as text "16_poverty2018: " _N " districts"
