*=====================================================================
* programs.do - helper programs shared by all scripts
*=====================================================================

* fix_ubigeo: zero-pad a numeric or string ubigeo to 6 characters.
capture program drop fix_ubigeo
program define fix_ubigeo
    syntax varname, GENerate(name)
    capture confirm string variable `varlist'
    if _rc {
        generate str6 `generate' = string(`varlist', "%06.0f") if !missing(`varlist')
    }
    else {
        generate str6 `generate' = ustrtrim(`varlist')
        replace `generate' = "0" + `generate' if strlen(`generate') == 5
    }
    quietly count if !missing(`generate') & !ustrregexm(`generate', "^[0-9]{6}$")
    if r(N) {
        display as error "fix_ubigeo: `r(N)' values are not 6-digit codes"
        exit 459
    }
end

* normname: uppercase, strip accents and punctuation, collapse spaces.
capture program drop normname
program define normname
    syntax varname(string), GENerate(name)
    generate str244 `generate' = ustrupper(ustrtrim(`varlist'))
    replace `generate' = ustrregexra(ustrnormalize(`generate', "nfd"), "\p{M}", "")
    replace `generate' = ustrregexra(`generate', "[^A-Z0-9 ]", " ")
    replace `generate' = ustrregexra(`generate', " +", " ")
    replace `generate' = ustrtrim(`generate')
end

* check_merge: assert the counts of _merge categories.
*   check_merge, master(#) using(#)   (omit an option to skip that check)
capture program drop check_merge
program define check_merge
    syntax [, Master(integer -1) Using(integer -1) Matched(integer -1)]
    quietly count if _merge == 1
    local n1 = r(N)
    quietly count if _merge == 2
    local n2 = r(N)
    quietly count if _merge == 3
    local n3 = r(N)
    display as text "merge: master only `n1', using only `n2', matched `n3'"
    if `master'  >= 0 assert `n1' == `master'
    if `using'   >= 0 assert `n2' == `using'
    if `matched' >= 0 assert `n3' == `matched'
end
