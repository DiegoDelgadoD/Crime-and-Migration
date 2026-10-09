*=====================================================================
* 19d_pre2017_crime.do - 2016 police reports by district (pre-period)
*
* Input : $raw/pre2017_crime/cap200_denuncias_2016.sav
*         INEI, Registro Nacional de Denuncias de Delitos y Faltas 2016,
*         Capitulo 200 (module 587-Modulo1199), SPSS version from
*         https://proyectos.inei.gob.pe/iinei/srienaho/descarga/SPSS/587-Modulo1199.zip
*         (the CSV in the open-data zip is corrupted: numeric fields are
*         unreadable, checked 2026-09-30).
* Output: $der/controls/pre2017_crime_2016.dta (district of occurrence)
*
* Privacy: the file is incident-level and includes the street, block,
* hour, document numbers and a person ID. Only the variables below are
* loaded; the rest never enter memory, and nothing is listed by record.
*
* Records come from two bases: BASE 1 (police registry, crime type in the
* numeric code IH208) and BASE 2 (SIDPOL, crime type as text). The 2016
* registry did not cover every police unit (analysis plan, missing data),
* so these counts are a partial baseline, not a full count.
*=====================================================================
if "$root" == "" exit 198

import spss BASE ID_N IH203_ANIO IH205_DD IH205_PP IH205_DIS IH208 ///
    DELITO_ESPECIFICO DELITO_MODALIDAD ///
    using "$raw/pre2017_crime/cap200_denuncias_2016.sav", clear
assert IH203_ANIO == 2016
generate str6 ubigeo = IH205_DD + IH205_PP + IH205_DIS
assert ustrregexm(ubigeo, "^[0-9]{6}$")

generate strL esp = ustrupper(ustrtrim(DELITO_ESPECIFICO))
generate strL mod = ustrupper(ustrtrim(DELITO_MODALIDAD))

* Intentional homicide (excludes culpable homicide and mercy killing)
generate byte hom = (BASE == 1 & inlist(IH208, 1, 2, 3, 4, 5, 7, 8)) | ///
    (BASE == 2 & esp == "HOMICIDIO" & mod != "HOMICIDIO CULPOSO")
generate byte sicariato = (BASE == 1 & IH208 == 8) | ///
    (BASE == 2 & (ustrregexm(mod, "SICARIATO") | ustrregexm(mod, "^LA CONSPIRACI")))
generate byte hom_paf   = BASE == 2 & mod == "HOMICIDIO POR PAF"
generate byte extorsion = (BASE == 1 & inlist(IH208, 117, 119)) | (BASE == 2 & esp == "EXTORSION")
generate byte robo      = (BASE == 1 & inrange(IH208, 99, 101)) | (BASE == 2 & ustrregexm(esp, "^ROBO"))
generate byte hurto     = (BASE == 1 & inrange(IH208, 95, 98)) | (BASE == 2 & esp == "HURTO")
generate byte any       = 1
generate byte from_registry = BASE == 1

tabstat hom sicariato hom_paf extorsion robo hurto any, by(BASE) stat(sum) format(%10.0fc)

collapse (sum) pre16_hom = hom pre16_sicariato = sicariato pre16_hom_paf = hom_paf ///
    pre16_extorsion = extorsion pre16_robo = robo pre16_hurto = hurto ///
    pre16_all = any pre16_registry = from_registry, by(ubigeo)

merge 1:1 ubigeo using "$der/geo/geo_harmonized.dta", keepusing(ubigeo)
quietly count if _merge == 1
display as text "2016 district codes not in the 2025 list: " r(N)
if r(N) list ubigeo pre16_all if _merge == 1, noobs
drop if _merge == 1
generate byte pre16_any_report = _merge == 3
drop _merge
foreach v of varlist pre16_* {
    replace `v' = 0 if missing(`v')
}
label variable pre16_any_report "District has any 2016 report (0 = none, not a true zero)"
isid ubigeo
assert _N == 1893
compress
save "$der/controls/pre2017_crime_2016.dta", replace
quietly count if pre16_any_report
display as text "19d_pre2017_crime: " r(N) " of 1,893 districts with any 2016 report"
