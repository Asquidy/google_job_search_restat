*** This File Counts The Number Of People "Affected" by Each Policy ***
clear all
set mem 8000m
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/"

*** Taken from 2b
set more off
forvalues x=1/10 {
	use "Texas_UI_Data/user_weeks_left_roth_data.dta"

	*****TESTING CUT
	*** keep if id<31000000
	
	global y = `x'

	if $y==1 {
		global id_cut_low = 0
		global id_cut_high = 38100000
	}
	if $y==2 {
		global id_cut_low = 38100000
		global id_cut_high = 54000000
	}
	if $y==3 {
		global id_cut_low = 54000000
		global id_cut_high = 75000000
	}
	if $y==4 {
		global id_cut_low = 75000000
		global id_cut_high = 88000000
	}
	if $y==5 {
		global id_cut_low = 88000000
		global id_cut_high = 100000000
	}
	if $y==6 {
		global id_cut_low = 100000000
		global id_cut_high = 110000000
	}
	if $y==7 {
		global id_cut_low = 110000000
		global id_cut_high = 115000000
	}
	if $y==8 {
		global id_cut_low = 115000000
		global id_cut_high = 120000000
	}
	if $y==9 {
		global id_cut_low = 120000000
		global id_cut_high = 125000000
	}
	if $y==10 {
		global id_cut_low = 125000000
		global id_cut_high = 1000000000
	}
	
	keep if id>=$id_cut_low & id<$id_cut_high

*** keep if id<38100000

*** Create an indicator variable if an individual came back onto UI after a policy change ***


	tsset id date, daily delta(7)
	drop naive_total_weeks_left - tier4_weeks_left eb_weeks_left
	drop soph_expiration_date naive_expiration_date earned_inc_amt actual_ui_payment weekly_ben_amt total_ben_amt
	drop retropayment num_retro retroweeknum weekson weeksinspell reg_weekly_amount
	compress
	cap merge m:1 date using "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta"
	cap merge m:1 date using "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta"
	cap merge m:1 date using "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta"
	drop if _merge==2
	drop _merge 
	drop hole7_last
	drop hole8_last

	*** Create an indicator for whether it was the week of the change ***

	*** For Expansions and Expansions
	tsset id date, daily delta(7)
	foreach var of varlist min_* *_last {
		tab `var'
		foreach num of numlist 1 2 4 {
			cap drop `var'_`num'week
			cap gen `var'_`num'week = 0
			di `num'*7
			replace `var'_`num'week = 1 if date >= `var' & date < (`var' + `num'*7)
		}	
	}

	*** For Each Announcement Calculate ***
	egen any_1week = rowmax(*_1week)

	*** Not UI -> UI ***
	gen change_ui_nonui = 0
	replace change_ui_nonui = 1 if spellnum==spellnum[_n-1]&id==id[_n-1]&date[_n-1]<(date-14)&tier_code==5&any_1week==1


	*** < 10 -> < 20 
	gen change_0to20 = 0
	replace change_0to20 = 1 if spellnum==spellnum[_n-1]&id==id[_n-1]&soph_total_weeks_left>10&soph_total_weeks_left<=20&soph_total_weeks_left[_n-1]<=10&tier_code==5&any_1week==1

	*** < 10 -> < 30
	gen change_0to30 = 0
	replace change_0to30 = 1 if spellnum==spellnum[_n-1]&id==id[_n-1]&soph_total_weeks_left>20&soph_total_weeks_left<=30&soph_total_weeks_left[_n-1]<=10&tier_code==5&any_1week==1

	*** < 10 -> > 30
	gen change_0togr = 0
	replace change_0togr = 1 if spellnum==spellnum[_n-1]&id==id[_n-1]&soph_total_weeks_left>30&soph_total_weeks_left[_n-1]<=10&tier_code==5&any_1week==1

	*** 10-20 -> < 30
	gen change_10to30 = 0
	replace change_10to30 = 1 if spellnum==spellnum[_n-1] & id==id[_n-1] & soph_total_weeks_left>20 & soph_total_weeks_left<=30 & soph_total_weeks_left[_n-1]<=20 & soph_total_weeks_left>10 & tier_code==5 & any_1week==1

	*** 10-20 -> > 30
	gen change_10togr = 0
	replace change_10togr = 1 if spellnum==spellnum[_n-1] & id==id[_n-1] & soph_total_weeks_left>30 & soph_total_weeks_left[_n-1]<=20 & soph_total_weeks_left[_n-1]>10 & tier_code==5 & any_1week==1

	*** 20-30 -> > 30
	gen change_20togr = 0
	replace change_20togr = 1 if spellnum==spellnum[_n-1] & id==id[_n-1] & soph_total_weeks_left>30 & soph_total_weeks_left[_n-1]<=30 & soph_total_weeks_left > 20 & tier_code==5 & any_1week==1

	foreach var2 of varlist *_1week {
		foreach change2 of varlist change_* {
			tab `change2' if `var2'==1
		}
	}
	cap drop announce_name
	gen announce_name = "none" 
	local i = 1
	foreach var of varlist min_tier1_13_1week min_tier1_20_1week min_tier2_1week min_tier3_1week min_tier4_1week min_eb_13_1week min_eb_20_1week *_last_1week {
		replace announce_name = "`var'" if `var'==1
	}

	drop if announce_name=="none"
		*** Calculate Total Amounts 
	gen wl010 = (soph_total_weeks_left>=0 & soph_total_weeks_left<=10)
	gen wl1020 = (soph_total_weeks_left>10 & soph_total_weeks_left<=20)
	gen wl2030 = (soph_total_weeks_left>20 & soph_total_weeks_left<= 30)
	gen gr30 = (soph_total_weeks_left>30) 

	collapse (count) id (sum)  change_ui_nonui - change_20togr wl010 wl1020 wl2030 gr30, by(announce_name)

	save Texas_UI_Data/soph_affected_by_announce`x'.dta, replace
}

forvalues x=1/9 {
	append using Texas_UI_Data/soph_affected_by_announce`x'
}

collapse (sum) id change_ui_nonui - change_20togr wl010 wl1020 wl2030 gr30, by(announce_name)

merge 1:1 announce_name using Texas_UI_Data/announce_data
drop _merge

compress
save Texas_UI_Data/announce_affected_amt, replace
*** For Each Announcement ***
*** Before and After ***
** eb13_1week, tier1_13_1week, tier1_20_1week, tier3_1week, tier2_extra_1week, tier4_1week, eb20_1week, hole1_last_1week, hole2_1week, hole3_last_1week, hole4_last_1week, hole5_last_1week, hole6_last_1week, hole7_last_1week, hole_last_1week

