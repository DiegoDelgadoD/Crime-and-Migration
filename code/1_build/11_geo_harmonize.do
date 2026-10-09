*=====================================================================
* 11_geo_harmonize.do - district identifiers used by every panel
*
* Input : census 2025 district list (data/Consulta ... Sexo ... Distrital.xlsx)
*         $look/district_splits.csv (2025 district -> 2007 parent; filled
*         once the REDATAM 2007 export shows which districts differ)
* Output: $der/geo/geo_harmonized.dta
*
* hid is the district on 2007 boundaries. Until district_splits.csv is
* filled, hid equals the 2025 ubigeo (flag hid_provisional = 1).
*=====================================================================
if "$root" == "" exit 198

import excel using "$data/Consulta de población por Sexo, según nivel Distrital.xlsx", ///
    clear allstring
keep if ustrregexm(B, "^[0-9]{6}$")
keep B C D E
rename (B C D E) (ubigeo dep_name prov_name dist_name)
assert _N == 1893
isid ubigeo

generate str2 dept_id = substr(ubigeo, 1, 2)
generate str4 prov_id = substr(ubigeo, 1, 4)
generate byte lima_callao = inlist(prov_id, "1501") | dept_id == "07"
generate byte tumbes      = dept_id == "24"
label variable lima_callao "Lima province or Callao"

*---- Map to 2007 parents --------------------------------------------
generate str6 hid = ubigeo
generate byte hid_provisional = 1
capture confirm file "$look/district_splits.csv"
if !_rc {
    preserve
    import delimited "$look/district_splits.csv", clear varnames(1) stringcols(_all)
    local nsplit = _N
    tempfile splits
    if `nsplit' > 0 save `splits'
    restore
    if `nsplit' > 0 {
        merge 1:1 ubigeo using `splits', keep(master match) keepusing(hid2007)
        replace hid = hid2007 if _merge == 3
        drop _merge hid2007
        replace hid_provisional = 0
    }
}

compress
isid ubigeo
save "$der/geo/geo_harmonized.dta", replace
quietly levelsof dept_id
display as text "11_geo_harmonize: " _N " districts, " r(r) " departments"
