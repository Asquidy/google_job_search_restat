clear all
set more off
cap set mem 8000m
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"

forvalues x=1/4 {
	clear all
	set more off
	cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
	cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"
	cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data"
	use all_pay_data_clean

	global y = `x'

	if $y==1 {
		global id_cut_low = 0
		global id_cut_high = 67900000
	}
	if $y==2 {
		global id_cut_low = 67900000
		global id_cut_high = 100000000
	}
	if $y==3 {
		global id_cut_low = 100000000
		global id_cut_high = 120000000
	}
	if $y==4 {
		global id_cut_low = 120000000
		global id_cut_high = 10000000000
	}
	keep if id>=$id_cut_low & id<$id_cut_high

	*** Drop Those Who Ever Get TRA/TRX
	gen temp = 1 if tier_code==3|tier_code==4
	egen temp2 = max(temp), by(id)
	drop if temp2==1
	drop temp*

	*** Drop Those That Have No Regular Weeks
	egen num_regs=count(id) if tier_code==2, by(id)
	egen has_regulars=max(num_regs), by(id)
	drop if has_regulars==.
	drop num_regs has_reg

	*** Create Weeks Left ***
	*** Strategy: Keep Track of Regular and EUC Eligble Amounts ***
	sort id tier_code date 
	merge m:1 date using TX_Weeks_Left_Data
	drop if _merge==2
	drop _merge
	sort id date 
	
	*** Drop guys with weird dates
	egen count_date = count(date), by(date)
	gen temp = 1 if count_date<100
	egen max_bad_date = max(temp), by(id)
	drop if max_bad_date==1
	drop max_bad_date temp count_date

	*** Drop last weeks of a spell where guy didn't earn any money
	forvalues z = 1/10 {
		drop if tier_code==.|(paid_last_quarter[_n-1]!=. & id==id[_n-1] & actual_ui==0)
	}
	*** Drop first weeks of a spell where guy didn't earn any money
	forvalues z = 1/10 {
		drop if (id!=id[_n-1] & actual_ui==0)
	}	
	
	*** Fix places where they received a 'last payment' but everything continues on as before the next week
	replace endofspell=0 if endofspell==1 & id==id[_n+1] & date==date[_n+1]-7 & tier_code==tier_code[_n+1] & weekly_ben==weekly_ben[_n+1] & max_ben==max_ben[_n+1]
	replace paid_last_quarter=. if paid_last_quarter!=. & id==id[_n+1] & date==date[_n+1]-7 & tier_code==tier_code[_n+1] & weekly_ben==weekly_ben[_n+1] & max_ben==max_ben[_n+1]

	*** Just For Reg
	drop islastweek
	rename max_ben_amt total_ben_amt
	
	replace endofspell=1 if ((date[_n+1]-365)>date & id==id[_n+1] & tier_code[_n+1]==2) | ((date[_n+1]-30)>date & id==id[_n+1] & tier_code==2 & (total_ben_amt!=total_ben_amt[_n+1]) & tier_code[_n+1]==2) 

	gen firstweekofspell=(endofspell[_n-1]==1 & id==id[_n-1])|(id!=id[_n-1])
	sort id date

	replace spellnum=spellnum[_n-1]+firstweekofspell if id==id[_n-1]
	gen paygr0 = (actual_ui_payment>0)

	*** Cutoff for Weeks On is 2 months if same spell or 1 month if not same spell.

    gen weekson = 0
  	replace weekson = weekson[_n-1] + paygr0 if id==id[_n-1] & ((spellnum[_n-1]==spellnum & (date[_n-1]+ 60) > date) | (date[_n-1]+30 > date & spellnum[_n-1]!=spellnum)) & _n>1

	***Drop spells that only have EUC?
	egen min_tier = min(tier_code), by(spellnum id)
	drop if min_tier>2
	drop min_tier
	
	*** Missing Potential Reg that is never realized
	gen reg_eligible_amount2=total_ben_amt if tier_code==2

	egen reg_eligible_amount=max(reg_eligible_amount2), by(id spellnum)

	drop reg_eligible_amount2
	*** Some Missing Values: Because some spells consist solely of EUC
	
	gen reg_amount_left=reg_eligible_amount if firstweekofspell==1 & tier_code==2

	replace reg_amount_left=reg_amount_left[_n-1]-actual_ui_payment if id==id[_n-1]&spellnum==spellnum[_n-1] & tier_code==2
	
	*** For EUC Before Reg
	replace reg_amount_left = reg_amount_left[_n-1] if tier_code==5&id==id[_n-1]&firstweekofspell==0

	gen reg_weeks_left=ceil(reg_amount_left/weekly_ben_amt)
	
	replace reg_weeks_left=0 if tier_code==5
	
	**Drop claimants who we get the wrong number of regular weeks left for?
	*gen temp = (reg_weeks_left<0|reg_weeks_left>30) & tier_code==2
	*egen bad_guys = max(temp), by(id)
	*drop if bad_guys==1

	*** Maximum Possible Weeks At Date
	gen all_weeks_total=tier1+tier2+tier2extra+tier3+tier4+eb
	
	gen reg_fraction = (total_ben_amt/weekly_ben_amt)/26  if tier_code==2
	egen fraction_eligible=max(reg_fraction), by(id spellnum)
	drop reg_fraction
	
	gen added_benefit = 0
	replace added_benefit = all_weeks_total - all_weeks_total[_n-1] if id==id[_n-1]
	*** What about EUC first then new Reg?
	sort id date
	
	gen euc_eligible_amount = (ceil(fraction_eligible*tier1)+ceil(fraction_eligible*tier2)+ceil(fraction_eligible*tier3)+ceil(fraction_eligible*tier4) + eb + tier2extra)*weekly_ben_amt
	drop tier1-tier4

	*** Calculate First Euc Week to Start Count of Eligible EUC Amount
	gen first_euc_week2 = 999999
	replace first_euc_week2 = date if tier_code==5

	egen first_euc_week=min(first_euc_week2), by(id spellnum)

	drop first_euc_week2

	gen is_first_euc_week = (date==first_euc_week)

	gen euc_amount_left = 0
	replace euc_amount_left=euc_eligible_amount if date<first_euc_week

	sort id spellnum tier_code date
	
	replace euc_amount_left = euc_eligible_amount - actual_ui_payment if is_first_euc_week==1

	replace euc_amount_left = euc_amount_left[_n-1]-actual_ui_payment + added_benefit*weekly_ben_amt if tier_code==5&tier_code[_n-1]==5
	
	sort id date

	replace euc_amount_left = euc_amount_left[_n-1] if tier_code==2 & id==id[_n-1] & date > first_euc_week

	*** drop first_euc_week

	*** What about Max Benefit Changes?
	gen euc_weeks_left=ceil(euc_amount_left/weekly_ben_amt)

	gen total_amount_left = reg_amount_left + euc_amount_left
	gen total_weeks_left = reg_weeks_left + euc_weeks_left

	*** Fix REG being in the middle of the benefit time
	replace total_weeks_left = total_weeks_left[_n-1]-1 if total_amount_left==. & id==id[_n-1] & spellnum==spellnum[_n-1]
	
	compress
	save user_weeks_left_data_`x', replace
	
}

