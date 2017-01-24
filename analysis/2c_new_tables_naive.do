cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/"
clear all
*** Taken from 2b
cap use "Texas_UI_Data/naive_readyforweeklyregs.dta"
set more off
cap gen monthyear=mofd(date)
merge m:1 monthyear using "Other_Data\south_vacancies.dta"
drop if _merge==2
drop _merge 
cap gen lvacancies = log(vacancies)
cap gen ltightness = log(vacancies/unemployed)

foreach var of varlist num_on_ui* {
	replace `var' = `var'*(population)
}

*drop if msa_code == 13
cap tab msa, gen(mms)
cap gen scunemployed = unemployed/1000
cap gen sclabor_force = labor_force/1000
cap gen not_on_ui = unemployed - total_on_ui
cap gen lnot_on_ui=log(not_on_ui)
cap gen extensions_unemp = all_extensions_4week * scunemployed

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
label var extensions_unemp "Expansion * Num. Unemployed"

*** Scale To Make Reasonable Coefs ***
cap gen scnot_on_ui = not_on_ui/1000
cap gen sctotal_on_ui = total_on_ui/1000
cap gen scemployed = employed/1000
cap tab weekyear, gen(wyfe)

*** Check here that everything adds up! 
cap egen check_sum1 = rowtotal(num_weeks_on1-num_weeks_on120 num_weeks_on0)
cap replace check_sum1 = check_sum1*population 

cap egen check_sum2 = rowtotal(num_on_ui0-num_on_ui87)
cap replace check_sum2 = check_sum2 

sum total_on_ui check_sum1 check_sum2

foreach var of varlist num_ui_0_10 - num_ui_80_90{
	replace `var' = `var'*population/1000
}

cap egen greater_than_30 = rowtotal(num_ui_30_40 - num_ui_80_90)
cap egen weekson7 = rowtotal(num_weeks_on1 - num_weeks_on7 num_weeks_on0)
replace weekson7 = population * weekson7
cap egen weeksleft5 = rowtotal(num_on_ui0 - num_on_ui5)
cap gen weeksonrest = total_on_ui - weekson7 - weekson14 - weekson21 - weeksleft5
foreach var of varlist weekson* weeksleft*{
	replace `var' = `var'/1000
}

tsset msa_code date, daily delta(7)

gen altweeksonleft5=(l4.weeksleft5+l3.weeksleft5+l2.weeksleft5)/3
gen indaltweeksonleft5=all_extensions_4week*altweeksonleft5
gen dum2011 = year==2011

compress
cap save "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions_naive.dta", replace
cap save "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions_naive.dta", replace
cap save "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions_naive.dta", replace

stop

******************************************************************
    ******************* Table 6 - Week Composition - Naive *********************
clear all
cap use "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions_naive.dta", replace
cap use "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions_naive.dta", replace
cap use "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions_naive.dta", replace
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"

eststo clear

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas17 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_scemployed .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62 all_extensions_4week} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_sctotal_on_ui .4 xb_scnot_on_ui .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62 all_extensions_4week} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"


esttab using Tables/nllsregs_naive.tex, se title(Effect of UI Status and Composition on Job Search (NLLS) - Current Law Beliefs \label{tab:naiveregs}) keep("xb_sctotal_on_ui: _cons" "xb_scnot_on_ui: _cons" "xb_scemployed: _cons" "xb_all_extensions_4week: _cons" "xb_greater_than_30:_cons" "xb_num_ui_0_10_weeks:_cons" "xb_num_ui_10_20_weeks:_cons" "xb_num_ui_20_30_weeks:_cons") coeflabels(xb_sctotal_on_ui:_cons "Number on UI" xb_scnot_on_ui:_cons "Not on UI" xb_scemployed:_cons "Number Employed" xb_all_extensions_4week:_cons "Post Legislation" xb_greater_than_30:_cons "Over 30 Weeks Left" xb_num_ui_0_10_weeks:_cons "0-10 Weeks Left" xb_num_ui_10_20_weeks:_cons "10-20 Weeks Left" xb_num_ui_20_30_weeks:_cons "20-30 Weeks Left" ) scalars( "ratu UI Recipients/Employed" "ratemp UI Recipients/Non-UI Unemployed" "hline \hline \vspace{-2mm}" "msafe DMA FE and Trend" "myfe Year-Month FE" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \begin{minipage} [t] {\columnwidth} Notes: Dependent variable is log(GJSI) at DMA-week level. Analysis spans all Texas DMAs from 2006-2011. Number on UI, Not on UI, and Number Employed are the total number of individuals in each category. Post Legislation is the week of and three weeks following legislation. Unemployed/Employed gives the relative levels of search activity across types. Standard Errors Clustered at DMA level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01 \end{minipage} {") obslast replace label gaps
