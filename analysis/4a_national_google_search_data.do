*** Create Monthly State Level Google Search Series: Old Data Pull
*** Note, this is data from older version of the paper. The next file compares the new data pull with this one.
clear all
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/restat_data"
set mem 1100m
set more off

** Number of Independent Google Trends Queries:
local max "1"
local states "AL AR AZ CA CO CT DC DE FL GA HI IL IN KS KY LA MA MD MI MN MO MS NC NE NH NJ NM NV NY OH OK OR PA RI SC TN TX UT VA WA WI WV AK ME MT WY ND SD VT IA ID"

forvalues x = 1/`max' {
	cap cd "Google_Data/StateMonth_2004_2013_`x'"

	foreach state of local states {
		clear all
		sleep 2
		cap insheet using "`state'.csv"
		if _rc==0 {
			gen search_msa = v1 in 2
			replace search_msa = search_msa[_n-1] if search_msa[_n-1]~=""

			gen state_long = regexs(1) if regexm(search_msa, "(^.*) \(United States\);")
			gen state_abrv = "`state'"
			gen date = regexs(0) if regexm(v1, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]")
			gen jobs_search = regexs(1) if regexm(v1, ",([0-9]*)") & date~=""
			destring jobs_search, replace
			drop if date==""
			drop v1 search_msa
			
			compress
			save  clean_`state'_jobs, replace
		}

	}


	clear all

	foreach state of local states {
		cap append using clean_`state'_jobs
	}

	drop if jobs_search==.

	gen year = substr(date, 1, 4)
	gen month = substr(date, 6, 2)
	destring year, replace
	destring month, replace

	*** Take mean of job search across weeks in month
	collapse jobs_search, by(year month state_*)

    cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/restat_data"
	cap cd "Google_Data"
	compress
	save all_us_monthly_data_`x', replace
}



if `max'>1 {
	clear all
	use temp_daily_search_data_1

	forvalues x = 2/`max' {
		merge 1:1 year month state_abrv using all_us_monthly_data_`x'
		drop _merge
	}

	egen jobs_final = rowmean(jobs_search_*)
	keep state* year month jobs_final
}

compress
save final_monthly_search_data_2013, replace
