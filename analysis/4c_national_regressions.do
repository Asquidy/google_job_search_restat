*** File runs regressions for national results table.
clear all
set mem 1100m
set more off

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\Scott Baker\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "~/Dropbox/Texas_Job_Search_New/National_Analysis_Data"

local states "AL AR AZ CA CO CT DC DE FL GA HI IL IN KS KY LA MA MD MI MN MO MS NC NE NH NJ NM NV NY OH OK OR PA RI SC TN TX UT VA WA WI WV AK ME MT WY ND SD VT IA ID"

use final_merged_data
rename unemp_rate unemp_rate_old

cap merge 1:1 year month state using "/Users/afradkin/Dropbox/Texas_Job_Search_New/Other_Data/all_unemp_emp.dta"
cap merge 1:1 year month state using "C:\Users\Scott Baker\Dropbox\Texas Job Search - New\Other_Data/all_unemp_emp.dta"
keep if _merge==3 
drop _merge
drop if year<2005
drop if state=="LA" & year==2005

tsset gestcen year_month

gen ljobs_search = log(jobs_search)
egen max_pop = max(pop), by(state)
*** keep if max_pop > 2000000

*** Define post-expansion varible. Use only changes due to triggers and legislation (hence current policy)
order state year month alt_totwks
gen old_alt_totweeks = alt_totwks

gen ui_expansion_ind_nonsmooth = l.alt_totwks<alt_totwks & l.alt_totwks!=.

replace alt_totwks = max(alt_totwks, l.alt_totwks, l2.alt_totwks, l3.alt_totwks) 

*** if year==2010 & inlist(month, 6,7) & inlist(state, "AK", "VT")

gen ui_expansion_ind2 = l.alt_totwks<alt_totwks & l.alt_totwks!=.
gen ui_expansion_ind3 = (l.alt_totwks<(alt_totwks-7)) & l.alt_totwks!=.
gen ui_expansion_ind4 = (l.alt_totwks<(alt_totwks-10)) & l.alt_totwks!=.

gen post_legislation = ui_expansion_ind+l.ui_expansion_ind
replace post_legislation = ui_expansion_ind if l.ui_expansion_ind==.
replace post_legislation = 1 if post_legislation==2

gen post_legislation2 = ui_expansion_ind2 + l.ui_expansion_ind2
replace post_legislation2 = ui_expansion_ind2 if l.ui_expansion_ind2==.
replace post_legislation2 = 1 if post_legislation2==2

gen post_legislation3 = ui_expansion_ind3 + l.ui_expansion_ind3
replace post_legislation3 = ui_expansion_ind3 if l.ui_expansion_ind3==.
replace post_legislation3 = 1 if post_legislation3==2

gen post_legislation4 = ui_expansion_ind4 + l.ui_expansion_ind4
replace post_legislation4 = ui_expansion_ind4 if l.ui_expansion_ind4==.
replace post_legislation4 = 1 if post_legislation4==2

gen post_legislation_nonsmooth = ui_expansion_ind_nonsmooth + l.ui_expansion_ind_nonsmooth
replace post_legislation_nonsmooth = ui_expansion_ind_nonsmooth if l.ui_expansion_ind_nonsmooth==.
replace post_legislation_nonsmooth = 1 if post_legislation_nonsmooth==2


areg ljobs_search post_legislation i.year_month, ab(state) cluster(state)
areg ljobs_search post_legislation2 i.year_month, ab(state) cluster(state)
areg ljobs_search post_legislation3 i.year_month, ab(state) cluster(state)
*areg ljobs_search post_legislation4 unemp_rate i.year_month statedate*, ab(state) cluster(state)
areg ljobs_search alt_totwks i.year_month, ab(state) cluster(state)

replace unemp_rate = unemp_rate/100
gen total_ui = cont_claims + init_claims
gen frac_ui = total_ui/population
gen lpop = log(population)
gen total_not_ui = tot_lf*unemp_rate - total_ui
gen employed = tot_lf - total_ui - total_not_ui

