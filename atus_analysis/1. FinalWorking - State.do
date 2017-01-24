clear all
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\ATUS"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\ATUS"
set mem 1000m
set more off

use AllCPSATUS.dta

*drop  gemetsta-pecohab
drop if teage>65
drop if teage<20

nsplit tucaseid, digits(4 2 8)

sort tucaseid
drop if tucaseid==tucaseid[_n-1]

/*
kruger mueller use:

sum  t050403 t050404 t050405 t050481 t050499  t180589 if teage>19 & teage<66 & tucaseid1<2008

telfs is labor force status
*/

gen AllJobSearchTimeWTravel = t050403+ t050404 +t050405+ t050481+ t050499+  t180589 
gen AllJobSearchTime = t050403+ t050404 +t050405+ t050481+ t050499
gen JobSearchWTravelIndicator = 1 if AllJobSearchTimeWTravel>0
replace JobSearchWTravelIndicator =0 if JobSearchWTravelIndicator ==.
gen JobSearchIndicator = 1 if AllJobSearchTime>0
replace JobSearchIndicator =0 if JobSearchIndicator ==.

order tucaseid1 tucaseid2 gestcen AllJobSearchTimeWTravel AllJobSearchTime JobSearchIndicator JobSearchWTravelIndicator 

rename tucaseid1 Year
rename tucaseid2 Month

drop gestcen
sort gestfips

merge gestfips using GestfipsGestCen
drop _merge

sort gestcen
merge gestcen using gestcenstate
drop _merge

rename Year year
rename Month month

gen count=1

sort year month gestcen

tab year, gen(yy)
tab month, gen(mm)
gen period = year+month/12
tab period, gen(ym)
tab tudiaryday, gen(dw)
tab state, gen(ss)

gen weekend = 0
replace weekend=1 if tudiaryday==1|tudiaryday==7

label variable trholiday "Holiday"
label variable weekend "Weekend"
label variable dw1 "Sunday"
label variable dw2 "Monday"
label variable dw3 "Tuesday"
label variable dw4 "Wednesday"
label variable dw5 "Thursday"
label variable dw6 "Friday"
label variable dw7 "Saturday"


compress
save ATUS_state, replace

/*
*********************************************************
Check relative time spent on search between unemp/emp out of kru/muel's sample (in their sample it was 50/1)
gen unemp = 0
replace unemp = 1 if telfs==3|telfs==4
gen emp = 0
replace emp = 1 if telfs==1|telfs==2
gen nilf =0
replace nilf = 1 if telfs==5

sum AllJobSearchTimeWTravel if emp==1&year==2009
sum AllJobSearchTimeWTravel if unemp==1&year==2009

*********************************************************
*/

collapse  JobSearchIndicator JobSearchWTravelIndicator  t050403- t180589 (sum) count (sum) AllJobSearchTime AllJobSearchTimeWTravel, by(year state month)

rename year Year
rename month Month

sort Year Month state

*********************************************************************************************
sort Year Month state
merge Year Month state using statejobssearch
drop _merge

sort Year Month state
merge Year Month state using statelocalsearch
drop _merge

sort Year Month state
merge Year Month state using stateweathersearch
drop _merge

sort Year Month state
merge Year Month state using stateweathersearch
drop _merge

*********************************************************************************************
***Merge in new indicators

sort Year Month state
cap merge 1:1 Year Month state using "C:\Users\scottb131\Dropbox\Texas Job Search - New\Google_Data\all_aux_term_monthly_new.dta"
cap merge 1:1 Year Month state using "C:\Users\Scott Baker\Dropbox\Texas Job Search - New\Google_Data\all_aux_term_monthly_new.dta"
drop _merge

*********************************************************************************************

rename allsearch jobs
rename localsearch local
rename weathersearch weather
rename Year year
rename Month month

egen baseline = mean(AllJobSearchTime ) if [_n]==1
replace baseline =baseline[_n-1] if baseline[_n-1]~=.

gen diffjobsearchwtravel = log(AllJobSearchTimeWTravel)-log(baseline)
gen diffjobsearch = log(AllJobSearchTime)-log(baseline)

drop if year==2003

tab year, gen(yy)
tab month, gen(mm)

gen ljobs=log(jobs)
gen lweather = log(weather)
gen llocal = log(local)
gen lunemp_emp = log(searchUnemp_Emp )
gen lunemp = log(searchUnemployment )
gen lbenefit = log(searchBenefits )

gen lsearchtime = log(AllJobSearchTime)
gen lsearchtimewtravel = log(AllJobSearchTimeWTravel)
cap gen ljobs = log(jobs)
tab state, gen(ss)

sort state year month

reg jobs AllJobSearchTime mm* if year<2010
reg jobs AllJobSearchTime mm* if year<2009
reg jobs AllJobSearchTime mm* if year<2008
reg jobs AllJobSearchTime mm* if year<2007
reg jobs AllJobSearchTime mm* if year<2006

gen period = year+month/12
replace period=period*12

encode state, gen(state_code)

tsset state_code period

***Relationship between time and search index:

foreach var of varlist yy* {
	gen ljobs`var' = ljobs*`var'
}

