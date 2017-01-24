clear all
cap use "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/TX_Weeks_Left_Data.dta"
cap use "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data\TX_Weeks_Left_Data.dta"
cap use "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\TX_Weeks_Left_Data.dta"
format date %td
drop if date<td(01jan2006)
keep if mod(date,7)==1

gen tier1_alt = tier1
gen tier2_alt = tier2 + tier2extra
gen tier3_alt = tier3
gen tier4_alt = tier4
gen eb_alt = eb

***Start is when the current legislation expires
***Last is when new legislation takes effect

**** Hole 1 ****
gen hole1_start = td(31dec2009)
gen hole1_last = td(19dec2009)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole1_start <= date & date <= hole1_last
}

**** Hole 2 ****
gen hole2_start = td(28feb2010)
gen hole2_last = td(2mar2010)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole2_start <= date & date <= hole2_last
}

*** Hole 3 ***
gen hole3_start = td(05apr2010)
gen hole3_last = td(15apr2010)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole3_start <= date &  date <= hole3_last
}

*** Hole 4 ***
gen hole4_start = td(02jun2010)
gen hole4_last = td(22jul2010)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole4_start <= date & hole4_last >= date
}

*** Hole 5 ***
gen hole5_start = td(30nov2010)
gen hole5_last = td(17dec2010)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole5_start <= date & hole5_last >= date
}

*** Hole 6 ***
gen hole6_start = td(03jan2012)
gen hole6_last = td(23dec2011)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole6_start <= date & hole6_last >= date
}

*** Hole 7 ***
gen hole7_start = td(06mar2012)
gen hole7_last = td(22feb2012)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole7_start <= date & hole7_last >= date
}

*** Hole 8 ***
gen hole8_start = td(02jan2013)
gen hole8_last = td(02jan2013)

foreach var of varlist tier1_alt - tier4_alt {
	replace `var' = 0 if hole8_start <= date & hole8_last >= date
}

***** For EB *****
foreach var in hole1 hole2 hole3 hole4 hole5 hole6 hole7 hole8 {
	replace eb_alt = 0 if date>=(`var'_start + 7) & date<=`var'_last 
}
egen min_tier1_13 = min(date) if tier1==13
egen min_tier1_20 = min(date) if tier1==20
egen min_tier2 = min(date) if tier2==13
egen min_tier3 = min(date) if tier3==13
egen min_tier4 = min(date) if tier4==6
egen min_eb_13 = min(date) if eb==13
egen min_eb_20 = min(date) if eb==20

foreach var of varlist min_*{
	di `var'
	egen `var'2 = max(`var')
	drop `var' 
	rename `var'2 `var'
}

cap save "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/TX_Weeks_Left_Data_Alt.dta", replace
cap save "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\TX_Weeks_Left_Data_Alt.dta", replace
cap save "C:\Users\sbaker2\Dropbox\Texas Job Search - New\Texas_UI_Data\TX_Weeks_Left_Data_Alt.dta", replace