foreach var of varlist total_not_ui employed total_ui init_claims {
	gen frac_`var' = `var'/population
}

gen frac_unemp = frac_total_ui + frac_total_not_ui

foreach var of varlist *weeks_left* {
	gen frac_`var' = `var'/cps_count*frac_ui
	replace frac_`var' = 0 if frac_`var'==.
}

gen frac_near_exp = frac_weeks_left_0_9+frac_weeks_left_10_19
*** replace frac_near_exp = .0002125 if frac_near==0 //this is the min non-zero value
gen frac_med_exp = frac_weeks_left_20_29+frac_weeks_left_30_39
*** replace frac_med_exp = .0002992 if frac_med==0
gen frac_far_exp = frac_weeks_left_40_49+frac_weeks_left_50_59+frac_weeks_left_60_69+frac_weeks_left_70_79+frac_weeks_left_80_89
*** replace frac_far_exp = .0003054 if frac_far_exp==0

gen dljobs_search = d.ljobs_search
qui tab year_month, gen(ym)
tab state, gen(ss)
tab year, gen(yy)
tab month, gen(mm)

label var post_legislation "Post Legislation"
label var frac_employed "Share Employed"
label var frac_total_ui "Share On UI"
label var frac_total_not_ui "Share Not on UI"
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
label var alt_totwks "Potential Benefit Duration"
label var frac_med_exp "Frac 10-40 Weeks Left"
label var frac_far_exp "Frac 40$+$ Weeks Left"

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

cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "~/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"

egen state_month_group = group(state month)
stop

*********************************************************************************************************
*****National Table - OLS and NLLS
eststo clear

eststo: qui areg ljobs_search post_legislation i.year_month, ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local smfe "No"

eststo: qui areg ljobs_search post_legislation i.year_month, ab(state_month_group) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local smfe "No"

eststo: qui areg ljobs_search post_legislation frac_total_ui frac_total_not_ui frac_employed frac_near_exp i.year_month statedate*, ab(state) cluster(state)
qui estadd local stfe "No"
qui estadd local myfe "Yes"
qui estadd local smfe "Yes"

eststo: qui areg ljobs_search post_legislation alt_totwks i.year_month, ab(state) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local smfe "No"

eststo: qui areg ljobs_search post_legislation totwks i.year_month, ab(state_month_group) cluster(state)
qui estadd local stfe "Yes"
qui estadd local myfe "Yes"
qui estadd local smfe "No"

eststo: qui areg ljobs_search post_legislation totwks frac_total_ui frac_total_not_ui frac_employed frac_near_exp i.year_month, ab(state) cluster(state)
qui estadd local stfe "No"
qui estadd local myfe "Yes"
qui estadd local smfe "No"

* ***Scale for reasonable coeffs
* foreach var of varlist frac* {
* 	replace `var' = `var'*population/2500
* }
* eststo: qui nl (ljobs_search = 1 + {xb:ss1-ss51 ym1-ym74 post_legislation} + log({xb: frac_total_ui frac_employed})), initial(xb_frac_total_ui .4 xb_frac_employed .4) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"
* qui estadd local spec "NLLS"

* eststo: qui nl (ljobs_search = 1 + {xb:ss1-ss51 ym1-ym74 post_legislation} + log({xb:frac_total_ui frac_total_not_ui frac_employed})), initial(xb_frac_total_ui .4 xb_frac_employed .4) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"
* qui estadd local spec "NLLS"

* foreach var of varlist frac* {
*     replace `var' = 2500*`var'/population
* }