label var AllJobSearchTime "Job Search Time"
label var JobSearchIndicator "Job Search Indic."
label var jobs "Google Job Search Index"
label var local "Google Job Category Search"
label var ljobs "log(Google Job Search Index)"
label var llocal "Google Job Category Search"
label var lweather "log(Google Weather Search Index)"
label var lunemp "log(Google Unemp Rate Index)"
label var lbenefit "log(Google Unemp Benefit Index)"
label var lunemp_emp "log(Google Unemp/Emp Index)"


sort state
merge state using StateGestcenConvert
drop _merge
sort StateFIPS year month
merge StateFIPS year month using StateUnemployment
drop _merge

sort State year month

drop if State==""
drop if year==2010
replace AllJobSearchTime=0 if AllJobSearchTime==.

gen AllJobSearchTime_percap = AllJobSearchTime/count
drop if count==.

*sum AllJobSearchTime_percap
*replace AllJobSearchTime_percap = AllJobSearchTime_percap/r(sd)
*sum JobSearchIndicator
*replace JobSearchIndicator = JobSearchIndicator/r(sd)

/*
**********************************************************************************************************************************************
*********GRAPHS
**********************************************************************************************************************************************

graph twoway (lfitci ljobs JobSearchIndicator)   (scatter ljobs JobSearchIndicator), ytitle("Google Job Search") xtitle("ATUS Job Search Indicator") legend(ring(0) pos(5) order(2 "linear fit" 1 "95% CI"))

graph twoway (lfitci ljobs  AllJobSearchTime)   (scatter ljobs  AllJobSearchTime),  ytitle("Google Job Search") xtitle("ATUS Job Search Time") legend(ring(0) pos(5) order(2 "linear fit" 1 "95% CI"))

graph twoway (lfitci weather JobSearchIndicator) (scatter weather JobSearchIndicator), ytitle("Google Weather Search") xtitle("ATUS Job Search Indicator") legend(ring(0) pos(5) order(2 "linear fit" 1 "95% CI"))

**********************************************************************************************************************************************
*********TABLES
**********************************************************************************************************************************************
*****OLD TABLE
reg AllJobSearchTime_percap ljobs, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label replace addtext(Year FE, NO, Month FE, NO) ctitle("Search Time") nocons nor2

reg JobSearchIndicator ljobs, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label  addtext(Year FE, NO, Month FE, NO) ctitle("Search Indicator") nocons nor2

reg AllJobSearchTime_percap ljobs mm* yy*, cluster(state) nocons
outreg2 using Tables\ATUSCorr,  tex(landscape pr frag) keep(ljobs) label  addtext(Year FE, YES, Month FE, YES) ctitle("Search Time") nocons nor2

reg JobSearchIndicator ljobs mm* yy*, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label  addtext(Year FE, YES, Month FE, YES) ctitle("Search Indicator") nocons nor2

reg AllJobSearchTime_percap lweather mm* yy*, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(lweather) label addtext(Year FE, YES, Month FE, YES) ctitle("Search Time") nocons nor2

***********************************************************************************************************************************************
*****NEW TABLE
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"

gen any_search_time = AllJobSearchTime!=0
gen any_search_time_X_ljobs = any_search_time*ljobs

egen min_lunemp = min(lunemp)
replace lunemp = min_lunemp if lunemp==.

reg AllJobSearchTime_percap ljobs, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label replace addtext(State FE, NO, Month FE, NO) ctitle("Search Time") nocons

reg AllJobSearchTime_percap ljobs if AllJobSearchTime>0, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label addtext(State FE, NO, Month FE, NO) ctitle("Search Time-NonZero") nocons

*probit any_search_time ljobs  mm* yy*, vce(cluster state)
*outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label addtext(State FE, NO, Month FE, NO) ctitle("Search Indic") nocons

*reg any_search_time ljobs, cluster(state) nocons
*outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label addtext(State FE, NO, Month FE, NO) ctitle("Search Indic") nocons

reg AllJobSearchTime_percap ljobs ss* mm*, cluster(state) nocons
outreg2 using Tables\ATUSCorr,  tex(landscape pr frag) keep(ljobs) label addtext(State FE, YES, Month FE, YES) ctitle("Search Time") nocons

reg AllJobSearchTime_percap ljobs ss* mm* if AllJobSearchTime>0, cluster(state) nocons
outreg2 using Tables\ATUSCorr,  tex(landscape pr frag) keep(ljobs) label addtext(State FE, YES, Month FE, YES) ctitle("Search Time-NonZero") nocons

*reg any_search_time ljobs ss* mm*, cluster(state) nocons
*outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs) label addtext(State FE, YES, Month FE, YES) ctitle("Search Indic") nocons

***SRB: New columns for R&R
reg AllJobSearchTime_percap ljobs lweather ss* mm*, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs lweather) label addtext(State FE, YES, Month FE, YES) ctitle("Search Time") nocons

reg AllJobSearchTime_percap ljobs lunemp_emp lunemp ss* mm*, cluster(state) nocons
outreg2 using Tables\ATUSCorr, tex(landscape pr frag) keep(ljobs lunemp lunemp_emp) label addtext(State FE, YES, Month FE, YES) ctitle("Search Time") nocons


