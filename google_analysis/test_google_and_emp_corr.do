*** Generate Table 5, regression of GJSI on unemployment rates ***
clear all

cap cd "~/Dropbox/Texas_Job_Search_New/restat_data/Google_Data/"
use  monthly_data_for_empirical_tests

*********************************************************************************************
*** Merge in new data
rename state state_abv
rename state_long state
sort Year Month state
merge 1:1 Year Month state using "all_aux_term_monthly_new.dta"
drop _merge

*********************************************************************************************

gen lbenefit = log(searchBen)
gen lunemp_emp = log(searchUnemp_Emp)
gen lunemp = log(searchUnemployment)
gen lweather = log(searchWeather)
   

sort stateyear Month
tab state, gen(ss)
gen period = Y + (Month-1)/12
tab period, gen(ym)
gen period_code = period*12
encode state, gen(state_code)
tsset state_code period_code

foreach var of varlist lbenefit lunemp_emp lunemp lweather lallsearch allsearch unemprate difflallsearch diffunemprate diffscinitialclaims forfinalpayments difftightness2 laglallsearch diffvacanciespercap scinitialclaims vacanciespercap tightness2 forfinalpayments {
	sum `var'
	replace `var' = `var'/r(sd)
}

label var unemprate "Unemployment Rate"

cap cd "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables/Tables"

reg lallsearch unemprate, cluster(stateyear)
outreg2 using Table1, tex(landscape pr frag) keep(unemprate) label replace addtext(Month FE, NO, State FE, NO) ctitle("Log(GJSI)") nocons

reg lallsearch unemprate mm*, cluster(stateyear)
outreg2 using Table1, tex(landscape pr frag) keep(unemprate) label  addtext(Month FE, YES, State FE, NO) ctitle("Log(GJSI)") nocons

reg lallsearch unemprate mm* ss*, cluster(stateyear)
outreg2 using Table1, tex(landscape pr frag) keep(unemprate) label  addtext(Month FE, YES, State FE, YES) ctitle("Log(GJSI)") nocons

reg lallsearch unemprate scinitialclaims mm*, cluster(stateyear)
outreg2 using Table1, tex(landscape pr frag) keep(unemprate scinitialclaims) label  addtext(Month FE, YES, State FE, NO) ctitle("Log(GJSI)") nocons

reg lallsearch unemprate scinitialclaims forfinalpayments mm*,  cluster(stateyear)
outreg2 using Table1, tex(landscape pr frag) keep(unemprate scinitialclaims forfinalpayments) label  addtext(Month FE, YES, State FE, NO) ctitle("Log(GJSI)") nocons

reg lallsearch unemprate scinitialclaims forfinalpayments mm* ss*,  cluster(stateyear)
outreg2 using Table1, tex(landscape pr frag) keep(unemprate scinitialclaims forfinalpayments) label  addtext(Month FE, YES, State FE, YES) ctitle("Log(GJSI)") nocons
