*** Generate Figures Plotting Google News Related to UI Policy ***
clear all
set more off
cd "~/Dropbox/Texas_Job_Search_New/restat_data/Google_Data"
use all_news_search_data


***Make national set of legislation dates
gen national_expansion = .
replace national_expansion=1 if year==2008 & month==6 & day==30
replace national_expansion=1 if year==2008 & month==11 & day==21
replace national_expansion=1 if year==2009 & month==11 & day==6

gen texas_expansion = .
replace texas_expansion=1 if year==2008 & month==6 & day==30
replace texas_expansion=1 if year==2009 & month==4 & day==17
replace texas_expansion=1 if year==2009 & month==8 & day==3
replace texas_expansion=1 if year==2009 & month==11 & day==6
replace texas_expansion=1 if year==2009 & month==12 & day==9
replace texas_expansion=1 if year==2011 & month==12 & day==14

*************

foreach var of varlist national_ texas_ {
	gen t_`var' = .
	forvalues x = 0/15 {
		replace t_`var' = `x' if `var'[_n-`x']==1
		replace t_`var' = -`x' if `var'[_n+`x']==1
	}
}

egen tx_euc_articles = sum(num_tx_euc), by(t_texas_)
egen tx_ui_articles = sum(num_tx_ui), by(t_texas_)
egen national_euc_articles = sum(num_us_euc), by(t_national_)

drop if t_national==. | t_texas_==.

collapse tx_euc tx_ui national_euc, by(t_texas_expansion)

rename t_texas_ period
gen period_bin = -2 if period>-13 & period<-7
replace period_bin = -1 if period>=-7 & period<-2
replace period_bin = 0 if period>=-2 & period<3
replace period_bin = 1 if period>=3 & period<8
replace period_bin = 2 if period>=8 & period<13

egen tx_euc_bin = sum(tx_euc_articles), by(period_bin)
egen tx_ui_bin = sum(tx_ui_articles), by(period_bin)
egen national_euc_bin = sum(national_euc_art), by(period_bin)

* twoway (bar tx_euc_articles period)
* twoway (bar tx_ui_articles period)

* twoway (bar tx_euc_bin period_bin)
* twoway (bar tx_ui_bin period_bin)


cap cd  "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables"
label var national_euc_bin "Number of Articles About EUC and Extended Benefits"
label var national_euc_art "Number of Articles About EUC and Extended Benefits"
label var period_bin "Number of Days Surrounding New Legislation"
label var period "Number of Days Surrounding New Legislation"

label define periods -2 "-12 to -8 days" -1 "-7 to -3 days" 0 "-2 to 2 days" 1 "3 to 8 days" 2 "8 to 12 days"
label values period_bin  periods


twoway (bar national_euc_bin period_bin), xlabel(-2 -1 0 1 2,valuelabel)
graph export national_euc_bin.png, width(1200) height(600) replace

twoway (bar national_euc_art period), xlabel(-15(5)15)
graph export national_euc.png, width(1200) height(600) replace
