*** This file compares the comscore data with Google search data.
clear all
cap use "~/Dropbox/Texas_Job_Search_New/restat_data/comScore_analysis/all2007_final.dta"

drop hoh* house* children racial workhour* durwork* count

** Drop guys that don't matter (just for speed)
drop if googlecount==0 & totaljobsearchtime==0

rename event_date date
nsplit date, digits(4 2 2)
rename date1 year
rename date2 month
rename date day
drop date

cap merge m:1 machine_id using "~/Dropbox/Texas_Job_Search_New/restat_data/comScore_analysis/idtostate.dta"
drop if _merge==2
drop _merge
drop if state=="DC"
drop if state=="PR"|state=="AS"|state=="NA"

collapse (sum) googlecount googlejobsearch totaljobsearchtime totalgooglejobsearchtime, by(state month)

rename state state_abrv
cap merge m:1 state_abrv using "~/Dropbox/Texas_Job_Search_New/restat_data/comScore_analysis/state_population"
drop if _merge==2
drop _merge
drop state_long

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

cd "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables/Tables"
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

