clear all
set mem 1100m
set more off

cap cd "C:\Users\ScottHome\Dropbox\Texas Job Search - New"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/"

use "Google_Data\final_daily_search_data.dta"
cap use "Google_Data/final_daily_search_data.dta"
sort msa date
tsset msa_code date

***Generate an overall texas series to match with non-msa people and make msa_code=0


***Fill in missing daily data with the weekly data
rename jobs_final job_search

replace job_search = l.job_search if job_search==.
replace job_search = f.job_search if job_search==.

/*
gen quarter = quarter(date)
egen season_msa = group(quarter year msa)
drop quarter
*/

***Merge with the number affected data
merge 1:1 msa_code date using "Texas_UI_Data\number_affected_data.dta"
drop _merge

*** Merge with unemp and labor force data by month/MSA
merge m:1 msa year month using "Other_Data/clean_tx_msa_unemp.dta"
drop if _merge==2
drop _merge
tsset msa_code date
foreach var of varlist employment labor_force unemp_rate {
	replace `var' = l.`var' if `var'==.
}

***Merge with pop data by year/MSA
merge m:1 msa year month using "Other_Data/tx_msa_pop.dta"
drop if _merge==2
drop _merge
tsset msa_code date
replace population = l.population if population==.

***Add holidays
gen new_year = (month==1&day==1)
gen christmas = ((month==12)&(day==24|day==25))
gen indep_day = (month==7 & day==4)
gen thanksgiving = (month==11 & ((year==2005 & (day==24|day==25))|(year==2006 & (day==24|day==23))|(year==2007 & (day==23|day==22))|(year==2008 & (day==27|day==28))|(year==2009 & (day==26|day==27))|(year==2010 & (day==26|day==25))|(year==2011 & (day==24|day==25))|(year==2012 & (day==22|day==23))))
gen labor_day = (month==9 & ((year==2005 & (day==5))|(year==2006 & (day==4))|(year==2007 & (day==3))|(year==2008 & (day==1))|(year==2009 & (day==7))|(year==2010 & (day==6))|(year==2011 & (day==5))|(year==2012 & (day==3))))
gen memorial_day = (month==5 & ((year==2005 & (day==30))|(year==2006 & (day==29))|(year==2007 & (day==28))|(year==2008 & (day==26))|(year==2009 & (day==25))|(year==2010 & (day==31))|(year==2011 & (day==30))|(year==2012 & (day==28))))
gen easter = (year==2005 & month==3 & day==27)|(year==2006 & month==4 & day==16)|(year==2007 & month==4 & day==8)|(year==2008 & month==3 & day==23)|(year==2009 & month==4 & day==12)|(year==2010 & month==4 & day==4)|(year==2011 & month==4 & day==24)|(year==2012 & month==4 & day==8)
gen holiday = new_year + christmas + easter + memorial_day + indep_day + labor_day + thanksgiving

***Merge with data on the extension dates
merge m:1 date using Texas_UI_Data\TX_Weeks_Left_Data.dta
drop _merge

gen eb13 = eb==13
gen eb20 = eb==20
drop eb
gen tier1_13 = tier1==13
gen tier1_20 = tier1==20
drop tier1

foreach var of varlist tier* eb* {
	replace `var' = 1 if `var'>0
}

**Here replace affected with affected per labor force
rename affected_indicator number_on_ui
foreach var of varlist num_new* affected* {
	replace `var' = 0 if `var'==.
}
foreach var of varlist affected* {
	replace `var' = `var'/(population)
}

