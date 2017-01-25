*** Merge Files Necessary for Non-Linear Least Squares Analysis of Texas Data ***
clear all
set mem 1100m
set more off

cap cd "~/Dropbox/Texas_Job_Search_New/restat_data/"
cap use "Google_Data/final_weekly_search_data.dta"

sort msa date
tsset msa_code date, daily delta(7)

**Change search data to replace 0's
rename jobs job_search
replace job_search = l.job_search if job_search==0

**Change to same date timing as UI data
drop year month day
replace date = date + 6 
** this changes so make the search week equal to the friday of the UI ben
gen year = year(date)
gen month = month(date)
gen day = day(date)

***Generate an overall texas series to match with non-msa people and make msa_code=0

***Merge with the number affected data
merge 1:1 msa_code date using "Texas_UI_Data\number_affected_data.dta"
drop _merge

***Merge with unemp and labor force data by month/MSA
merge m:1 msa year month using "Other_Data/clean_tx_msa_unemp.dta"
drop if _merge==2
drop _merge
tsset msa_code date, daily delta(7)
foreach var of varlist employment labor_force unemp_rate {
	replace `var' = l.`var' if `var'==.
}

***Merge with num people by weeks_left/date/msa naive
merge 1:1 msa_code date using "Texas_UI_Data\soph_weeks_left_data.dta"
drop if _merge==2
drop _merge

foreach num of numlist 0(1)87{
	rename count`num' num_on_ui`num'
}
***Merge with num people by weeks_left/date/msa naive
** merge 1:1 msa_code date using "Texas_UI_Data\naive_weeks_left_data.dta"
** drop if _merge==2
** drop _merge

*** Merge w/ weeks on data
merge 1:1 msa_code date using "Texas_UI_Data\number_weeks_on_data.dta"
drop if _merge==2
drop _merge

***Merge with pop data by year/MSA
merge m:1 msa year month using "Other_Data/tx_msa_pop.dta"
drop if _merge==2
drop _merge
tsset msa_code date, daily delta(7)
replace population = l.population if population==.

***Add holidays
*** Do this by expanding out to daily and then collapsing back to weekly
tsset msa_code date
tsfill, full

replace year = year(date)
replace day = day(date)
replace month = month(date)
gen new_year = (month==1&day==1)
gen christmas = ((month==12)&(day==24|day==25))
gen indep_day = (month==7 & day==4)
gen thanksgiving = (month==11 & ((year==2005 & (day==24|day==25))|(year==2006 & (day==24|day==23))|(year==2007 & (day==23|day==22))|(year==2008 & (day==27|day==28))|(year==2009 & (day==26|day==27))|(year==2010 & (day==26|day==25))|(year==2011 & (day==24|day==25))|(year==2012 & (day==22|day==23))))
gen labor_day = (month==9 & ((year==2005 & (day==5))|(year==2006 & (day==4))|(year==2007 & (day==3))|(year==2008 & (day==1))|(year==2009 & (day==7))|(year==2010 & (day==6))|(year==2011 & (day==5))|(year==2012 & (day==3))))
gen memorial_day = (month==5 & ((year==2005 & (day==30))|(year==2006 & (day==29))|(year==2007 & (day==28))|(year==2008 & (day==26))|(year==2009 & (day==25))|(year==2010 & (day==31))|(year==2011 & (day==30))|(year==2012 & (day==28))))
gen easter = (year==2005 & month==3 & day==27)|(year==2006 & month==4 & day==16)|(year==2007 & month==4 & day==8)|(year==2008 & month==3 & day==23)|(year==2009 & month==4 & day==12)|(year==2010 & month==4 & day==4)|(year==2011 & month==4 & day==24)|(year==2012 & month==4 & day==8)
gen holiday = new_year + christmas + easter + memorial_day + indep_day + labor_day + thanksgiving

gen new_week = msa[_n-1]!=""
gen week = 1
replace week = week[_n-1]+new_week if msa_code==msa_code[_n-1]

foreach var of varlist new_year-holiday {
	egen w_`var' = max(`var'), by(msa week)
	drop `var'
	rename w_`var' `var'
}
drop if msa==""
drop week new_week
gen weekyear=wofd(date)
tsset msa_code date, daily delta(7)

gen eb13 = eb==13
gen eb20 = eb==20
drop eb
gen tier1_13 = tier1==13
gen tier1_20 = tier1==20
drop tier1

foreach var of varlist tier* eb* {
	replace `var' = 1 if `var'>0
}

