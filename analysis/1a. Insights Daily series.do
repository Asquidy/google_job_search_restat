clear all
set mem 1100m
set more off

global msas "600	612	618	623	625	626	627	633	634	635	636	641	651	657	661	662	692	709	749	765"
global months "1 4 7 10"
global years "2004 2005 2006 2007 2008 2009 2010 2011 2012"

**This is number of runs I've done
local max "3"

forvalues x = 1/`max' {
	cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Google Data\TexasDailyData_`x'" 

	foreach year of global years {
		foreach month of global months {
			foreach msa of global msas {
				clear all
				sleep 50
				cap insheet using "US-TX-`msa'-`year'-`month'-jobs.csv"
				if _rc==0 {
					gen search_msa = v1 in 2
					replace search_msa = search_msa[_n-1] if search_msa[_n-1]~=""

					gen msa = regexs(1) if regexm(search_msa, "(^.*) \(United States\);")
					gen date = regexs(0) if regexm(v1, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]")
					gen jobs_search = regexs(1) if regexm(v1, ",([0-9]*)") & date~=""
					destring jobs_search, replace
					drop if date==""
					drop v1 search_msa
					compress
					save  clean_tx_daily_`msa'_`year'_`month'_jobs, replace
				}
			}
		}
	}
	/*
	foreach year of global years {
		foreach month of global months {
			foreach msa of global msas {
				clear all
				sleep 50
				cap insheet using "US-TX-`msa'-`year'-`month'-jobs.csv"
				if _rc==0 {
					cap if regexm(v1, "quota") in 13 {
						cap save  QUOTA_HIT_`msa'_`year'_`month'_jobs, replace
					}
				}
			}
		}
	}
	clear all
	*/

	clear all

	foreach year of global years {
		foreach month of global months {
			foreach msa of global msas {
				cap append using clean_tx_daily_`msa'_`year'_`month'_jobs
			}
		}
	}
	replace jobs_search = . if jobs_search==0
	drop if jobs_search==.

	gen year = substr(date, 1, 4)
	gen month = substr(date, 6, 2)
	gen day = substr(date, 9, 2)
	destring year, replace
	destring month, replace
	destring day, replace

	drop if msa=="Shreveport"

	gen msa_code = 1
	replace msa_code = 2 if msa=="Amarillo"
	replace msa_code = 3 if msa=="Austin"
	replace msa = "Beaumont-Port Arthur" if msa=="Beaumont-Port Author"
	replace msa_code = 4 if msa == "Beaumont-Port Arthur"
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
	compress
	save all_tx_daily_`x', replace

	*clear all

	*forvalues x = 1/10 {
	*append using all_tx_daily_`x'
	*}

	collapse (mean) jobs_search msa_code, by(year month day msa)

	gen date = mdy(month, day, year)

	tsset msa_code date

	tsfill, full
	replace year = year(date)
	replace month = month(date)
	replace day = day(date)
	gen period = year+(month-1)/12 + (day-1)/365

	gsort msa_code -msa
	replace msa=msa[_n-1] if msa_==msa_[_n-1]
	sort msa date

	rename jobs_search jobs_search_`x'
	
	compress
	save temp_daily_search_data_`x', replace
}

clear all
use temp_daily_search_data_1

forvalues x = 2/`max' {
	merge 1:1 year month day msa using temp_daily_search_data_`x'
	drop _merge
}

egen jobs_final = rowmean(jobs_search_*)
keep msa year month day jobs_final date period msa_code

compress
save final_daily_search_data, replace
