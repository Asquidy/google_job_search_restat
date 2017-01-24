clear all
set more off
cap set mem 8000m
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"

forvalues x=0/4 {

	use all_pay_data
	sleep 10000
	keep if mod(id,5)==`x'
	duplicates drop ui_year ui_month ui_day id, force
	save all_pay_data`x'.dta, replace
	clear all
	cap use ui_actual_payment_data
	keep if mod(id,5)==`x'
	merge 1:1 id ui_year ui_month ui_day using all_pay_data`x' 

	rename _merge linkedactualandpay
	drop if linkedactualandpay==2
	*** 3k Dropped ***

	*** 
	* 3906 obs that were not matched to actual data
	* 8 MM obs that were not in all_pay_clean
	* 5 MM obs that were not in all_pay_clean have 0 payment
	***

	gen inactualpay=(linkedactualandpay==3)
	egen maxpay=max(inactualpay), by(id)
	drop if maxpay==0
	* 2MM Dropped
	drop maxpay inactualpay

	egen totaluipay=sum(actual_ui_payment), by(id)
	drop if totaluipay==0
	drop totaluipay

	*** Merge ***

	rename ui_year year
	rename ui_month month
	rename ui_day day
	gen date = mdy(month, day, year)

	*****Any Cleaning In Here**********
	** drop people with weekly pay = 0 
	gen tag = weekly==0
	egen user_tag = max(tag), by(id)
	drop if user_tag==1
	drop user_tag tag

	**drop miscoded people who have max total ben's = 50000
	gen tag =1 if max==50000
	egen user_tag = max(tag), by(id)
	drop if user_tag==1
	drop user_tag tag

	merge 1:1 id date using post_benefit_employment_data_small, keep(master match) 
	drop if _merge==2
	rename _merge islastweek

	**drop people who are already around in the first month of the data as we cannot observe their start date
	gen tag = year==2006 & month<3
	drop year month day
	format %td date

	egen user_tag = max(tag), by(id)
	drop tag
	preserve
	keep if user_tag==1
	save only_2006`x'.dta, replace
	restore

	drop if user_tag==1
	drop user_tag
	 
	compress
	save all_pay_data_clean`x'.dta, replace
}

*** Fill In Some Non_Matched Obs ***
*** Note, some "difficult cases" will still be blank ***

