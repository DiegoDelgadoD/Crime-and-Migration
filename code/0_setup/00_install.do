*=====================================================================
* 00_install.do - install user-written packages into code/ado/plus
*
* Called by master.do when the pinned folder lacks ivreghdfe. Writes the
* installed versions to output/logs/package_versions.log and runs smoke
* tests on sysuse auto. Stage 1 (build) uses only built-in commands.
*
* Sources checked 2026-09-29 (see .claude/2026-09-29_analysis_plan.md).
* Not verified: the tF program of Lee et al. (2022); 52_weakiv_inference
* will use a lookup of their Table 3 critical values if it is missing.
*=====================================================================
if "$root" == "" exit 198

local ssc require ftools reghdfe ranktest ivreg2 ivreghdfe avar moremata  ///
          weakivtest weakiv boottest ppmlhdfe hdfe acreg mvtnorm plausexog ///
          rwolf did_multiplegt_stat did_multiplegt_dyn jwdid gtools estout ///
          coefplot spmap shp2dta geonear ritest

local failed ""
foreach p of local ssc {
    capture noisily ssc install `p', replace
    if _rc local failed "`failed' `p'"
}

* GitHub-only packages
capture noisily net install ivppmlhdfe, replace ///
    from("https://raw.githubusercontent.com/ekwonomist/ivppmlhdfe/main/")
if _rc local failed "`failed' ivppmlhdfe"
capture noisily net install scpc, replace ///
    from("https://raw.githubusercontent.com/ukmueller/SCPC/master/src")
if _rc local failed "`failed' scpc"
capture noisily net install honestdid, replace ///
    from("https://raw.githubusercontent.com/mcaceresb/stata-honestdid/main")
if _rc local failed "`failed' honestdid"
capture noisily net install spur, replace ///
    from("https://raw.githubusercontent.com/pdavidboll/SPUR/main/")
if _rc local failed "`failed' spur"
capture noisily net install binsreg, replace ///
    from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata/")
if _rc local failed "`failed' binsreg"

* Compile Mata libraries
capture noisily ftools, compile
capture noisily reghdfe, compile

display as text "Packages that failed to install: `failed'"

*---------------- Record versions ------------------------------------
log using "$logs/package_versions.log", replace text name(pkgver)
display "Package versions installed `c(current_date)' in `c(sysdir_plus)'"
ado dir
foreach p in reghdfe ivreghdfe ivreg2 ppmlhdfe boottest acreg weakivtest {
    capture noisily which `p'
}
log close pkgver

*---------------- Smoke tests ----------------------------------------
sysuse auto, clear
ivreghdfe price (mpg = weight), absorb(foreign) cluster(rep78)
assert e(N) > 0
ppmlhdfe price mpg, absorb(foreign) vce(robust)
assert e(N) > 0
ivreg2 price (mpg = weight), robust
boottest mpg, reps(199) seed(1) nograph
weakivtest
display as text "00_install.do: smoke tests passed"
if "`failed'" != "" display as error "Install failures to resolve: `failed'"
