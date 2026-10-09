*=====================================================================
* 23_import_instruments.do - instruments and geographic controls
*
* Inputs: $gis/district_geometry.csv     (code/gis/17_district_geometry.py)
*         $gis/altitude.csv              (code/gis/22_altitude_popw.py)
*         $gis/travel_time_cebaf.csv     (code/gis/21_travel_time_cebaf.py)
*         $der/instruments/z1.dta        (20_z1_share2007.do, once REDATAM 2007 exists)
* Output: $der/instruments/instruments.dta (one row per 2025 district)
*
* Z2 = log road travel time (hours) from CEBAF Tumbes on the 2017-01-01
*      OSM network, from the GHSL 2015 population-weighted centroid.
* Z3 = GHSL 2015 population-weighted altitude (km), Copernicus GLO-90.
* Three 2025 districts (120307, 130112, 160405) are missing from the INEI
* boundary file and the crosswalk, so their geographic variables are
* missing until their parent districts are coded.
*=====================================================================
if "$root" == "" exit 198

import delimited "$gis/district_geometry.csv", clear varnames(1) stringcols(1)
isid ubigeo
tempfile geo
save `geo'
import delimited "$gis/altitude.csv", clear varnames(1) stringcols(1)
isid ubigeo
merge 1:1 ubigeo using `geo'
check_merge, master(0) using(0)
drop _merge
save `geo', replace
import delimited "$gis/travel_time_cebaf.csv", clear varnames(1) stringcols(1)
rename (lat lon) (lat_pt lon_pt)
isid ubigeo
merge 1:1 ubigeo using `geo'
check_merge, master(0) using(0)
drop _merge

merge 1:1 ubigeo using "$der/geo/geo_harmonized.dta", keepusing(ubigeo)
quietly count if _merge == 1
display as text "Boundary districts not in the 2025 list: " r(N)
assert r(N) == 0
quietly count if _merge == 2
display as text "2025 districts without geography: " r(N)
assert r(N) <= 3
generate byte geo_missing = _merge == 2
drop _merge

*---- Instruments -----------------------------------------------------
generate z2_ltt  = ln(tt_cebaf_h + 0.5)
generate z2_lkm  = ln(km_cebaf + 1)
generate z3_alt  = alt_popw / 1000
label variable z2_ltt "Z2: log(hours + 0.5), road travel time from CEBAF Tumbes (OSM 2017)"
label variable z2_lkm "Z2 variant: log(km + 1), shortest road distance from CEBAF Tumbes"
label variable z3_alt "Z3: population-weighted altitude, km (GHSL 2015, GLO-90)"

*---- Geographic controls (all pre-period or time-invariant) ----------
generate ltt_lima = ln(tt_lima_h + 0.5)
generate larea    = ln(area_km2)
generate ldens15  = ln(pop_ghsl15 / area_km2)
* Centered near Peru's middle; raw squares (lon^2 near 5,700) make the
* reghdfe cluster VCE numerically singular (checked 2026-09-30)
generate lat  = lat_popw + 10
generate lon  = lon_popw + 75
generate lat2 = lat^2
generate lon2 = lon^2
generate latlon = lat * lon
label variable lat "Latitude of GHSL-weighted centroid + 10"
label variable lon "Longitude of GHSL-weighted centroid + 75"
generate byte snap_far = snap_km > 20 if !missing(snap_km)
label variable ltt_lima "log(hours + 0.5), road travel time to Lima (OSM 2017)"
label variable ldens15  "log GHSL 2015 population per km2"
label variable snap_far "District point more than 20 km from the road network"

capture confirm file "$der/instruments/z1.dta"
if !_rc {
    merge 1:1 ubigeo using "$der/instruments/z1.dta", keep(master match) nogenerate
}

isid ubigeo
assert _N == 1893
compress
save "$der/instruments/instruments.dta", replace
summarize z2_ltt z3_alt ltt_lima ldens15 snap_far
display as text "23_import_instruments: done"
