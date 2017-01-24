*** Combines CPS Data w/ Google Search Data and Other Labor Force Statistics at State - Month Level.
clear all
set mem 1100m
set more off

cap cd "C:\Users\ScottHome\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "~/Dropbox/Texas_Job_Search_New/National_Analysis_Data"

local states "AL AR AZ CA CO CT DC DE FL GA HI IL IN KS KY LA MA MD MI MN MO MS NC NE NH NJ NM NV NY OH OK OR PA RI SC TN TX UT VA WA WI WV AK ME MT WY ND SD VT IA ID"

use rothstein_data

**Keeps only if they could be reinterviewed twice
keep if hrmis==1 | hrmis==2 | hrmis==5 | hrmis==6

*** Generate variables about CPS individuals, including transitions. 
gen matched1=(obsnum<nobs)
gen matched2=(obsnum<nobs-1)
gen dur1=(uedur>=0 & uedur<=13)
gen dur2=(uedur>=14 & uedur<=26)
gen dur3=(uedur>=27 & uedur<99)
gen dur4=(uedur==99)
gen reemp3=reemp*exit3
gen lfexit3=lfexit*exit3

*** Correction of Rothstein
replace totwks = 93 if totwks==92

*** Weeks left given eligibility
gen e_wksleft=wksleft*uielig
gen e_alt_totwks=alt_totwks*uielig
gen e_alt_wksleft = e_alt_totwks-uedur
replace e_alt_wksleft = 0 if e_alt_wksleft<0

label var e_alt_totwks "anticipating EUC reauthorization"

rename hryear year
rename hrmon month

keep if uielig

rename st_cens gestcen

merge m:1 gestcen using gestcenstate
drop _merge regstate
rename state state_long
rename State state

*** Save alt_totwks
preserve
	keep year month state alt_totwks
	collapse alt_totwks, by(year month state)
	save national_current_policy_wks, replace
restore

keep year month state state_long gestcen e_totwks e_alt_totwks e_wksleft e_alt_wksleft uedur totwks

forvalues x = 9(10)99 {
	local y = `x'-9
	gen weeks_left_`y'_`x' = e_wksleft>=`y' & e_wksleft<=`x'
	gen alt_weeks_left_`y'_`x' = e_alt_wksleft>=`y' & e_alt_wksleft<=`x'
}

gen cps_count = 1

collapse totwks (sum) alt_weeks_left* weeks_left* cps_count, by(year month state gestcen state_long)

sort state year month
order state year month totwks
egen year_month = group(year month)
tsset gestcen year_month

tsfill, full
replace month = l.month+1 if month==.
foreach var of varlist totwks state gestcen year {
	cap replace `var' = l.`var' if `var'==.
	cap replace `var' = `var'[_n-1] if `var'==""
}

replace totwks = l.totwks if totwks==.
foreach var of varlist alt_weeks_left* weeks_left*{
	replace `var' = 0 if `var'==.
}
replace totwks = 93 if totwks==92

order state year month totwks
gen ui_expansion_ind = l.totwks!=totwks & l.totwks!=.

*** Merge in unemployment data
merge 1:1 year month state using unemp_rate_by_state
drop if _merge==2|_merge==1
drop _merge

* preserve
* clear
* import excel using state_population.xls, firstrow
* reshape long year_, i(state_long) j(year)
* rename year_ population

* save state_population, replace
* restore

*** Merge w/ State Stats
replace state_long = regexr(state_long, "^ ", "")
merge m:1 year state_long using state_population
drop if _merge==2|_merge==1
drop _merge

merge 1:1 year month state using all_claims_data
drop if _merge==2
drop _merge

merge 1:1 year month state using labor_force
drop if _merge==2
drop _merge

*** Merge with search
rename state state_abrv
cap cd "C:\Users\ScottHome\Dropbox\Texas Job Search - New\Google_Data\StateMonthly_1"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\Google_Data\StateMonthly_1"
cap cd "~/Dropbox/Texas_Job_Search_New/Google_Data/StateMonthly_1/"

merge 1:1 year month state_abrv using final_monthly_search_data
drop if _merge==2
drop _merge
rename state_abrv state

cap cd "C:\Users\ScottHome\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "~/Dropbox/Texas_Job_Search_New/National_Analysis_Data"

*** Merge with current policy weeks
merge 1:1 year month state using national_current_policy_wks
drop if _merge==2
drop _merge

***************************************************************************************************
***Add in new unemp/wages/total weeks/etc. for RESTAT revision*************************************
cd "C:\Users\ScottHome\Dropbox\Texas Job Search - New\RESTAT Revision Data (Updates)"

drop population unemp_rate labor_force init_claims cont_claims

*merge 1:1 state year month using all_new_macro_data_monthly
*drop _merge

****************************************
**Now merge in new weeks available data and macro data
merge 1:1 state year month using new_euc_eb_weeks_monthly
drop _merge
drop if year<2004

**Fill in with new weeks available data
replace alt_totwks = total_weeks if total_weeks!=.
drop total_weeks

cap drop year_month
gen year_month = (year + (month-1)/12)*12
encode state, gen(state_code)

/**New macro vars = 
labor_force
unemp_rate
population
employment
unemployment
insured_unemp_rate
*/

**Fill down for 2015/2016
tsset state_code year_month
replace alt_totwks = l.alt_totwks if alt_totwks==. & year>2014

drop gestcen state_long ui_expansion_ind

****************************************
**Load in new Google Search data
rename jobs_search old_jobs_search

merge 1:1 state year month using final_monthly_search_data_2016
drop if _merge==2
drop _merge

corr old_jobs_search jobs_search


***************************************************************************************************
cap cd "C:\Users\ScottHome\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "~/Dropbox/Texas_Job_Search_New/National_Analysis_Data"

compress
save final_merged_data, replace
