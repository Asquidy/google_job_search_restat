clear all
set more off

use "Other Data/tx_msa_unemp.dta"

drop unemp_rate

gen area_short = regexr(area_name, ",.*$", "")

replace area_short = "Abilene-Sweetwater" if area_short=="Abilene"|area_short=="Sweetwater"
replace area_short = "Austin" if area_short=="Austin-Round Rock"
replace area_short = "Harlingen" if area_short=="Brownsville-Harlingen"
replace employment = -employment if area_short=="Huntsville"
replace labor = -labor if area_short=="Huntsville"
replace area_short = "Houston" if area_short=="Houston-Baytown-Huntsville"|area_short=="Huntsville"
replace area_short = "Waco-Temple-Bryan" if area_short=="Waco"|area_short=="College Station-Bryan"
replace area_short = "Sherman" if area_short=="Sherman-Denison"
replace area_short="Odessa-Midland" if area_short=="Midland-Odessa"
replace area_short="Tyler-Longview" if area_short=="Longview"|area_short=="Tyler"

collapse (sum) employment labor_force, by(area_short year month)
gen unemp_rate = (1-(emp/labor))*100

rename area_short msa
compress
save "Other Data/clean_tx_msa_unemp.dta", replace


