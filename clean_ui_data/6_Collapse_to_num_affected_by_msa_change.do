clear all
set more off
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"

use user_weeks_left_data
drop if county_fips>900
/*** Just make single measure by week/msa of number of people with each number of weeks left
preserve
gen num_on_ui = 1
collapse (sum) num_on_ui, by(total_weeks_left date zip)

merge m:1 zip using msa_zip_convert
drop if _merge==2
drop _merge zip

replace total_weeks_left = 0 if total_weeks_left<0 & total_weeks_left>-3
collapse (sum) num_on_ui, by(total_weeks_left date msa)
drop if total_weeks_left <0 | total_weeks>99

reshape wide num_on_ui, i(msa date) j(total_weeks)

drop if msa==12|msa==19
egen msa_code2 = group(msa_code)
replace msa_code2 = 0 if msa_code2==.
drop msa_code
rename msa msa_code
compress
save num_on_ui_by_weeks_left, replace
restore
***/

**Add in UI law data
merge m:1 date using only_law_change_indicators_actual.dta
drop if _merge==2
drop _merge
drop law
sort id date

**generate the last total weeks left and last_date we observed for each user at each point
gen last_obs_weeks_left = total_weeks_left[_n-1] if id==id[_n-1]
gen last_date = date[_n-1] if id==id[_n-1]

**This keeps week before, week of and 2 weeks after (for those guys who were off and then came back on in the next weeks
keep if law_change==1|(law_change[_n+1]==1 & id==id[_n+1])|l1law_change==1|l2law_change==1

compress
save temp_num_affected, replace

**Drop guys who entered after the law change but are on regular or who are on EUC but have had big gaps since last UI (these guys are just new UI recips, not re-entrants) (run as many times as there are lags+1)
forvalues x = 1/3 {
	drop if (law_change==1|l1law_change==1|l2law_change==1)  & (id!=id[_n-1]|(id==id[_n-1] & date>date[_n-1]+30)) & (tier_==2|(tier_==5 & total_weeks_left[_n-1]>1)|(tier_==5 & date[_n-1]<date-182))
}
**Generate indicator for week before law change
gen f1law_change = 1 if law_change==. & l1law_change==. & l2law_change==.

gen affected_indicator = law_change==1|(l1law_change==1 & date[_n-1]!=date-7)|(l2law_change==1 & date[_n-1]!=date-7 & date[_n-1]!=date-14)

**Drop extraneous weeks after law change
drop if f1law_change!=1 & affected_indicator!=1

***Create 'old weeks left variable' to let us filter on people affected
sort id date
gen old_weeks_left = total_weeks_left[_n-1] if id==id[_n-1] & date<=date[_n-1]+30
replace old_weeks_left = 0 if id!=id[_n-1]|date>date[_n-1]+30
keep if affected_indicator==1

***Generate the number of affected people and the number of new weeks they got
/*
forvalues x=1/12 {
	gen affected_`x'weeks = 1 if old_weeks_left<`x'
	gen num_new_weeks_`x' = total_weeks_left-old_weeks_left+1 if old_weeks_left<`x'
	replace num_new_weeks_`x' =0 if num_new_weeks_`x'<0
}
*/

local old = -2
forvalues x=2(3)20 {
	
	gen affected_`x'weeks = 1 if old_weeks_left<`x' & old_weeks_left>=`old'
	gen num_new_weeks_`x' = total_weeks_left-old_weeks_left+1 if old_weeks_left<`x' & old_weeks_left>=`old'
	replace num_new_weeks_`x' =0 if num_new_weeks_`x'<0
	local old = `x'
}

gen affected_high_weeks = 1 if old_weeks_left>=`old'
gen num_new_weeks_high = total_weeks_left-old_weeks_left+1 if old_weeks_left>=`old'
replace num_new_weeks_high =0 if num_new_weeks_high<0

merge m:1 zip using DMA_zip_crosswalk_small
drop if _merge==2
drop _merge county_fips county

**Change dates of latecomers such that they apply to law_change dates
replace date = date-7 if l1law_change==1
replace date = date-14 if l2law_change==1

***Get number of affected and average number of new weeks by msa-extension
collapse (sum) affected_* (mean) num_new_weeks*, by(dma_code msa_code date)

sort dma date
compress
save number_affected_data, replace

merge m:1 date using only_law_change_indicators_actual.dta
drop if _merge==2
sort dma date
order law
