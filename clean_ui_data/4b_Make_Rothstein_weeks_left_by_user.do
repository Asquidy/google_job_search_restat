*** This Code generate an expected weeks left number for each observation.
*** The Assumption is that individuals never expect benefits to be renewed.
set mem 8000m
forvalues x=1/10 {
	clear all
	set more off
	cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
	cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"
	cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data"
	use all_pay_data_clean

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

	*** Correct Anomalous Dates
	gen mod_date = mod(date,7)
	replace date = date - mod_date + 1
	drop mod_date

	*** Drop if TUC first
	sort id date
	gen tucfirst = 1 if tier_code == 5 & (id!=id[_n-1] | _n==1)
	egen max_tucfirst = max(tucfirst), by(id)
	drop if max_tucfirst==1
	drop tucfirst

	*** Merge Eligibilities
	cap merge m:1 date using "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta"
	cap merge m:1 date using "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta"
	cap merge m:1 date using "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta"
	drop if _merge == 2
	drop _merge
	duplicates drop id date, force

	*** Merge w/ Retroactive Payments ***
	cap merge 1:1 id date using "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/retroactive_payment_data.dta"
	cap merge 1:1 id date using "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data\retroactive_payment_data.dta"
	cap merge 1:1 id date using "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\retroactive_payment_data.dta"
	cap drop retro_month retro_day retro_year
	gsort id -date
	drop if _merge==2
	gen retropayment=(_merge==3)
	drop _merge	 
	gen retroweeknum=num_retro
	replace retroweeknum=retroweeknum[_n-1]-1 if id==id[_n-1] & date>(date[_n-1]-8)&retroweeknum[_n-1]>1&retroweeknum==.

	sort id date
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

	*** Drop guys with weird dates
	egen count_date = count(date), by(date)
	gen temp = 1 if count_date<100
	egen max_bad_date = max(temp), by(id)
	drop if max_bad_date==1
	drop max_bad_date temp count_date
	
	*** Drop last weeks of a spell where guy didn't earn any money
	drop if tier_code==.

	*** Drop those who never get regular benefits
	egen min_tier = min(tier_code), by(id)
	drop if min_tier>2
	drop min_tier

	*** Drop first weeks of a spell where guy didn't earn any money
	*forvalues z = 1/10 {
		*drop if (id!=id[_n-1] & actual_ui==0)
	*}   

	*** Fix places where they received a 'last payment' but actually just moving to EUC
	replace endofspell=0 if endofspell==1 & id==id[_n+1] & date==date[_n+1]-7 & weekly_ben_amt==weekly_ben_amt[_n+1] & (tier_code==2 & tier_code[_n+1]==5)
	replace paid_last_quarter=. if endofspell==0
	replace endofspell=1 if ((date[_n+1]-365)>date & id==id[_n+1] & tier_code[_n+1]==2) | ((date[_n+1]-30)>date & id==id[_n+1] & tier_code==2 & (max_ben_amt!=max_ben_amt[_n+1]) & tier_code[_n+1]==2) 

	cap drop islastweek
	rename max_ben_amt total_ben_amt

	gen firstweekofspell=(endofspell[_n-1]==1 & id==id[_n-1])|(id!=id[_n-1])
	replace spellnum=spellnum[_n-1]+firstweekofspell if id==id[_n-1]
	
	
	***Here maybe fix spell num where guys went from TUC back to REG without it being a new spell
	
	
	gen paygr0 = (actual_ui_payment>0)

	gen weekson = 0
	replace weekson = weekson[_n-1] + paygr0 if id==id[_n-1] & spellnum[_n-1]==spellnum & _n>1
	gen weeksinspell = 0
	replace weeksinspell = weeksinspell[_n-1] + 1 if id==id[_n-1] & spellnum[_n-1]==spellnum & _n>1

	*** Number of Regular Weeks On
	gen reg_eligible_amount2 = total_ben_amt if tier_code==2
	egen reg_eligible_amount = max(reg_eligible_amount2), by(id spellnum)
	drop reg_eligible_amount2

	gen reg_weekly_amount2 = max(weekly_ben_amt, actual_ui_payment) if tier_code==2	
	egen reg_weekly_amount = max(reg_weekly_amount2), by(id spellnum)
	drop reg_weekly_amount2	

	gen reg_amount_left=reg_eligible_amount if firstweekofspell==1 & tier_code==2
	replace actual_ui_payment = 0 if actual_ui_payment==.
	replace reg_amount_left=reg_amount_left[_n-1]-actual_ui_payment[_n-1] if id==id[_n-1]&spellnum==spellnum[_n-1] & tier_code==2

	replace reg_amount_left = 0 if tier_code==5&id==id[_n-1]

	gen reg_weeks_left=ceil(reg_amount_left/reg_weekly_amount)
	replace reg_weeks_left=0 if tier_code==5

	*** Drop guys who have negative weeks left
	gen temp = reg_weeks_left<0
	egen temp2 = max(temp), by(id spellnum)
	drop if temp2==1
	drop temp*
	
	*** Fraction of Theoretical Benefits Eligible For
	gen reg_fraction = (total_ben_amt/weekly_ben_amt)/26  if tier_code==2
	egen fraction_eligible=max(reg_fraction), by(id spellnum)
	drop reg_fraction
	replace fraction_eligible = fraction_eligible[_n-1] if fraction_eligible==.

	*** Step 1: EUC first
	sort id spellnum date
	gen first_ratio = ceil(total_ben_amt/weekly_ben_amt) if id==id[_n-1] & spellnum == spellnum[_n-1] & tier_code[_n-1]==2 & tier_code==5

	egen first_TUC = min(date) if tier_code==5, by(spellnum id)
	gen first_tier1 = (date == first_TUC)
	drop first_TUC
	
	*** Maximum EUC weeks eligible at a given date
	*** Assume the Following Order:
	*** Tiers Go In Order Unless There is a change in benefit amount
	*** Calculate Weeks Left for Each Tier / EB
	
	replace tier2 = tier2+tier2extra
	drop tier2extra
	
	***************************************************************************************************************
	***************************************************************************************************************
	***First make naive weeks_eligible including EUC and EB
	gen weeks_eligible_tier1 = ceil(tier1*fraction_eligible)
	gen weeks_eligible_tier2 = ceil(tier2*fraction_eligible)
	gen weeks_eligible_tier3 = ceil(tier3*fraction_eligible)
	gen weeks_eligible_tier4 = ceil(tier4*fraction_eligible)
	gen weeks_eligible_eb = eb
	
	gen naive_euc_eligible = weeks_eligible_tier1 + weeks_eligible_tier2 + weeks_eligible_tier3 + weeks_eligible_tier4 + weeks_eligible_eb

	*** Calculate Money Left for Each Tier / EB		
	egen euc_weekly_pay = max(weekly_ben_amt) if tier_code==5, by(id) 
	egen euc_weekly_pay2 = max(euc_weekly_pay), by(id)
	drop euc_weekly_pay
	rename euc_weekly_pay2 euc_weekly_pay
	egen max_reg_pay = max(weekly_ben_amt) if tier_code==2, by(id)
	replace euc_weekly_pay = max_reg_pay if euc_weekly_pay==.
	drop max_reg_pay

	gen eligible_amount_tier1 = weeks_eligible_tier1*euc_weekly_pay
	gen eligible_amount_tier2 = weeks_eligible_tier2*euc_weekly_pay
	gen eligible_amount_tier3 = weeks_eligible_tier3*euc_weekly_pay
	gen eligible_amount_tier4 = weeks_eligible_tier4*euc_weekly_pay
	gen eligible_amount_eb = weeks_eligible_eb*euc_weekly_pay

	gen eligible_amount_euc = eligible_amount_tier1 + eligible_amount_tier2 + eligible_amount_tier3 + eligible_amount_tier4 + eligible_amount_eb

	***Now calculate naive weeks left
	gen tier1_amount_left = eligible_amount_tier1
	replace tier1_amount_left = tier1_amount_left[_n-1]-actual_ui_payment[_n-1] if id==id[_n-1] & spellnum==spellnum[_n-1] & tier_code==5 & eligible_amount_tier1[_n-1]!=0
	replace tier1_amount_left = 0 if tier1_amount_left<0
	gen tier1_weeks_left=ceil(tier1_amount_left/euc_weekly_pay)
	
	gen tier2_amount_left = eligible_amount_tier2

	replace tier2_amount_left=tier2_amount_left[_n-1]-actual_ui_payment[_n-1] if id==id[_n-1] & spellnum==spellnum[_n-1] & tier_code==5 & tier1_amount==0 & eligible_amount_tier2[_n-1]!=0
	replace tier2_amount_left = 0 if tier2_amount_left<0
	gen tier2_weeks_left=ceil(tier2_amount_left/euc_weekly_pay)	
	
	gen tier3_amount_left = eligible_amount_tier3
	replace tier3_amount_left=tier3_amount_left[_n-1]-actual_ui_payment[_n-1] if id==id[_n-1] & spellnum==spellnum[_n-1] & tier_code==5 & tier2_amount==0 & tier1_amount==0 & eligible_amount_tier3[_n-1]!=0
	replace tier3_amount_left = 0 if tier3_amount_left<0
	gen tier3_weeks_left=ceil(tier3_amount_left/euc_weekly_pay)	

	gen tier4_amount_left = eligible_amount_tier4
	replace tier4_amount_left=tier4_amount_left[_n-1]-actual_ui_payment[_n-1] if id==id[_n-1] & spellnum==spellnum[_n-1] & tier_code==5 & tier3_amount==0 & tier2_amount==0 & tier1_amount==0 & eligible_amount_tier4[_n-1]!=0
	replace tier4_amount_left = 0 if tier4_amount_left<0
	gen tier4_weeks_left=ceil(tier4_amount_left/euc_weekly_pay)		
	
	gen eb_amount_left = eligible_amount_eb
	replace eb_amount_left=eb_amount_left[_n-1]-actual_ui_payment[_n-1] if id==id[_n-1] & spellnum==spellnum[_n-1] & tier_code==5 & tier4_amount==0  & tier3_amount==0 & tier2_amount==0 & tier1_amount==0 & eligible_amount_eb[_n-1]!=0
	replace eb_amount_left = 0 if eb_amount_left<0
	gen eb_weeks_left=ceil(eb_amount_left/euc_weekly_pay)		
		

	gen naive_total_weeks_left = reg_weeks_left + tier1_weeks_left + tier2_weeks_left + tier3_weeks_left + tier4_weeks_left + eb_weeks_left
	
	***************************************************************************************************************
	***************************************************************************************************************
	***Now make sophisticated weeks left with legislation expirations
	gen naive_expiration_date = date+(7*naive_total_weeks_left)
	drop if naive_expiration==.
	
	gen EUC_expires = 0
	foreach var in hole8 hole7 hole6 hole5 hole4 hole3 hole2 hole1 {
		replace EUC_expires = `var'_start if date<`var'_last
	}

	** Code checks whether each tier is available before the current EUC expiration date.
	*** Naive Expiration Date is calculated previously to include all possible tiers left.
	gen soph_expiration_date = naive_expiration_date if (naive_expiration_date-tier4_weeks_left*7-eb_weeks_left*7)<EUC_expires
	replace soph_expiration_date= naive_expiration_date - tier4_weeks_left*7 if (naive_expiration_date-tier3_weeks_left*7 - tier4_weeks_left*7-eb_weeks_left*7)<EUC_expires & soph_expiration_date==.
	replace soph_expiration_date= naive_expiration_date - tier4_weeks_left*7 - tier3_weeks_left*7 if (naive_expiration_date - tier2_weeks_left*7 - tier3_weeks_left*7 - tier4_weeks_left*7-eb_weeks_left*7)<EUC_expires & soph_expiration_date==.
	replace soph_expiration_date= naive_expiration_date - tier4_weeks_left*7 - tier3_weeks_left*7 - tier2_weeks_left*7 if (naive_expiration_date - tier1_weeks_left*7 - tier2_weeks_left*7 - tier3_weeks_left*7 - tier4_weeks_left*7-eb_weeks_left*7)<EUC_expires & soph_expiration_date==.
	replace soph_expiration_date= naive_expiration_date - tier4_weeks_left*7 - tier3_weeks_left*7 - tier2_weeks_left*7  - tier1_weeks_left*7 if ((naive_expiration_date - reg_weeks_left*7 - eb_weeks_left*7 - tier1_weeks_left*7 - tier2_weeks_left*7 - tier3_weeks_left*7 - tier4_weeks_left*7)<EUC_expires) & soph_expiration_date==.
	replace soph_expiration_date= naive_expiration_date - tier4_weeks_left*7 - tier3_weeks_left*7 - tier2_weeks_left*7  - tier1_weeks_left*7 if (date>EUC_expires) & soph_expiration_date==.
	replace soph_expiration_date = soph_expiration_date[_n-1] if soph_expiration_date==. & id==id[_n-1] & spellnum==spellnum[_n-1]
	replace soph_expiration_date = naive_expiration_date if soph_expiration_date==.
	
	gen soph_total_weeks_left = (soph_expiration_date-date)/7
	
	format soph_expiration_date %td
	format EUC %td
	format naive_expir %td
	format date %td
	order date EUC soph_expiration_date naive_expir *weeks_left
	order date EUC soph_expiration_date naive_expir soph_total_weeks_left naive_total_weeks
	compress
	save temp, replace
	
	**************************************************************************************************************
	**************************************************************************************************************
	
	drop reg_weeks_left reg_eligible_amount reg_amount_left fraction_eligible endofspell firstweek *hole* weeks_eligible_* 
        drop in2006 max_tucfirst tier1_amount_left-eb_amount_left EUC_expires eligible_amount* first_* naive_euc_eligible euc_weekly_pay paygr0 tier1-tier4 
        order id date
	
	compress
	save user_weeks_left_roth_data_`x', replace
	
}

clear all

*** Append Chunks of Data
use user_weeks_left_roth_data_1 
forvalues x=2/10 {
	append using user_weeks_left_roth_data_`x'
}

