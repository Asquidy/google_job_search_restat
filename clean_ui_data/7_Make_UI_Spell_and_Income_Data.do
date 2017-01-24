clear all
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"
set mem 8000m
use user_weeks_left_data

*************NOW CONSTRUCT DATA ABOUT EACH SPELL

egen spell_id=group(id spellnum)

egen spell_weeks = count(spell_id), by(spell_id)

egen start_spell = min(date), by(spell_id)
egen end_spell = max(date), by(spell_id)

*** Eligible At Start
*egen spell_ui_inc = min(euc_eligible_amount+reg_eligible_amount), by(spell_id)

*** Non-UI Earned
egen spell_earn_inc = sum(earned_inc_amt), by(spell_id)
drop earned_inc_amt
*** UI Earned
egen spell_ui_earn = sum(actual_ui_payment), by(spell_id)
drop actual_ui_payment
egen earned_pay_in_lastornextquarter = max(paid_last_), by(spell_id)
drop paid_last_

gen temp = total_weeks_left if spell_id!=spell_id[_n-1]
egen start_num_weeks = max(temp), by(spell_id)
drop temp
gen temp = total_weeks_left if spell_id!=spell_id[_n+1]
egen end_num_weeks = max(temp), by(spell_id)
drop temp

sort id spell_id date
drop if spell_id==spell_id[_n-1] & spell_id[_n-1]!=.
drop date tier total_weeks

save spell_data_temp, replace
***************NOW MERGE IN BASE PERIOD DATA
**Try to match with the start date of the ui spell
rename start_spell date

**create base_quarter which is generally 5 quarters before UI start quarter
gen base_quarter = qofd(date)-5

**Merge with the recipients base quarter data
merge m:1 id base_quarter using base_period_data_collapsed
**Make a date if the observed base quarter is BEFORE we think it should be
replace date = dofq(base_quarter) if _merge==2
sort id date

**drop the second base period if there already was one
drop if _merge==2 & spell_id==spell_id[_n-1] & date[_n+1]==date[_n-1]+7

**sort and fill down
replace max_base_quarter_wages = max_base_quarter_wages[_n-1] if id==id[_n-1] & max_base_quarter_wages==.
replace total_base_wages = total_base_wages[_n-1] if id==id[_n-1] & total_base_wages==.
replace total_base_wages = total_base_wages[_n-1] if id==id[_n-1] & total_base_wages==.
replace median_base_wages = median_base_wages[_n-1] if id==id[_n-1] & median_base_wages==.
replace num_quarters_in = num_quarters_in[_n-1] if id==id[_n-1] & num_quarters_in==.
drop if _merge==2
drop _merge
sort spell_id date

** this is another loop for base quarters that are AFTER where we think it should be
replace base_quarter=base_quarter+1
rename max_base_quarter_wages max_base_quarter_wagesold
rename total_base_wages total_base_wagesold
rename median_base_wages median_base_wagesold
rename num_quarters_in_base_period num_quarters_in_base_periodold
merge m:1 id base_quarter using base_period_data_collapsed
replace total_base_wages=total_base_wagesold if total_base_wagesold~=.
replace median_base_wages = median_base_wagesold if median_base_wagesold~=.
replace max_base_quarter_wages=max_base_quarter_wagesold if max_base_quarter_wagesold~=.
replace num_quarters_in_base_period=num_quarters_in_base_periodold if num_quarters_in_base_periodold~=.
drop max_base_quarter_wagesold total_base_wagesold median_base_wagesold num_quarters_in_base_periodold
drop if _merge==2
rename _merge fourquarters
sort id date
**this is a third loop for base quarters that are AFTER where we think it should be
replace base_quarter=base_quarter+1
rename max_base_quarter_wages max_base_quarter_wagesold
rename total_base_wages total_base_wagesold
rename median_base_wages median_base_wagesold
rename num_quarters_in_base_period num_quarters_in_base_periodold

merge m:1 id base_quarter using base_period_data_collapsed
replace total_base_wages=total_base_wagesold if total_base_wagesold~=.
replace median_base_wages = median_base_wagesold if median_base_wagesold~=.
replace max_base_quarter_wages=max_base_quarter_wagesold if max_base_quarter_wagesold~=.
replace num_quarters_in_base_period=num_quarters_in_base_periodold if num_quarters_in_base_periodold~=.
drop max_base_quarter_wagesold total_base_wagesold median_base_wagesold num_quarters_in_base_periodold
drop if _merge==2
rename _merge threequarters

**SET BACK TO CORRECT NAME
rename date start_spell 

***************NOW MERGE IN POST UI INCOME DATA

gen last_payment_year = year(end_spell)
gen last_payment_month = month(end_spell)
gen last_payment_day = day(end_spell)

merge 1:1 id last_payment_year last_payment_month last_payment_day using post_benefit_employment_data
drop if _merge==2|_merge==1
drop _merge
drop *27 date weekson paygr

compress
save all_spell_income_data, replace
