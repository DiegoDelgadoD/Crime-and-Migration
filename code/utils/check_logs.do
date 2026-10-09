*=====================================================================
* check_logs.do - fail if any stage log contains a Stata error code
* or an empty-sample message. Error lines start with r(###);.
*=====================================================================
mata:
real scalar _count_bad(string scalar fn)
{
    real scalar fh, n
    string scalar line, msg
    msg = "no " + "observations"
    n  = 0
    fh = fopen(fn, "r")
    while ((line = fget(fh)) != J(0, 0, "")) {
        if (regexm(line, "^r\([0-9]+\);") | strpos(line, msg)) n++
    }
    fclose(fh)
    return(n)
}
end

local files : dir "$logs" files "*.log"
local bad 0
foreach f of local files {
    if "`f'" == "package_versions.log" continue
    mata: st_local("n", strofreal(_count_bad("$logs/`f'")))
    if `n' > 0 {
        display as error "`f': `n' flagged lines"
        local bad = `bad' + `n'
    }
}
display as text "check_logs: `bad' flagged lines in `: word count `files'' logs"
assert `bad' == 0
