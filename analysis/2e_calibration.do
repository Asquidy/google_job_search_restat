clear all

cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New"
cap cd "C:\Users\sbaker2\Dropbox\Texas Job Search - New"

use Texas_UI_Data/working_data_regressions

****Here is the regression we use
nl (ljob_search = 1 + {xb:holiday msas1-msas17 msasdate1-msasdate17 ymfe1-ymfe62 all_extensions_and_exp_4week} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed 1 xb_scnot_on_ui 1) cluster(msa)
****************************
***Make coefficients here
local coeffs "all_extensions_and_exp_4week num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed ymfe1 ymfe2 ymfe3 ymfe4 ymfe5 ymfe6 ymfe7 ymfe8 ymfe9 ymfe10 ymfe11 ymfe12 ymfe13 ymfe14 ymfe15 ymfe16 ymfe17 ymfe18 ymfe19 ymfe20 ymfe21 ymfe22 ymfe23 ymfe24 ymfe25 ymfe26 ymfe27 ymfe28 ymfe29 ymfe30 ymfe31 ymfe32 ymfe33 ymfe34 ymfe35 ymfe36 ymfe37 ymfe38 ymfe39 ymfe40 ymfe41 ymfe42 ymfe43 ymfe44 ymfe45 ymfe46 ymfe47 ymfe48 ymfe49 ymfe50 ymfe51 ymfe52 ymfe53 ymfe54 ymfe55 ymfe56 ymfe57 ymfe58 ymfe59 ymfe60 ymfe61 ymfe62 msas1 msas2 msas3 msas4 msas5 msas6 msas7 msas8 msas9 msas10 msas11 msas12 msas13 msas14 msas15 msas16 msas17 msasdate1 msasdate2 msasdate3 msasdate4 msasdate5 msasdate6 msasdate7 msasdate8 msasdate9 msasdate10 msasdate11 msasdate12 msasdate13 msasdate14 msasdate15 msasdate16 msasdate17"

foreach coeff of local coeffs {
	gen c_`coeff' = _b[/xb_`coeff']
}

***test just houston
*keep if msa_code==6
***

keep c_* date labor_force employment not_on_ui msa_code num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 sclabor_force scnot_on_ui scemployed population ljob_search

*** Calculate LF weighted coefficients ***
egen tx_labor_force = sum(labor_force), by(date)
egen tx_not_on_ui = sum(not_on_ui), by(date)
egen tx_employment = sum(employment), by(date)

gen msa_weight = labor_force/tx_labor_force

forvalues i=1/17{
	replace c_msas`i' = . if msa_code!=`i'
	replace c_msas`i' = c_msas`i'*msa_weight if msa_code==`i'
	replace c_msasdate`i' = . if msa_code!=`i'
	replace c_msasdate`i' = c_msasdate`i'*msa_weight if msa_code==`i'
}

collapse ljob_search c_all_extensions_and_exp_4week c_num_ui_0_10_weeks c_num_ui_10_20_weeks c_num_ui_20_30_weeks c_greater_than_30 c_scnot_on_ui c_scemployed c_ymfe* c_msasdate* c_msas1-c_msas17 (sum) num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 labor_force employment not_on_ui sclabor_force scnot_on_ui scemployed, by(date)

egen c_msa_avg=rowtotal(c_msas1 - c_msas17)
egen c_msadate_avg = rowtotal(c_msasdate*)

rename date clean_date

merge 1:1 clean_date using Texas_UI_Data/announce_affected_amt
drop if _merge!=3
drop _merge

order announce* year_month
rename id total_on_ui
rename change_ui change_not_ui_to_ui

compress
save Texas_UI_Data/calibration_data, replace

cap use Texas_UI_Data/calibration_data

**Converting back to the scaled pops
foreach var of varlist wl* change_* gr* total_on_ui {
	replace `var' = `var'/1000
}


replace year_month = 62 if year_month==63
gen baseline = 0
forvalues x=1/80 {
	cap replace baseline = c_msa_avg + c_msadate_avg*clean_date + c_ymfe`x' + log(c_num_ui_0_10_weeks*wl010 +  c_num_ui_10_20_weeks*wl1020 +c_num_ui_20_30_weeks*wl2030 +c_greater_than_30*gr30 + c_scnot_on_ui*scnot_on_ui + c_scemployed*scemployed) if year_month==`x'
}


gen no_legislation = 0
forvalues x=1/80 {
	cap replace no_legislation = c_msa_avg + c_msadate_avg*clean_date + c_ymfe`x' + log(c_num_ui_0_10_weeks*(wl010+change_0to20+change_0to30+change_0togr) +  c_num_ui_10_20_weeks*(wl1020-change_not_ui_to_ui+change_10to30+change_10togr-change_0to20) +c_num_ui_20_30_weeks*(wl2030+change_20togr-change_10to30-change_0to30) +c_greater_than_30*(gr30-change_20togr-change_10togr-change_0togr) + c_scnot_on_ui*(scnot_on_ui+change_not_ui_to_ui) + c_scemployed*scemployed) if year_month==`x'
}


gen change_in_search_due_to_leg = baseline-no_legislation

order change_in_search_due_to_leg baseline no_legislation change*

gen expansion = regexm(announce_name, "min")
order expansion
sort expansion

gen c_sc_on_ui = 0.616
order announce_name c_all_extensions_and_exp_4week change_not_ui_to_ui c_scnot_on_ui c_sc_on_ui change_0to20 c_num_ui_0_10_weeks c_num_ui_10_20_weeks 

edit
keep if all_extensions_and_exp_1week==1 
egen tot_lf = sum(labor_force), by(date)
egen tot_unemp = sum(unemployed), by(date)
egen tot_total_on_ui = sum(total_on_ui), by(date)

format tot_lf tot_unemp tot_total_on_ui  %10.0g
tab tot_lf if tier1_13_1week==1
tab tot_lf if tier2_1week==1
tab tot_lf if tier2extra_1week==1
tab tot_lf if tier3_1week==1
tab tot_lf if tier4_1week==1
tab tot_lf if hole1_last_1week==1
tab tot_lf if hole2_last_1week==1
tab tot_lf if hole3_last_1week==1
tab tot_lf if hole4_last_1week==1
tab tot_lf if hole5_last_1week==1
tab tot_lf if hole6_last_1week==1