*** Note: This needs to be manually edited afterwards!
cd "~/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"
esttab using "Tables/national_regs_new", tex se keep(post_legislation totwks frac_total_ui frac_total_not_ui frac_near_exp frac_employed) scalars("stfe State FE" "myfe Year-Month FE" "smfe State-Month FE" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{ Notes: Dependent variable is log(GJSI) at state-month level. Analysis spans all 50 states and Washington DC from 2005 - March 2011. ``Frac'' variables represent the fraction of the CPS participants in each category. Data taken from the CPS at a state-month level, imputing weeks left and UI status from the duration of unemployment. Post Legislation is an indicator for the month of and month following an extension. Also included are the fraction of the population who are unemployed but not on UI. Columns 1-4 are OLS while columns 5-6 are NLLS. Standard errors are clustered at state level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {")   obslast replace label gaps wrap

*** esttab using "Tables/national_regs_new", tex se keep(post_legislation totwks frac_total_ui frac_total_not_ui frac_near_exp frac_employed "xb_post_legislation: _cons" "xb_frac_total_ui: _cons" "xb_frac_total_not_ui: _cons" "xb_frac_total_ui: _cons" "xb_frac_near_exp: _cons" "xb_frac_employed: _cons") scalars("stfe State FE" "myfe Year-Month FE" "spec Specification" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{ Notes: Dependent variable is log(GJSI) at state-month level. Analysis spans all 50 states and Washington DC from 2005 - March 2011. ``Frac'' variables represent the fraction of the CPS participants in each category. Data taken from the CPS at a state-month level, imputing weeks left and UI status from the duration of unemployment. Post Legislation is an indicator for the month of and month following an extension. Also included are the fraction of the population who are unemployed but not on UI. Columns 1-4 are OLS while columns 5-6 are NLLS. Standard errors are clustered at state level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {")   obslast replace label gaps wrap

* ********************* Make graph of coefficients (Impulse response table) *********************
* eststo clear

* eststo: qui areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month, ab(state) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"
* qui estadd local strendfe "No"

* eststo: qui areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month unemp_rate frac_employed, ab(state) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"
* qui estadd local strendfe "No"

* eststo: qui areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month statedate1-statedate50, ab(state) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"
* qui estadd local strendfe "Yes"

* eststo: qui areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month unemp_rate frac_employed statedate1-statedate50, ab(state) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"
* qui estadd local strendfe "Yes"

* esttab using Tables/impulsereponsetable.tex, se title(Effects of UI Expansion Over Time \label{tab:impulsereponsetable}) keep(ui_expansion_ind l*_expansion_ind unemp_rate frac_employed) scalars("stfe State FE" "myfe Year and Month FE" "strendfe State Time Trend"  "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{Notes: Dependent variable is log(GJSI) at state-month level. Analysis spans all 50 states and Washington DC from 2005-2012. ``Frac Employed'' represents the fraction of the population who are employed, by the CPS definition. Post Legislation and it's lags are indicators for the month of a UI extension or expansion law (or lags of this variable). Standard errors are clustered at a state level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {")   obslast replace label gaps wrap



***Leads

* areg ljobs_search time_until ui_expansion_ind time_from unemp_rate frac_employed i.year_month statedate1-statedate50, ab(state) cluster(state)


* areg ljobs_search f2_ui_expansion_ind f1_ui_expansion_ind ui_expansion_ind l*_expansion_ind i.year_month unemp_rate frac_employed, ab(state) cluster(state)
* areg ljobs_search f2_ui_expansion_ind f1_ui_expansion_ind ui_expansion_ind l1_ui_expansion_ind - l5_ui_expansion_ind i.year_month unemp_rate frac_employed statedate1-statedate50, ab(state) cluster(state)
* areg ljobs_search f2_ui_expansion_ind f1_ui_expansion_ind ui_expansion_ind l1_ui_expansion_ind-l4_ui_expansion_ind i.year_month unemp_rate frac_employed, ab(state) cluster(state)
* areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month unemp_rate frac_employed, ab(state) cluster(state)
* areg ljobs_search ui_expansion_ind l1_ui_expansion_ind-l4_ui_expansion_ind f1_ui_expansion_ind-f4_ui_expansion_ind unemp_rate frac_employed i.year_month , ab(state) cluster(state)
* areg ljobs_search f1_ui_expansion_ind-f2_ui_expansion_ind ui_expansion_ind l1_ui_expansion_ind-l8_ui_expansion_ind  unemp_rate frac_employed i.year_month , ab(state) cluster(state)
* areg ljobs_search f1_ui_expansion_ind-f2_ui_expansion_ind ui_expansion_ind l1_ui_expansion_ind-l2_ui_expansion_ind  unemp_rate frac_employed i.year_month , ab(state) cluster(state)




* ************************************************************************************************
* ************************************************************************************************
* ***Combined Impulse Response graph with Texas
* eststo clear

* eststo: qui areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month, ab(state) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"

* eststo: qui areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month unemp_rate frac_employed, ab(state) cluster(state)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"

* use "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\texas_working_data_regressions.dta",clear

* use "~/Dropbox/Texas_Job_Search_New/Texas_UI_Data/texas_working_data_regressions.dta",clear
* label var ui_expansion_ind "Period of Legislation"
* label var l1_ui_expansion_ind "Period of Legislation - Lag 1"
* label var l2_ui_expansion_ind "Period of Legislation - Lag 2"
* label var l3_ui_expansion_ind "Period of Legislation - Lag 3"
* label var l4_ui_expansion_ind "Period of Legislation - Lag 4"
* label var l5_ui_expansion_ind "Period of Legislation - Lag 5"
* label var l6_ui_expansion_ind "Period of Legislation - Lag 6"
* label var l7_ui_expansion_ind "Period of Legislation - Lag 7"
* label var l8_ui_expansion_ind "Period of Legislation - Lag 8"
* label var frac_employed "Frac. Employed"

* eststo: qui areg ljob_search ui_expansion_ind l*_expansion_ind msas1-msas18, ab(year_month)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"

* eststo: qui areg ljob_search ui_expansion_ind l*_expansion_ind unemp_rate frac_employed msas1-msas18, ab(year_month) cluster(msa)
* qui estadd local stfe "Yes"
* qui estadd local myfe "Yes"

* esttab using "Tables/impulsereponsetable2.tex", se title(Effects of UI Expansion Over Time \label{tab:impulsereponsetable}) keep(ui_expansion_ind l*_expansion_ind unemp_rate frac_employed) scalars("stfe Location FE" "myfe Period FE"  "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{Notes: Dependent variable is log(GJSI) at state-month level in columns 1 and 2; DMA-week level in columns 3 and 4. Analysis spans all 50 states and Washington DC from 2005-2012 in columns 1 and 2 and all Texas DMAs from 2006-2011 in columns 3 and 4. ``Frac Employed'' represents the fraction of the population who are employed, by the CPS definition. Post Legislation and it's lags are indicators for the month of a UI extension or expansion law (or lags of this variable). Standard errors are clustered at a state level for columns 1 and 2 and at a DMA level in columns 3 and 4. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {")   obslast replace label gaps wrap

* ***********************************************************************************************************************************************
* ***********************************************************************************************************************************************
* areg ljobs_search ui_expansion_ind l*_expansion_ind i.year_month unemp_rate frac_employed, ab(state) cluster(state)

* matrix est = e(b)
* matrix var = e(V)
* gen variance = .
* gen estimate = .
* gen standerror=.
* gen low_conf = .
* gen high_conf = .
* forvalues y = 1/9 {
* 	replace variance = var[`y', `y'] in `y'
* 	replace estimate = est[1, `y'] in `y'
* }
* replace standerror = variance^.5
* replace low_conf = estimate-1.96*standerror
* replace high_conf = estimate+1.96*standerror

* gen months_from_expansion = .
* forvalues x=1/9 {
* 	replace months_from_expansion = (`x'-1) in `x'
* }

* label var estimate "Relative Job Search Intensity (\%)"
* label var months_from_expansion "Months Since UI Expansion"
* graph twoway (line estimate months_from_expansion) in 1/9, scheme(s2mono) legend(off) ytitle("Relative Job Search Intensity")
* graph twoway (line estimate months_from_expansion) (line low_conf months_from_expansion, clp(dash)) (line high_conf months_from_expansion, clp(dash)) in 1/9, scheme(s2mono) legend(off) ytitle("Relative Job Search Intensity")
* graph export Figures/months_from_expansion.png, width(1200) height(600) replace
