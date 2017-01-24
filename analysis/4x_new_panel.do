*** File runs regressions for national results table.
clear all
set mem 1100m
set more off

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "~/Dropbox/Texas_Job_Search_New/National_Analysis_Data"

local states "AL AR AZ CA CO CT DC DE FL GA HI IL IN KS KY LA MA MD MI MN MO MS NC NE NH NJ NM NV NY OH OK OR PA RI SC TN TX UT VA WA WI WV AK ME MT WY ND SD VT IA ID"

use final_merged_data
tsset gestcen year_month

drop if year<2005
gen ljobs_search = log(jobs_search)
egen max_pop = max(pop), by(state)
*** keep if max_pop > 2000000
order state year month alt_totwks
cap drop ui_expansion_ind
gen ui_expansion_ind = l.alt_totwks>alt_totwks & l.alt_tot!=.

gen ui_expansion_ind_2mon = ui_expansion_ind
replace ui_expansion_ind_2mon = 1 if ui_expansion_ind_2mon==0 & l.ui_expansion_ind_2mon==1 & l2.ui_expansion_ind_2mon==0

replace unemp_rate = unemp_rate/100
gen total_ui = cont_claims + init_claims
gen frac_ui = total_ui/population
gen lpop = log(population)
gen total_not_ui = labor_force*unemp_rate - total_ui
gen employed = labor_force - total_ui - total_not_ui

foreach var of varlist total_not_ui employed total_ui init_claims {
	gen frac_`var' = `var'/population
}

foreach var of varlist *weeks_left* {
	gen frac_`var' = `var'/cps_count*frac_ui
	replace frac_`var' = 0 if frac_`var'==.
}

gen more_weeks = alt_totwks>l.alt_totwks & l.alt_totwks!=.
gen less_weeks = alt_totwks<l.alt_totwks & l.alt_totwks!=.
replace more_weeks=0 if l.more_weeks==1|l2.more_weeks==1

gen num_more_weeks = more_weeks*(alt_totwks - l.alt_totwks)

gen frac_near_exp = frac_weeks_left_0_9+frac_weeks_left_10_19
*** replace frac_near_exp = .0002125 if frac_near==0 //this is the min non-zero value
gen frac_med_exp = frac_weeks_left_20_29+frac_weeks_left_30_39
*** replace frac_med_exp = .0002992 if frac_med==0
gen frac_far_exp = frac_weeks_left_40_49+frac_weeks_left_50_59+frac_weeks_left_60_69+frac_weeks_left_70_79+frac_weeks_left_80_89
*** replace frac_far_exp = .0003054 if frac_far_exp==0

gen frac_ui_X_expansion = frac_ui*more_weeks
gen near_exp_X_expansion = frac_near_exp*more_weeks
gen med_exp_X_expansion = frac_med_exp*more_weeks
gen far_exp_X_expansion = frac_far_exp*more_weeks

/*
*** gen frac_near_exp = frac_weeks_left_0_9
*** replace frac_near_exp = .0002125 if frac_near==0 //this is the min non-zero value
*** gen frac_med_exp = frac_weeks_left_10_19+frac_weeks_left_20_29
*** replace frac_med_exp = .0002992 if frac_med==0
*** gen frac_far_exp = frac_weeks_left_40_49+frac_weeks_left_50_59+frac_weeks_left_60_69 + frac_weeks_left_30_39
*** replace frac_far_exp = .0003054 if frac_far_exp==0

*** gen frac_ui_X_expansion = frac_ui*more_weeks
*** gen near_exp_X_expansion = frac_near_exp*more_weeks
*** gen med_exp_X_expansion = frac_med_exp*more_weeks
*** gen far_exp_X_expansion = frac_far_exp*more_weeks
*/

*** gen num_frac_ui_X_expansion = frac_ui*num_more_weeks
*** gen num_near_exp_X_expansion = frac_near_exp*num_more_weeks

*** gen frac_init_X_expansion = frac_init_claims*num_more_weeks

gen dljobs_search = d.ljobs_search
qui tab year_month, gen(ym)
gen post_legislation = ui_expansion_ind+l.ui_expansion_ind
replace post_legislation = ui_expansion_ind if l.ui_expansion_ind==.
replace post_legislation = 1 if post_legislation==2

tab state, gen(ss)
tab year, gen(yy)
tab month, gen(mm)