foreach var of varlist num_weeks_on* num_on_ui* {
	replace `var' = 0 if `var'==.
}
foreach var of varlist num_weeks_on* num_on_ui* {
	replace `var' = `var'/(population)
}

***** Old code for post-expansion indicators *********
******************************************************
** Make one and two week indicators for after the extensions
* tsset msa_code date, daily delta(7)
* foreach var of varlist tier* eb*{
* 	cap gen `var'_1week = `var'==1 & l.`var'==0
* 	replace `var'_1week = l.`var'_1week if l.`var'_1week==1 & l1.`var'_1week==0
* 	cap gen `var'_2week = `var'==1 & l.`var'==0
* 	replace `var'_2week = l.`var'_2week if l.`var'_2week==1 & l2.`var'_2week==0
* 	cap gen `var'_4week = `var'==1 & l.`var'==0
* 	replace `var'_4week = l.`var'_4week if l.`var'_4week==1 & l4.`var'_4week==0
* }

* foreach var of varlist *_last {
* 	tab `var'
* 	foreach num of numlist 1 2 4{
* 		cap drop `var'_`num'week
* 		cap gen `var'_`num'week = 0
* 		di `num'*7
* 		replace `var'_`num'week = 1 if date >= `var' & date < (`var' + `num'*7)
* 	}	
* }

* foreach var of varlist  num_weeks_on* num_on_ui* {
* 	gen `var'_1week = `var' if `var'!=0 & l.`var'==0
* 	replace `var'_1week = 0 if `var'_1week==.
* 	replace `var'_1week = l.`var'_1week if l.`var'_1week!=0 & l1.`var'_1week==0
* 	gen `var'_2week = `var' if `var'!=0 & l.`var'==0
* 	replace `var'_2week = 0 if `var'_2week==.
* 	replace `var'_2week = l.`var'_2week if l.`var'_2week!=0 & l2.`var'_2week==0
* 	gen `var'_4week = `var' if `var'!=0 & l.`var'==0
* 	replace `var'_4week = 0 if `var'_4week==.
* 	replace `var'_4week = l.`var'_4week if l.`var'_4week!=0 & l4.`var'_4week==0
* }

* egen all_extensions_1week = rowmax(tier1_13_1week tier1_20_1week tier2_1week tier3_1week tier4_1week eb13_1week eb20_1week)
* egen all_extensions_2week = rowmax(tier1_13_2week tier1_20_2week tier2_2week tier3_2week tier4_2week eb13_2week eb20_2week)
* egen all_extensions_4week = rowmax(tier1_13_4week tier1_20_4week tier2_4week tier3_4week tier4_4week eb13_4week eb20_4week)

* egen all_extensions_and_exp_1week = rowmax(tier1_13_1week tier1_20_1week tier2_1week tier3_1week tier4_1week eb13_1week eb20_1week hole*last*_1week)

* egen all_extensions_and_exp_2week = rowmax(tier1_13_2week tier1_20_2week tier2_2week tier3_2week tier4_2week eb13_2week eb20_2week hole*last*_2week)

* egen all_extensions_and_exp_4week = rowmax(tier1_13_4week tier1_20_4week tier2_4week tier3_4week tier4_4week eb13_4week eb20_4week hole*last*_4week)
******************************************************
***Combine num_on_ui to the same level as num affected

foreach var of varlist num_on_ui0-num_on_ui87 {
	replace `var' = 0 if `var'==.
}


egen num_weeks_on_from0 = rowtotal(num_weeks_on1-num_weeks_on4 num_weeks_on0)
egen num_weeks_on_from5 = rowtotal(num_weeks_on5-num_weeks_on9)
egen num_weeks_on_from10 = rowtotal(num_weeks_on10-num_weeks_on14)
egen num_weeks_on_from15 = rowtotal(num_weeks_on15-num_weeks_on19)
egen num_weeks_on_from20 = rowtotal(num_weeks_on20-num_weeks_on24)
egen num_weeks_on_from25 =rowtotal(num_weeks_on26 - num_weeks_on29)


