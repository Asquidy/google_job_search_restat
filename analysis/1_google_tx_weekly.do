clear all
set mem 1100m
set more off
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Google_Data\TexasWeeklyData"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\Google_Data\TexasWeeklyData"
cap cd "~/Dropbox/Texas_Job_Search_New/restat_data/Google_Data/TexasWeeklyData"

global msas "600	612	618	623	625	626	627	633	634	635	636	641	651	657	661	662	692	709	749	765"

foreach msa of global msas {
	forvalues x = 1/1 {

		clear all
		insheet using "US-TX-`msa'-`x'.csv"

		gen search_msa = v1 in 2
		replace search_msa = search_msa[_n-1] if search_msa[_n-1]~=""

		gen msa = regexs(1) if regexm(search_msa, "(^.*) \(United States\);")
		gen date = regexs(0) if regexm(v1, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]")
		gen jobs_search = regexs(1) if regexm(v1, ",([0-9]*)") & date~=""
		destring jobs_search, replace
		drop if date==""
		drop v1 search_msa
		compress
		save  clean_tx_weekly_`y'_`msa'_`x', replace
	}
}
*
clear all

foreach msa of global msas {
	forvalues x = 1/1 {
		append using clean_tx_weekly_`y'_`msa'_`x'
	}
}
*
replace jobs_search = . if jobs_search==0

sort msa date
egen min_job_search = min(jobs), by(msa)
replace jobs = min_job if jobs==. & (jobs[_n-1]!=.|jobs[_n-2]!=.) & (jobs[_n+1]!=.|jobs[_n+2]!=.) & msa==msa[_n-1] & msa==msa[_n+1]
replace jobs = min_job if jobs==. & (jobs[_n-1]!=.|jobs[_n-2]!=.) & (jobs[_n+1]!=.|jobs[_n+2]!=.) & msa==msa[_n-1] & msa==msa[_n+1]

gen year = substr(date, 1, 4)
gen month = substr(date, 6, 2)
gen day = substr(date, 9, 2)
destring year, replace
destring month, replace
destring day, replace
drop date
gen date = mdy(month, day, year)

drop if msa=="Shreveport"

gen msa_code = 1
replace msa_code = 2 if msa=="Amarillo"
replace msa_code = 3 if msa=="Austin"
replace msa_code = 4 if msa=="Beaumont-Port Author"
replace msa = "Beaumont-Port Arthur" if msa=="Beaumont-Port Author"
replace msa_code = 5 if msa=="Corpus Christi"
replace msa_code = 6 if msa=="Dallas-Fort Worth"
replace msa_code = 7 if msa=="El Paso"
replace msa_code = 8 if msa=="Harlingen"
replace msa_code = 9 if msa=="Houston"
replace msa_code = 10 if msa=="Laredo"
replace msa_code = 11 if msa=="Lubbock"
replace msa_code = 12 if msa=="Odessa-Midland"
replace msa_code = 13 if msa=="San Angelo"
replace msa_code = 14 if msa=="San Antonio"
replace msa_code = 15 if msa=="Sherman"
replace msa_code = 16 if msa=="Tyler-Longview"
replace msa_code = 17 if msa=="Victoria"
replace msa_code = 18 if msa=="Waco-Temple-Bryan"
replace msa_code = 19 if msa=="Wichita Falls"

cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Google Data"

sort msa year month day
label var jobs_search "Google 'Jobs' Search"

cd ..

save final_weekly_search_data, replace