label var post_legislation "Post Legislation"
label var more_weeks "Post Legislation"
label var frac_employed "Fraction Employed"
label var frac_total_ui "Fraction On UI"
label var frac_total_not_ui "Fraction Unemployed"
label var unemp_rate "Unemployment Rate"
label var num_more_weeks "Number New Weeks of Benefits"
label var frac_ui "Fraction on UI"
label var frac_ui_X_expansion "Frac on UI*Legislation"
label var near_exp_X_expansion "Frac $<$10 Weeks Left*Legislation"
label var frac_near_exp "Frac $<$10 Weeks Left"
label var frac_weeks_left_0 "Frac Under 10 Weeks Left"
label var frac_weeks_left_10 "Frac 10-19 Weeks Left"
label var frac_weeks_left_20 "Frac 20-29 Weeks Left"
label var frac_weeks_left_30 "Frac 30-39 Weeks Left"
label var frac_weeks_left_40 "Frac 40-49 Weeks Left"
label var frac_weeks_left_50 "Frac 50-59 Weeks Left"
label var frac_weeks_left_60 "Frac 60-69 Weeks Left"
label var frac_weeks_left_70 "Frac 70 or more Weeks Left"

label var far_exp_X_expansion "Frac 40$+$ Weeks Left*Legislation"
label var med_exp_X_expansion "Frac 10-40 Weeks Left*Legislation"
label var frac_med_exp "Frac 10-40 Weeks Left"
label var frac_far_exp "Frac 40$+$ Weeks Left"

gen l1_ui_expansion_ind = l1.ui_expansion_ind
gen l2_ui_expansion_ind = l2.ui_expansion_ind
gen l3_ui_expansion_ind = l3.ui_expansion_ind
gen l4_ui_expansion_ind = l4.ui_expansion_ind
gen l5_ui_expansion_ind = l5.ui_expansion_ind
gen l6_ui_expansion_ind = l6.ui_expansion_ind
gen l7_ui_expansion_ind = l7.ui_expansion_ind
gen l8_ui_expansion_ind = l8.ui_expansion_ind
gen f1_ui_expansion_ind = f1.ui_expansion_ind
gen f2_ui_expansion_ind = f2.ui_expansion_ind
gen f3_ui_expansion_ind = f3.ui_expansion_ind
gen f4_ui_expansion_ind = f4.ui_expansion_ind
gen f5_ui_expansion_ind = f5.ui_expansion_ind
gen f6_ui_expansion_ind = f6.ui_expansion_ind
gen f7_ui_expansion_ind = f7.ui_expansion_ind
gen f8_ui_expansion_ind = f8.ui_expansion_ind

*** Change so that only one lag can hold at a time
forvalues num = 8(-1)1{
    local this_num = `num' - 1
	forvalues num2 = 1(1)`this_num'{
        replace l`num'_ui_expansion_ind = 0 if l`num2'_ui_expansion_ind==1
    }
    replace l`num'_ui_expansion_ind = 0 if ui_expansion_ind==1
}

*** Same for leads
forvalues num = 8(-1)1{
    local this_num = `num' - 1
    forvalues num2 = 1(1)`this_num'{
        replace f`num'_ui_expansion_ind = 0 if f`num2'_ui_expansion_ind==1
    }
    replace f`num'_ui_expansion_ind = 0 if ui_expansion_ind==1
}


foreach var of varlist l*_ui_expansion_ind {
    *replace `var' = 0 if `var'==.
}
label var ui_expansion_ind "Period of legislation"
label var l1_ui_expansion_ind "Period of Legislation - Lag 1"
label var l2_ui_expansion_ind "Period of Legislation - Lag 2"
label var l3_ui_expansion_ind "Period of Legislation - Lag 3"
label var l4_ui_expansion_ind "Period of Legislation - Lag 4"
label var l5_ui_expansion_ind "Period of Legislation - Lag 5"
label var l6_ui_expansion_ind "Period of Legislation - Lag 6"
label var l7_ui_expansion_ind "Period of Legislation - Lag 7"
label var l8_ui_expansion_ind "Period of Legislation - Lag 8"
label var ui_expansion_ind "Period of legislation"
label var f1_ui_expansion_ind "Period of Legislation - Lead 1"
label var f2_ui_expansion_ind "Period of Legislation - Lead 2"
label var f3_ui_expansion_ind "Period of Legislation - Lead 3"
label var f4_ui_expansion_ind "Period of Legislation - Lead 4"
label var f5_ui_expansion_ind "Period of Legislation - Lead 5"
label var f6_ui_expansion_ind "Period of Legislation - Lead 6"
label var f7_ui_expansion_ind "Period of Legislation - Lead 7"
label var f8_ui_expansion_ind "Period of Legislation - Lead 8"

tab state, gen(statecode)
forvalues num = 1/51 {
    cap gen statedate`num' = statecode`num'*year_month
}

gen l1_unemp_rate = l.unemp_rate
gen f1_unemp_rate = f.unemp_rate

gen time_from_exp = 0 if ui_expansion_ind==1
replace time_from_exp=l.time_from_exp+1 if ui_expansion_ind==0
replace time_from_exp = 0 if time_from==.
gen time_until_exp = 0 if ui_expansion_ind==1
forvalues x=24(-1)1 {
	replace time_until_exp = `x' if f`x'.ui_expansion_ind==1
}
replace time_until = 0 if time_until==.

replace time_until = 12 if time_until>12
replace time_from = 12 if time_from>12