clear all
forvalues x=1/4 {
	append  using user_weeks_left_data_`x'
}

drop  reg_eligible_amount reg_amount_left reg_weeks_left all_weeks_total fraction_eligible added_benefit euc_eligible_amount first_euc_week is_first_euc_week euc_amount_left euc_weeks_left total_amount_left endofspell firstweek
compress
save user_weeks_left_data, replace
***Can drop all messed up obs here?

/*
*** Adjust for retroactive weeks ***
*** Why are some retro payments not matched?
*** Most of these are because we dropped some ids 50% appear 4 or fewer times and have had 4 retro payments. 
*** Those that have more tend to have non-overlapping retro and actual benefits

cap merge 1:1 id date using "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/retroactive_payment_data.dta"
cap merge 1:1 id date using "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data\retroactive_payment_data.dta"
drop retro_month retro_day retro_year
gsort id -date
drop if _merge==2
gen retropayment=(_merge==3)
drop _merge

*** Algorithm ***
*** Start with retro payment and backwards in time ***
*** If there is a date gap or if numretro goes to 0, stop ***
gen retroweeknum=num_retro
replace retroweeknum=retroweeknum[_n-1]-1 if id==id[_n-1] & date>(date[_n-1]-8)&retroweeknum[_n-1]>1&retroweeknum==.
compress
save user_weeks_left_data, replace

drop if retroweeknum>0 & retroweeknum~=.
compress
Check if premature stop
egen minretroweeknum=min(retroweeknum), by(id)
save user_weeks_left_data_noretro, replace
*/