**Make one and two week indicators for after the extensions
tsset msa_code date
foreach var of varlist tier* eb* {
	gen `var'_1week = `var'==1 & l.`var'==0
	replace `var'_1week = l.`var'_1week if l.`var'_1week==1 & l7.`var'_1week==0
	gen `var'_2week = `var'==1 & l.`var'==0
	replace `var'_2week = l.`var'_2week if l.`var'_2week==1 & l14.`var'_2week==0
	gen `var'_4week = `var'==1 & l.`var'==0
	replace `var'_4week = l.`var'_4week if l.`var'_4week==1 & l28.`var'_4week==0
}
foreach var of varlist num_new_weeks* affected_* {
	gen `var'_1week = `var' if `var'!=0 & l.`var'==0
	replace `var'_1week = 0 if `var'_1week==.
	replace `var'_1week = l.`var'_1week if l.`var'_1week!=0 & l7.`var'_1week==0
	gen `var'_2week = `var' if `var'!=0 & l.`var'==0
	replace `var'_2week = 0 if `var'_2week==.
	replace `var'_2week = l.`var'_2week if l.`var'_2week!=0 & l14.`var'_2week==0
	gen `var'_4week = `var' if `var'!=0 & l.`var'==0
	replace `var'_4week = 0 if `var'_4week==.
	replace `var'_4week = l.`var'_4week if l.`var'_4week!=0 & l28.`var'_4week==0
}

egen all_extensions_1week = rowmax(tier1_13_1week tier1_20_1week tier2_1week tier3_1week tier4_1week eb13_1week eb20_1week)
egen all_extensions_2week = rowmax(tier1_13_2week tier1_20_2week tier2_2week tier3_2week tier4_2week eb13_2week eb20_2week)
egen all_extensions_4week = rowmax(tier1_13_4week tier1_20_4week tier2_4week tier3_4week tier4_4week eb13_4week eb20_4week)

***Generate various indicators
gen day_of_week = dow(date)
egen year_month = group(year month)
tab msa, gen(msas)
tab day_of_week, gen(dow)
tab year, gen(yy)
tab month, gen(mm)

**generate season-msa fixed effects to combat google data problems
gen quarter = quarter(date)
egen season_msa = group(quarter year msa)
drop quarter

**generate week effects
gen week = week(date)
gen week_of_day = wofd(date)

**Generate a few other variables
cap gen ljob_search = log(job_search)
gen d_ljob_search = ljob_search-l7.ljob_search
gen ext_X_unemp = all_extensions_2week*unemp_rate
gen unemployment=labor_force - employment
gen llabor_force=log(labor_force)
gen lunemployment=log(unemployment)
gen lpopulation = log(population)

stop

***Main Regressions
areg ljob_search all_extensions_1week mm*, ab(season_msa)
areg ljob_search all_extensions_1week holiday dow* mm*, ab(season_msa)
areg ljob_search all_extensions_2week holiday dow* mm*, ab(season_msa)

areg ljob_search all_extensions_1week affected_4weeks_1week holiday dow* mm*, ab(season_msa)
areg ljob_search all_extensions_1week num_new_weeks_1week holiday dow* mm*, ab(season_msa)

areg ljob_search all_extensions_2week affected_4weeks_2week holiday dow* mm*, ab(season_msa)
areg ljob_search all_extensions_2week num_new_weeks_2week holiday dow* mm*, ab(season_msa)

areg ljob_search all_extensions_2week affected_4weeks_2week holiday dow* mm* [aweight = labor_force], ab(season_msa) 
areg ljob_search all_extensions_2week num_new_weeks_2week holiday dow* mm* [aweight = labor_force], ab(season_msa) 

areg ljob_search all_extensions_2week affected_4weeks_2week unemp_rate holiday dow* mm* [aweight = labor_force], ab(season_msa) cluster(season_msa)
areg ljob_search all_extensions_2week affected_12weeks_2week unemp_rate holiday dow* mm* [aweight = labor_force], ab(season_msa) cluster(season_msa)

areg ljob_search llabor_force lunemployment holiday dow* mm* [aweight = labor_force], ab(season_msa) cluster(season_msa)


areg ljob_search all_extensions_2week *weeks_2week unemp_rate holiday dow* mm* [aweight = labor_force], ab(season_msa) cluster(season_msa)

***Individual Extension Regressions
areg ljob_search tier2_2week tier3_2week tier4_2week tier1_13_2week tier1_20_2week eb13_2week eb20_2week unemp_rate holiday dow* mm*, ab(season_msa)

*** Andrey's Attempt To Piece Together Series ***
/*
drop if year<2006

egen countmiss=nmiss(job_search), by(year)
egen countlmiss=nmiss(ljob_search), by(year)
gen miss=(job_search==.)
egen meanmiss=mean(miss), by(msa year)
drop if meanmiss>.25

areg ljob_search new_year-easter, ab(season_msa)
predict normalizedsearch, resid
gen wofd=wofd(date)
egen jobsearch=median(normalizedsearch), by(wofd msa_code)
egen weekmsatag=tag(wofd msa) if jobsearch~=.
line jobsearch wofd if weekmsatag==1 & msa_code==11
gen quarter = quarter(date)
sort msa quarter date
gen prevlast = 0

preserve
keep if weekmsatag==1
replace prevlast = jobsearch if msa_code==msa_code[_n-1] & season_msa!=season_msa[_n-1]
gen toadd=jobsearch-prevlast
egen maxtoadd=max(toadd), by(season_msa)
gen jobsearch2 = jobsearch
replace jobsearch2 = jobsearch+maxtoadd if toadd~=0 
line jobsearch2 wofd if weekmsatag==1 & msa_code==11
*/

