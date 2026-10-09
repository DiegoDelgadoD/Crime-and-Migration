*=====================================================================
* 50_first_stage.do - instrument relevance (spec 1-2), no outcomes used
*
* Input : $der/analysis/ld_district.dta
* Output: $est/fs_diag.dta (one row per specification)
*
* First stage: dV on the excluded instruments, pre-period controls and
* department fixed effects, weighted by GHSL 2015 population, clustered by
* province. With one endogenous regressor, the cluster-robust Wald F on the
* excluded instruments equals the Kleibergen-Paap Wald F, and with one
* instrument it equals the Montiel Olea-Pflueger effective F (Pflueger and
* Wang 2015, p. 7). Report it as a diagnostic, not as a screen
* (Andrews, Stock, and Sun 2019, pp. 20-21).
*
* Altitude (Z3) appears alone only as a diagnostic; the plan uses it only
* as an over-identifying instrument (analysis plan, spec 2).
* dV is provisional (2025 share) until the 2017 census export exists.
*=====================================================================
if "$root" == "" exit 198

use "$der/analysis/ld_district.dta", clear
local X "ltt_lima larea ldens15 lat lon lat2 lon2 latlon pov18"
capture confirm variable z1_share07
local haveZ1 = !_rc

tempname h
postfile `h' str12 spec str40 instr str24 sample double(b1 se1 b2 se2 F N G) ///
    using "$est/fs_diag.dta", replace

local sets "z2_ltt|z3_alt|z2_ltt z3_alt|z2_lkm"
if `haveZ1' local sets "`sets'|z1_share07|z1_share07 z2_ltt|z1_share07 z3_alt"

foreach smp in all nolima {
    local cond "1"
    if "`smp'" == "nolima" local cond "!lima_callao"
    local rest "`sets'"
    local k 0
    while "`rest'" != "" {
        gettoken Z rest : rest, parse("|")
        if "`Z'" == "|" continue
        local ++k
        quietly reghdfe dv `Z' `X' [aw=w] if `cond', absorb(dept_id) vce(cluster prov_id)
        quietly test `Z'
        local F = r(F)
        local z1 : word 1 of `Z'
        local z2 : word 2 of `Z'
        local b2 = .
        local s2 = .
        if "`z2'" != "" {
            local b2 = _b[`z2']
            local s2 = _se[`z2']
        }
        post `h' ("spec`k'") ("`Z'") ("`smp'") (_b[`z1']) (_se[`z1']) (`b2') (`s2') ///
            (`F') (e(N)) (e(N_clust))
        display as text %-8s "`smp'" %-28s "`Z'" "  F = " %8.2f `F' "  N = " e(N) "  G = " e(N_clust)
    }
}
* Diagnostic: Z2 without the travel-time-to-Lima control (Lima lies on
* the route from Tumbes, so the two travel times are correlated)
local dropc "ltt_lima"
local Xnl : list X - dropc
display as text "Controls without Lima travel time: `Xnl'"
foreach smp in all nolima {
    local cond "1"
    if "`smp'" == "nolima" local cond "!lima_callao"
    foreach Z in z2_ltt z2_lkm {
        quietly reghdfe dv `Z' `Xnl' [aw=w] if `cond', absorb(dept_id) vce(cluster prov_id)
        quietly test `Z'
        local F = r(F)
        post `h' ("noLimaCtl") ("`Z'") ("`smp'") (_b[`Z']) (_se[`Z']) (.) (.) ///
            (`F') (e(N)) (e(N_clust))
        display as text %-8s "`smp'" %-28s "`Z' (no Lima control)" "  F = " %8.2f `F'
    }
}
quietly correlate z2_ltt ltt_lima [aw=w]
display as text "Correlation of log travel time to CEBAF and to Lima: " %5.3f r(rho)
postclose `h'

use "$est/fs_diag.dta", clear
format b1 se1 b2 se2 %9.4f
format F %9.2f
list, noobs sepby(sample)
display as text "50_first_stage: done (dV provisional if 2017 census missing)"