*** Cases where missing is an entire spell that is not in the all_pay_data **
forvalues x=0/4 {
	use all_pay_data_clean`x'.dta

	egen firstzip=max(zip), by(id)
	drop zip
	rename firstzip zip

	egen firstfips=max(county_fips), by(id)
	drop county_fips
	rename firstfips county_fips

	egen firstcc=max(city_code), by(id)
	drop city_code
	rename firstcc city_code

	sort id date
	gen spellnum=1
	**this makes end of spell indicator if we had observed them in the last week payment data
	gen endofspell=(paid_last_quarter!=.)
	replace spellnum=spellnum[_n-1]+endofspell[_n-1] if id==id[_n-1]
	replace weekly_ben_amt=weekly_ben_amt[_n-1] if weekly_ben_amt==. & spellnum==spellnum[_n-1]
	replace max_ben_amt=max_ben_amt[_n-1] if max_ben_amt==. & spellnum==spellnum[_n-1]
	replace tier_code=tier_code[_n-1] if tier_code==. & spellnum==spellnum[_n-1]

	gsort id -date
	replace weekly_ben_amt=weekly_ben_amt[_n-1] if weekly_ben_amt==. & spellnum==spellnum[_n-1]
	replace max_ben_amt=max_ben_amt[_n-1] if max_ben_amt==. & spellnum==spellnum[_n-1]
	replace tier_code=tier_code[_n-1] if tier_code==. & spellnum==spellnum[_n-1]

	save all_pay_data_clean`x'.dta, replace		
	
	use only_2006`x'.dta
	*** Get Rid of First Spell ***
	sort id date
	gen spellnum=0
	gen endofspell=(paid_last_quarter!=.)
	replace spellnum=spellnum[_n-1]+endofspell[_n-1] if id==id[_n-1]
	drop if spellnum==0
	
	egen firstzip=max(zip), by(id)
	drop zip
	rename firstzip zip

	egen firstfips=max(county_fips), by(id)
	drop county_fips
	rename firstfips county_fips

	egen firstcc=max(city_code), by(id)
	drop city_code
	rename firstcc city_code

	replace weekly_ben_amt=weekly_ben_amt[_n-1] if weekly_ben_amt==. & spellnum==spellnum[_n-1]
	replace max_ben_amt=max_ben_amt[_n-1] if max_ben_amt==. & spellnum==spellnum[_n-1]
	replace tier_code=tier_code[_n-1] if tier_code==. & spellnum==spellnum[_n-1]

	gsort id -date
	replace weekly_ben_amt=weekly_ben_amt[_n-1] if weekly_ben_amt==. & spellnum==spellnum[_n-1]
	replace max_ben_amt=max_ben_amt[_n-1] if max_ben_amt==. & spellnum==spellnum[_n-1]
	replace tier_code=tier_code[_n-1] if tier_code==. & spellnum==spellnum[_n-1]

	save only_2006`x'.dta, replace
}
clear all
use all_pay_data_clean4.dta
append using all_pay_data_clean0.dta
append using all_pay_data_clean1.dta
append using all_pay_data_clean2.dta
append using all_pay_data_clean3.dta
compress
gen in2006=0
append using only_20060.dta
append using only_20061.dta
append using only_20062.dta
append using only_20063.dta
append using only_20064.dta
replace in2006=1 if in2006==.
drop user_tag 

cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"
compress
save all_pay_data_clean, replace

***********************************

** Figure out max and min weekly benefit amounts over time
sort id date
drop if id==id[_n-1]

*** Drop rare payment amounts ***
gen year = year(date)
gen month = month(date)
gen day = day(date)
egen test = count(weekly_ben_amt), by(year month day weekly_ben_amt)
drop if test<5


egen max_ben = max(weekly_ben_amt), by(year month day)
egen min_ben = min(weekly_ben_amt), by(year month day)
egen tag = tag(year month day)
gen period = year + (month-1)/12 + (day-1)/365 if tag==1
label var max_ben "Maximum Weekly Benefits"
label var min_ben "Minimum Weekly Benefits"

sort year month day
twoway (line min_ben date)(line max_ben date, yaxis(2))

collapse max_ben min_ben, by(year month day date)

replace min_ben = min_ben[_n-1]+1 if max_ben>max_ben[_n-1] & min_ben==min_ben[_n-1]
replace min_ben = min_ben[_n-1] if min_ben==min_ben[_n-1]-1

twoway (line min_ben date)(line max_ben date, yaxis(2))

compress
save min_max_weekly_data, replace

**************************************

clear all
use all_pay_data_clean
*** Of those that didn't have 0 payment and weren't matched that week approx 55% are in 2006. Why? ***

*** First Week is Often Missing ***
*** Mean Eearned Amt is  406.8561 if there is earned amount.
*** Approx 14% of Obs have Earned Income


egen totalearnedinc=sum(earned_inc_amt), by(id)
egen idtag=tag(id)
egen numweeks=count(id), by(id)
gen haspay=(earned_inc_amt>0) 
egen sumhaspay=sum(haspay), by(id)


*** The Average UI Recipient Earns $2200 in non_UI income over 5 years and $11000 in UI Payment *** 

*** Of those that earn more than 0, the average earning is $3288 ***

*** Median numweeks is 27 and Mean is 39 ***

*** Total Texas LF is about 12 million
*** Unique ID's in Data are: 2365949
*** Approx 19% of LF interacted with the UI System
*** Approx 33% of those that recieved UI recieved no earned income while filing for UI

*** fraction retro *** 
compress

save ui_and_actual.dta, replace
