*** File runs regressions for national results table.
clear all
set mem 1100m
set more off

cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/restat_data/National_Analysis_Data"


local states "AL AR AZ CA CO CT DC DE FL GA HI IL IN KS KY LA MA MD MI MN MO MS NC NE NH NJ NM NV NY OH OK OR PA RI SC TN TX UT VA WA WI WV AK ME MT WY ND SD VT IA ID"

use final_merged_data

***Drop data from 2015->
drop if year>2014

*** Observations we don't want to use:
drop if year<2005
drop if state=="LA" & year==2005

tsset state_code year_month

gen ljobs_search = log(jobs_search)

*** Define post-expansion varible. Use only changes due to triggers and legislation (hence current policy)
order state year month alt_totwks
gen alt_totweeks_nonsmooth = alt_totwks
gen ui_expansion_ind_nonsmooth = l.alt_totwks<alt_totwks & l.alt_totwks!=.

*** Remove declines in weeks left to calculate policy changes:
*replace alt_totwks = max(alt_totwks, l.alt_totwks, l2.alt_totwks, l3.alt_totwks) 
 
gen ui_expansion_ind = l.alt_totwks<alt_totwks & l.alt_totwks!=.
gen post_legislation = ui_expansion_ind+l.ui_expansion_ind

replace post_legislation = ui_expansion_ind if l.ui_expansion_ind==.
replace post_legislation = 1 if post_legislation==2

*** Create scaled variables:
gen frac_lf = labor_force/population
rename labor_force tot_lf
replace unemp_rate = unemp_rate/100
replace insured_unemp_rate = insured_unemp_rate/100
gen total_ui = cont_claims + init_claims
gen total_not_ui = tot_lf*unemp_rate - total_ui

gen frac_ui = total_ui/tot_lf
gen frac_emp = (employment)/tot_lf
gen frac_not_ui = (unemployment - total_ui)/tot_lf
gen frac_total_ui = total_ui/tot_lf
gen lpop = log(population)
gen frac_unemp = frac_total_ui + frac_not_ui

foreach var of varlist *weeks_left* {
	gen frac_`var' = `var'/cps_count*frac_ui
	replace frac_`var' = 0 if frac_`var'==.
}

replace wage = wage/1000

gen frac_near_exp = frac_weeks_left_0_9+frac_weeks_left_10_19
*** replace frac_near_exp = .0002125 if frac_near==0 //this is the min non-zero value
gen frac_med_exp = frac_weeks_left_20_29+frac_weeks_left_30_39
*** replace frac_med_exp = .0002992 if frac_med==0
gen frac_far_exp = frac_weeks_left_40_49+frac_weeks_left_50_59+frac_weeks_left_60_69+frac_weeks_left_70_79+frac_weeks_left_80_89
*** replace frac_far_exp = .0003054 if frac_far_exp==0

qui tab year_month, gen(ym)
tab state, gen(ss)
tab year, gen(yy)
tab month, gen(mm)

label var post_legislation "Post Expansion"
label var frac_emp "Share Employed"
label var frac_total_ui "Share On UI"
label var frac_not_ui "Share Not on UI"
label var unemp_rate "Unemployment Rate"
label var frac_ui "Fraction on UI"
label var frac_near_exp "Share $<$10 Weeks Left"
label var frac_weeks_left_0 "Frac Under 10 Weeks Left"
label var frac_weeks_left_10 "Frac 10-19 Weeks Left"
label var frac_weeks_left_20 "Frac 20-29 Weeks Left"
label var frac_weeks_left_30 "Frac 30-39 Weeks Left"
label var frac_weeks_left_40 "Frac 40-49 Weeks Left"
label var frac_weeks_left_50 "Frac 50-59 Weeks Left"
label var frac_weeks_left_60 "Frac 60-69 Weeks Left"
label var frac_weeks_left_70 "Frac 70 or more Weeks Left"
label var totwks "Potential Benefit Duration"
label var alt_totwks "Potential Benefit Duration"
label var frac_med_exp "Frac 10-40 Weeks Left"
label var frac_far_exp "Frac 40$+$ Weeks Left"
label var insured_unemp_rate "Insured Unemp. Rate"

*** State specific trends:
tab state, gen(statecode)
forvalues num = 1/51 {
    cap gen statedate`num' = statecode`num'*year_month
    cap gen sq_statedate`num' = statedate`num'^2
}

*** Seasonality FE
egen state_month_group = group(state month)

***Other VAR construction
gen dljobs_search = d.ljobs_search 
gen l_ui_expansion_ind = l.ui_expansion_ind
gen  d_unemp_rate = d.unemp_rate
gen  d_frac_near_exp = d.frac_near_exp
gen unemp_rate_sq = unemp_rate^2
label var unemp_rate "Unemployment Rate"
label var dljobs_search "Change in Job Search"
label var l_ui_expansion_ind "Post Expansion"
label var d_unemp_rate "Change in Unemp. Rate"
label var d_frac_near_exp "Change in Frac Near Expiration"
label var wage "Average Wk. Wage ('000)"
label var unemp_rate_sq "Unemp. Rate Sq."
replace l_ui_expansion = 0 if l_ui_expansion==.
replace l_ui_expansion = 0 if l_ui_expansion==.
fvset base 1 year_month
label var frac_lf "Frac. Pop in Lab. Force"

cd "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables"

*******************************************************
*** National Search Outcomes Table - OLS - RESTAT FINAL
*******************************************************
eststo clear
eststo: areg ljobs_search alt_totwks i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search alt_totwks unemp_rate i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate frac_lf i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate frac_lf statedate* sq_statedate* i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "Yes"

eststo: areg ljobs_search alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate wage frac_lf i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate frac_lf i.year_month if l.month!=. & year<=2011, ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate frac_lf i.year_month if l.month!=. & year>2011, ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

cd "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables"
esttab using "Tables/national_regs_new_restat", tex se keep(alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate  frac_lf wage) order(alt_totwks unemp_rate unemp_rate_sq insured_unemp_rate  frac_lf wage) scalars("stfe State FE" "myfe Year-Month FE" "trends Linear and Quadratic State Trends" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes obslast replace label gaps wrap


****************************************************************
*** Robustness: Just use a before and after expansion indicator
****************************************************************

eststo clear
eststo: areg ljobs_search l_ui_expansion_ind i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search l_ui_expansion_ind unemp_rate unemp_rate_sq i.year_month  if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg ljobs_search l_ui_expansion_ind unemp_rate unemp_rate_sq sq_statedate* statedate* i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "Yes"

eststo: areg dljobs_search l_ui_expansion_ind unemp_rate unemp_rate_sq i.year_month  if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "No"

eststo: areg dljobs_search l_ui_expansion_ind unemp_rate unemp_rate_sq sq_statedate* statedate* i.year_month if l.month!=., ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local trends "Yes"

cd "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables"
esttab using "Tables/robust_expansion_restat", tex se keep(l_ui_expansion_ind unemp_rate unemp_rate_sq) order(l_ui_expansion_ind  unemp_rate unemp_rate_sq) scalars("stfe State FE" "myfe Year-Month FE""trends Linear and Quadratic State Trends" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes obslast replace label gaps wrap