compress
save user_weeks_left_roth_data, replace



/***Make some graphs about numbers of weeks left, benefit amounts, naive v. soph, and others:
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"
cap cd "C:\Users\Scott Baker\Dropbox\Texas Job Search - New\Texas_UI_Data"

clear all
use user_weeks_left_roth_data

gen frac_naive_less20 = naive_total_weeks_left<20
gen frac_soph_less20 = soph_total_weeks_left<20
gen frac_naive_less10 = naive_total_weeks_left<10
gen frac_soph_less10 = soph_total_weeks_left<10
gen frac_part_time_work = earned_inc_amt>0
gen only_non_part_time_avg_pay = actual_ui_payment if actual_ui_payment==weekly_ben_amt

egen naive_max_weeks_left = max(naive_total_weeks_left) if weekson==1, by(date)
egen soph_max_weeks_left = max(soph_total_weeks_left) if weekson==1, by(date)

collapse actual_ui_payment only_non_part_time_avg_pay naive_max_weeks_left soph_max_weeks_left weekson weeksinspell frac_part_time_work weekly_ben_amt naive_total_weeks_left soph_total_weeks_left *less* (count) id , by(date)

gen year = year(date)
drop if year==2006

compress
save graph_data, replace
cap use graph_data

foreach var of varlist naive_max_weeks_left soph_max_weeks_left {
	replace `var' = `var'[_n-1] if `var'[_n-1]!=`var' & `var'[_n-1]==`var'[_n+1]
}

label var id "Total on UI"
label var naive_total_weeks_left "Current Pol Avg Weeks Left"
label var soph_total_weeks_left "Current Law Avg Weeks Left"
label var frac_naive_less20 "Current Pol % Under 20 Weeks"
label var frac_soph_less20 "Current Law % Under 20 Weeks"
label var frac_naive_less10 "Current Pol % Under 10 Weeks"
label var frac_soph_less10 "Current Law % Under 10 Weeks"
label var weekson "Avg Num of Weeks on UI"
label var weeksinspell "Avg Num of Weeks on UI"
label var naive_max_weeks_left "Current Pol Weeks Eligible"
label var soph_max_weeks_left "Current Law Weeks Eligible"
label var only_non_part_time_avg_pay "Average Actual Benefit Amount"
label var weekly_ben_amt "Average Eligible Benefit Amount"
label var frac_part_time_work "Fraction Working Part Time"

**Avg weeks eligible for new UI recipients
twoway (line naive_max_weeks_left date)(line soph_max_weeks_left date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\weeks_eligible_by_type_new_users.png", width(1200) height(600) replace
cap graph export "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\weeks_eligible_by_type_new_users.png", width(1200) height(600) replace

**Avg weeks left by type over time
twoway (line naive_total_weeks_left date, lpattern(dash))(line soph_total_weeks_left date) if date<18978
cap graph export "C:\Users\Scott Baker\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\weeks_left_by_type.png", width(1200) height(600) replace
cap graph export "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\weeks_left_by_type.png", width(1200) height(600) replace

**Avg Fraction of those on UI with less than XX weeks left
twoway (line frac_naive_less20 date)(line frac_soph_less20 date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\frac_under_20_weeks.png", width(1200) height(600) replace
cap graph export "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\frac_under_20_weeks.png", width(1200) height(600) replace

twoway (line frac_naive_less10 date)(line frac_soph_less10 date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\frac_under_10_weeks.png", width(1200) height(600) replace
cap graph export "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\frac_under_10_weeks.png", width(1200) height(600) replace

**Total on UI
twoway (line id date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\total_on_ui.png", width(1200) height(600) replace

**Avg weekly benefit
twoway (line weekly_ben_amt date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\avg_benefit_amt.png", width(1200) height(600) replace

twoway (line only_non_part_time_avg_pay date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\non_part_time_ben.png", width(1200) height(600) replace

twoway (line only_non_part_time_avg_pay date)(line weekly_ben_amt date) if date<18978


**Frac Working Part Time
twoway (line frac_part_time_work date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\frac_part_time_work.png", width(1200) height(600) replace

**Avg Weeks On/Used
twoway (line weeksinspell date) if date<18978
cap graph export "C:\Users\sbaker2\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Figures\avg_weeks_used.png", width(1200) height(600) replace

*/
