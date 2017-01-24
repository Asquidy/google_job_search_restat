*** Logic for Spells ***
/*

A) New time on regular, with different max benefits.
B) New Base Period Wages. 
*/
cap set mem 6000m
set more off
clear all
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"


use base_period_wage_data
gen base_date = mdy(base_month, base_day, base_year)
gen base_quarter = quarter(base_date)

**Here fix some fat finger errors**
sort id base_date wage_year wage_quarter
rep=ace wage = wage[_n+1] if wage>=wage[_n+1]*100 & id==id[_n+1] & wage[_n+1]>=1000
replace wage = wage[_n-1] if wage>=wage[_n-1]*100 & id==id[_n-1] & wage[_n-1]>=1000
replace wage = wage[_n+1] if inrange(wage,wage[_n+1]*10-9,wage[_n+1]*10+9) & id==id[_n+1] & wage[_n+1]>=1000
replace wage = wage[_n-1] if inrange(wage,wage[_n-1]*10-9,wage[_n-1]*10+9) & id==id[_n-1] & wage[_n-1]>=1000

drop if wage>250000 & ((id==id[_n+1] & base_date==base_date[_n+1])|(id==id[_n-1] & base_date==base_date[_n-1]))

egen user_base_group = group(id base_date)
egen max_base_quarter_wages = max(wage), by(user_base_group)
egen total_base_wages = sum(wage), by(user_base_group)
egen median_base_wages = median(wage), by(user_base_group)

gen num_quarters_in_base_period = 1
drop if total_base_wages<500

*gen weekly_ben_amt = round(max_base_quarter/25)
*gen total_ben_amt = round(min(weekly_ben_amt*26, total_base_wages*.27))

collapse max_base_quarter_wages total_base_wages median_base_wages (sum) num_quarters , by(id base_date)
gen base_quarter = qofd(base_date)

compress
save base_period_data_collapsed, replace

*** Here keeping only first base period for each user
egen min_base = min(base_date), by(id)
drop if base_date!=min_base
drop min_base

compress
save base_period_data_collapsed_onlyfirst, replace

/*
egen ncounties=nvals(county_fips), by(id)
egen ncities=nvals(city_code), by(id)
*********** 
** Truncate Sample ***
keep if mod(id,11)==0
merge m:1 date min_max_weekly_data
*********** 
sort id date
*** Gap, Ben Amt, Tier
gen gap=date-date[_n-1] if id==id[_n-1]
*** Some people maxed out ***
gen isdiffamt=(weekly_ben_amt!=weekly_ben_amt[_n-1]) if id==id[_n-1]
gen isdifftier=(tier_code!=tier_code[_n-1]) if id==id[_n-1]

gen weirdalternating=0
replace weirdalternating=1 if weekly_ben_amt==weekly_ben_amt[_n-2] & weekly_ben_amt~=weekly_ben_amt[_n-1] & id==id[_n-2]

gen newspell=0
replace newspell=1 if (weekly_ben_amt!=weekly_ben_amt[_n-1]) & tier_code==2 & id==id[_n-1]&weirdalternating!=1
replace newspell=1 if (weekly_ben_amt==weekly_ben_amt[_n-1]) & tier_code==2 & (gap>90) & (weekly_ben_amt==max_ben) & id==id[_n-1]
replace newspell=1 if (tier_code[_n-1]!=tier_code) & tier_code==2 & id==id[_n-1]

gen spellnum=1
replace spellnum=spellnum[_n-1]+newspell if id==id[_n-1]

egen maxspellnum=max(spellnum), by(id)

