clear all
set more off
set mem 300m

local prefixes "_ tx_"
local term_sets "euc ui"

foreach pre of local prefixes {
	foreach term of local term_sets {
		forvalues x = 2008/2011 {
			forvalues y = 1/12 {
		
				insheet using data/`pre'`term'_`y'_`x'.csv
				
				drop v1 v5
				rename v2 day
				rename v3 month
				rename v4 year
				if "`pre'" == "tx_" {
					rename v6 num_tx_`term' 
				}
				if "`pre'" == "_" {
					rename v6 num_us_`term'
				}
				
				gen date = mdy(month, day, year)
				drop if date==.
				
				cap destring, replace
				
				compress
				if "`pre'" == "tx_" {
					save data/tx_`term'_`y'_`x', replace 
				}
				if "`pre'" == "_" {
					save data/us_`term'_`y'_`x', replace
				}
				clear all
			}
		}
	}
}

foreach term of local term_sets {
	forvalues x = 2008/2011 {
		forvalues y = 1/12 {
			append using data/tx_`term'_`y'_`x'
			append using data/us_`term'_`y'_`x'
		}
	}
}

collapse num_*, by(year month day date)

save all_news_search_data, replace
clear
