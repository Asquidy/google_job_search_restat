*** Estimate Non-linear Least Squares Regression of Job Search on Composition of Unemployed
*** (in terms of weeks of UI remaining)
clear all
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New"
cap cd "C:\Users\Scott Baker\Dropbox\Texas Job Search - New"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/restat_data"

*** Taken from 2_prep_weekly_data_curlaw.do
cap use "Texas_UI_Data/soph_readyforweeklyregs.dta"
set more off
drop tier2 - min_eb_20

*** Merge w/ weeks left ***
cap merge m:1 date using "Texas_UI_Data/TX_Weeks_Left_Data_Alt"

egen totwks = rowtotal(tier1_alt - eb_alt)
replace totwks = totwks + 26

*** Visually inspect weeks left for TX
*** scatter totwks date if msa_code==1

foreach var of varlist num_on_ui* {
	replace `var' = `var'*(population)
}

drop mms*
cap gen scunemployed = unemployed/500
cap gen sclabor_force = labor_force/500
cap gen not_on_ui = unemployed - total_on_ui
cap gen lnot_on_ui=log(not_on_ui)
drop employed
gen employed = labor_force - unemployed

cap gen lemployed = log(employed)
cap tab week, gen(wfe)
cap tab year, gen(yfe)
cap tab month, gen(mfe)
cap tab year_month, gen(ymfe)

label var lunemployed "Log Unemployed"
label var ltotal_on_ui "Log Total On UI"
label var ljob_search "Job Search"
label var all_extensions_4week "4 Weeks After Ext."
cap egen yearmsa = group(year msa_code)

*** Scale To Make Reasonable Coefs ***
cap gen scnot_on_ui = not_on_ui/500
cap gen sctotal_on_ui = total_on_ui/500
cap gen scemployed = employed/500

*** Check here that everything adds up! 
cap egen check_sum1 = rowtotal(num_weeks_on1-num_weeks_on120)
cap replace check_sum1 = check_sum1*population 

cap egen check_sum2 = rowtotal(num_on_ui0-num_on_ui87)
cap replace check_sum2 = check_sum2 

sum total_on_ui check_sum1 check_sum2

foreach var of varlist num_ui_0_10 - num_ui_80_90 {
	replace `var' = `var'*population/500
}

egen num_on_five_weeks = rowtotal(num_weeks_on1 - num_weeks_on5)
replace num_on_five_weeks = num_on_five_weeks*population/500

egen greater_than_30 = rowtotal(num_ui_30_40 - num_ui_80_90)

tsset msa_code date, daily delta(7)

******************************************************************
** Google Issued a Correction. We're creating a dummy for it and interactions
gen dum2011 = (year==2011)
egen msa_dum2011 = group(msa_code dum2011)

*** Scale to population
foreach var of varlist num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 num_on_five_weeks {
	gen frac_`var' = `var'*1000/population
}
foreach var of varlist employed not_on_ui total_on_ui {
	gen frac_`var' = `var'/population
}

gen frac_not_in_lab_force = 1 - frac_employed - frac_total_on_ui - frac_not_on_ui

**Quadratic trend
foreach var of varlist msasdate1-msasdate19 {
	gen `var'_2 = `var'^2
}

drop msasdate*_2
compress
cap save "~/Dropbox/Texas_Job_Search_New/restat_data/Texas_UI_Data/working_data_regressions_and.dta", replace

******************************************************************
    ******************* Table 4 NLLS *********************
clear all
use "~/Dropbox/Texas_Job_Search_New/restat_data/Texas_UI_Data/working_data_regressions_and.dta"
cd "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables/"

eststo clear
eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_sctotal_on_ui .4 xb_scnot_on_ui .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local mayfe "No"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local mayfe "No"
qui estadd local myfe "Yes"

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed num_on_five_weeks})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local mayfe "No"
qui estadd local myfe "Yes"

esttab using Tables/nllsregs_current_law.tex, se title(Effect of UI Status and Composition on Job Search (NLLS)) keep("xb_sctotal_on_ui:_cons" "xb_scnot_on_ui:_cons" "xb_scemployed:_cons" "xb_greater_than_30:_cons" "xb_num_ui_0_10_weeks:_cons" "xb_num_ui_10_20_weeks:_cons" "xb_num_ui_20_30_weeks:_cons" "xb_num_on_five_weeks:_cons") coeflabels(xb_sctotal_on_ui:_cons "Number on UI" xb_scnot_on_ui:_cons "Not on UI" xb_scemployed:_cons "Number Employed" xb_greater_than_30:_cons "Over 30 Weeks Left" xb_num_ui_0_10_weeks:_cons "0-10 Weeks Left" xb_num_ui_10_20_weeks:_cons "10-20 Weeks Left" xb_num_ui_20_30_weeks:_cons "20-30 Weeks Left" xb_num_on_five_weeks:_cons "$<$ 6 Weeks On") scalars( "ratu UI Recipients/Employed" "ratemp UI Recipients/Non-UI Unemployed" "hline \hline \vspace{-2mm}" "msafe DMA FE and Trend" "myfe Year-Month FE") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{Notes: Dependent variable is log(GJSI) at DMA-week level. Analysis spans all Texas DMAs from 2006-2011. Number on UI, Not on UI, and Number Employed are the total number of individuals in each category. Unemployed/Employed gives the relative levels of search activity across types. Standard Errors Clustered at DMA level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {") obslast replace label gaps
