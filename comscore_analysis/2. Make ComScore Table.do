
clear all
cap use "C:\Users\srb834\Dropbox\Texas Job Search - New\texas job search - old\Google Trends\ComScore\all2007_final.dta"
cap use "C:\Users\scottb131\Dropbox\Texas Job Search - New\texas job search - old\Google Trends\ComScore\all2007_final.dta"

drop hoh* house* children racial workhour* durwork* count


**Drop guys that don't matter (just for speed)
drop if googlecount==0 & totaljobsearchtime==0

rename event_date date
nsplit date, digits(4 2 2)
rename date1 year
rename date2 month
rename date day
drop date

cap merge m:1 machine_id using "C:\Users\srb834\Dropbox\Texas Job Search - New\texas job search - old\Google Trends\ComScore\idtostate.dta"
cap merge m:1 machine_id using "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas Job Search - Old\Google Trends\ComScore\idtostate.dta"
drop if _merge==2
drop _merge
drop if state=="DC"
drop if state=="PR"|state=="AS"|state=="NA"

collapse (sum) googlecount googlejobsearch totaljobsearchtime totalgooglejobsearchtime, by(state month)

rename state state_abrv
cap merge m:1 state_abrv using "C:\Users\srb834\Dropbox\Texas Job Search - New\texas job search - old\Google Trends\ComScore\state_population"
cap merge m:1 state_abrv using "C:\Users\scottb131\Dropbox\Texas Job Search - New\texas job search - old\Google Trends\ComScore\state_population"
drop if _merge==2
drop _merge
drop state_long

*drop if state_abrv=="NA"
*drop if googlecount<10000
replace totaljobsearchtime = floor(totaljobsearchtime/2) if state_abrv=="AR" & (month==10|month==11)
tab month, gen(mm)

gen google_index = (googlejobsearch+1)/googlecount
gen lgoogle_index = log(google_index)

gen job_search_per_cap = totaljobsearchtime/population
gen google_job_search_per_cap = totalgooglejobsearchtime/population
gen lgoogle_job_search_per_cap = log(google_job_search_per_cap)
gen ljob_search_per_cap = log(job_search_per_cap)


foreach var of varlist googlecount googlejobsearch totaljobsearchtime totalgooglejobsearchtime {
	gen l`var' = log(`var'+1)
}


STOP STOP STOP

cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"

label var google_index "Synthetic GJSI"
label var lgoogle_index "Log(Synthetic GJSI)"

reg job_search_per_cap google_index
outreg2 using GoogleComScore, tex(landscape pr frag) keep(google_index) label addtext(State FE, NO, Month FE, NO) ctitle("Job Search Time Per Cap") replace nocons

reg ljob_search_per_cap lgoogle_index
outreg2 using GoogleComScore, tex(landscape pr frag) keep(lgoogle_index) label addtext(State FE, NO, Month FE, NO) ctitle("Log(Job Search Time Per Cap)") nocons

reg ljob_search_per_cap lgoogle_index if population>1000000
outreg2 using GoogleComScore, tex(landscape pr frag) keep(lgoogle_index) label addtext(State FE, NO, Month FE, NO) ctitle("Log(Job Search Time Per Cap) - High Pop") nocons

areg ljob_search_per_cap lgoogle_index mm*, ab(state)
outreg2 using GoogleComScore, tex(landscape pr frag) keep(lgoogle_index) label addtext(State FE, YES, Month FE, YES) ctitle("Log(Job Search Time Per Cap)") nocons



/*OLD STUFF
set matsize 1000
set more off
cap use "C:\Users\Andrey\Documents\My Dropbox\Google Trends\Master Data\comscorestateday.dta", clear
cap use "C:\Users\sbaker2\Dropbox\Google Trends\Master Data\comscorestateday.dta", clear
cap use "C:\Users\srb834\Dropbox\Texas Job Search - New\texas job search - old\Google Trends\Master Data\comscorestateday.dta", clear

drop  workhourjobsearch_7_1 workhourjobsearch_9_5 workhourjobsearch_10_4 durworkhourjobsearch_7_1 durworkhourjobsearch_9_5 durworkhourjobsearch_10_4 jobsearcher
cap gen ratio=googlejobsearch/googlecount
label variable googlejobsearch `"# Google Job Searches"'
egen nosearchsum=sum(totaljobsearchtime) if totaljobsearchtime<1
egen searchsum=sum(totaljobsearchtime) if totaljobsearchtime>1
cap gen week=wofd(date)
cap recode date, as(string)
cap replace date=date(date, "YMD")

**** generate demographic interactions ****
cap tab hoh_most_education, gen(educdum)
cap tab household_income, gen(incomdum)


cap xi: i.state*googlejobsearch
cap areg totaljobsearchtime googlejobsearch _IstaX*, ab(state)
cap testparm _IstaXgoo*
cap estimates store m1state
cap areg totaljobsearchtime googlejobsearch, ab(state)
cap estimates store nointerstate
cap lrtest m1state nointerstate

drop ssfe*
gen lgooglejobsearch = log(googlejobsearch)
gen ltotaljobsearchtime = log(totaljobsearchtime)
gen ltotalgooglejobsearchtime = log(totalgooglejobsearchtime)
stop
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"
reg totaljobsearchtime lgooglejobsearch
outreg2 using Tables\indivgoogtotot, title(Correlation of Google Search to Online Job Search Time) tex(landscape pr frag) keep(googlejobsearch) label replace addtext(Zip_Code FE, NO, Date FE, NO) ctitle("Total Job Search Time") 
reg totaljobsearchtime lgooglejobsearch ss*
outreg2 using Tables\indivgoogtotot, title(Correlation of Google Search to Online Job Search Time) tex(landscape pr frag) keep(googlejobsearch) label addtext(Zip_Code FE, YES, Date FE, NO) ctitle("Total Job Search Time") 
reg totaljobsearchtime lgooglejobsearch dd*
outreg2 using Tables\indivgoogtotot, title(Correlation of Google Search to Online Job Search Time) tex(landscape pr frag) keep(googlejobsearch) label addtext(Zip_Code FE, NO, Date FE, YES) ctitle("Total Job Search Time")
reg totaljobsearchtime lgooglejobsearch ss* dd*
outreg2 using Tables\indivgoogtotot, title(Correlation of Google Search to Online Job Search Time) tex(landscape pr frag) keep(googlejobsearch) label addtext(Zip_Code FE, NO, Date FE, YES) ctitle("Total Job Search Time")


*********************************************************************/