egen num_on_ui_2weeks = rowtotal(num_on_ui0-num_on_ui1)
egen num_on_ui_5weeks = rowtotal(num_on_ui2-num_on_ui4)
egen num_on_ui_8weeks = rowtotal(num_on_ui5-num_on_ui7)
egen num_on_ui_11weeks = rowtotal(num_on_ui8-num_on_ui10)
egen num_on_ui_14weeks = rowtotal(num_on_ui11-num_on_ui13)
egen num_on_ui_17weeks = rowtotal(num_on_ui14-num_on_ui16)
egen num_on_ui_20weeks = rowtotal(num_on_ui17-num_on_ui19)
egen num_on_ui_high_weeks = rowtotal(num_on_ui20-num_on_ui87)
*
egen num_ui_0weeks = rowtotal(num_on_ui0)
egen num_ui_4weeks = rowtotal(num_on_ui1-num_on_ui4)
egen num_ui_9weeks = rowtotal(num_on_ui5-num_on_ui9)
egen num_ui_14weeks = rowtotal(num_on_ui10-num_on_ui14)
egen num_ui_19weeks = rowtotal(num_on_ui15-num_on_ui19)
egen num_ui_24weeks = rowtotal(num_on_ui20-num_on_ui24)
egen num_ui_29weeks = rowtotal(num_on_ui25-num_on_ui29)
egen num_ui_34weeks = rowtotal(num_on_ui30-num_on_ui34)
egen num_ui_39weeks = rowtotal(num_on_ui35-num_on_ui39)
egen num_ui_44weeks = rowtotal(num_on_ui40-num_on_ui44)
egen num_ui_49weeks = rowtotal(num_on_ui45-num_on_ui49)
egen num_ui_54weeks = rowtotal(num_on_ui50-num_on_ui54)
egen num_ui_59weeks = rowtotal(num_on_ui55-num_on_ui59)
egen num_ui_64weeks = rowtotal(num_on_ui60-num_on_ui64)
egen num_ui_69weeks = rowtotal(num_on_ui65-num_on_ui69)
egen num_ui_74weeks = rowtotal(num_on_ui70-num_on_ui74)
egen num_ui_75weeks = rowtotal(num_on_ui75-num_on_ui87)
*
egen num_ui_0_10_weeks = rowtotal(num_on_ui0-num_on_ui10)
egen num_ui_10_20_weeks = rowtotal(num_on_ui11-num_on_ui20)
egen num_ui_20_30_weeks = rowtotal(num_on_ui21-num_on_ui30)
egen num_ui_30_40_weeks = rowtotal(num_on_ui31-num_on_ui40)
egen num_ui_40_50_weeks = rowtotal(num_on_ui41-num_on_ui50)
egen num_ui_50_60_weeks = rowtotal(num_on_ui51-num_on_ui60)
egen num_ui_60_70_weeks = rowtotal(num_on_ui61-num_on_ui70)
egen num_ui_70_80_weeks = rowtotal(num_on_ui71-num_on_ui80)
egen num_ui_80_90_weeks = rowtotal(num_on_ui81-num_on_ui87)


*** Generate dates and indicators
egen year_month = group(year month)
tab msa, gen(msas)
tab year, gen(yy)
tab month, gen(mm)
gen week = week(date)

**Generate a few other variables
gen ljob_search = log(job_search)
gen unemployment=labor_force - employment
gen llabor_force=log(labor_force)
gen lunemployment=log(unemployment)
gen lpopulation = log(population)
gen lunemp_rate = log(unemp_rate)
egen fractotal_on_ui = rowtotal(num_on_ui_2weeks-num_on_ui_high_weeks)
gen total_on_ui = fractotal_on_ui*population

*** Check here that everything adds up! 
egen check_sum1 = rowtotal(num_weeks_on1-num_weeks_on120 num_weeks_on0)
replace check_sum1 = check_sum1 * population

egen check_sum2 = rowtotal(num_on_ui0-num_on_ui87)
replace check_sum2 = check_sum2 * population

gen total_on_ui_labor = fractotal_on_ui*population/labor_force
egen msa_year = group(msa year)

*** Keep only periods where we have UI periods
* drop if msa_code==13 | msa_code == 19

*** Get Rid of Dates Before and After UI Sample
drop if date<td(1oct2006)
drop if date>td(31dec2011)

*** Compute Logged versions of appropriate variables.
drop unemployed
gen unemployed = unemp_rate*labor_force/100
gen lunemployed = log(unemployed)
gen llaborforce = log(labor_force)
gen ltotal_on_ui = log(total_on_ui)
tab msa, gen(mms)
gen not_on_ui = unemployed - total_on_ui
drop employed
gen employed = labor_force - unemployed
gen lemployed = log(employed)
tab week, gen(wfe)
tab year, gen(yfe)
tab year_month, gen(ymfe)
label var lunemployed "Log Unemployed"
label var ltotal_on_ui "Log Total On UI"
label var ljob_search "Log Job Search"
egen yearmsa = group(year msa_code)

*** Msa trends
forvalues num = 1/19{
	cap gen msasdate`num'=msas`num'*date
}

gen monthyear=mofd(date)

save Texas_UI_Data/soph_readyforweeklyregs.dta, replace

