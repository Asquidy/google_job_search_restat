set more off

clear all
infix str id 1-9 dob_year 10-13 dob_month 15-16 dob_day 18-19 str gender 20 using stanfdobgen.txt
cap destring, replace
format id %11.0g
compress
save day_of_birth_data, replace
clear all

infix str id 1-9 base_year 10-13 base_month 15-16 base_day 18-19 wage_year 20-23 wage_quarter 24 wage 25-31 using stanf0611basewage.txt
cap destring, replace
format id %11.0g
compress
save base_period_wage_data, replace
clear all

infix str id 1-9 retro_year 10-13 retro_month 15-16 retro_day 18-19 num_retro 20-28 using stanf0611retroactive.txt
cap destring, replace
format id %11.0g
compress
gen date=mdy(retro_month,retro_day,retro_year)
duplicates tag date id, gen(duptag)
drop if duptag==1
drop duptag
save retroactive_payment_data, replace
clear all

/*Old employment files
infix str id 1-9 last_payment_year 10-13 last_payment_month 15-16 last_payment_day 18-19 emp_data_year1 20-23 emp_data_quarter1 24  emp_data_income1 25-31 emp_data_year2 32-35 emp_data_quarter2 36  emp_data_income2 37-43 emp_data_year3 44-47 emp_data_quarter3 48  emp_data_income3 49-55 emp_data_year4 56-59 emp_data_quarter4 60  emp_data_income4 61-67 emp_data_year5 68-71 emp_data_quarter5 72  emp_data_income5 73-79 emp_data_year6 80-83 emp_data_quarter6 84  emp_data_income6 85-91 emp_data_year7 92-95 emp_data_quarter7 96  emp_data_income7 97-103 emp_data_year8 104-107 emp_data_quarter8 108  emp_data_income8 109-115 emp_data_year9 116-119 emp_data_quarter9 120  emp_data_income9 121-127 emp_data_year10 128-131 emp_data_quarter10 132  emp_data_income10 133-139 emp_data_year11 140-143 emp_data_quarter11 144  emp_data_income11 145-151 emp_data_year12 152-155 emp_data_quarter12 156  emp_data_income12 157-163 emp_data_year13 164-167 emp_data_quarter13 168  emp_data_income13 169-175 emp_data_year14 176-179 emp_data_quarter14 180  emp_data_income14 181-187 emp_data_year15 188-191 emp_data_quarter15 192  emp_data_income15 193-199 emp_data_year16 200-203 emp_data_quarter16 204  emp_data_income16 205-211 emp_data_year17 212-215 emp_data_quarter17 216  emp_data_income17 217-223 emp_data_year18 224-227 emp_data_quarter18 228  emp_data_income18 229-235 emp_data_year19 236-239 emp_data_quarter19 240  emp_data_income19 241-247 emp_data_year20 248-251 emp_data_quarter20 252  emp_data_income20 253-259 emp_data_year21 260-263 emp_data_quarter21 264  emp_data_income21 265-271 emp_data_year22 272-275 emp_data_quarter22 276  emp_data_income22 277-283 emp_data_year23 284-287 emp_data_quarter23 288  emp_data_income23 289-295 emp_data_year24 296-299 emp_data_quarter24 300  emp_data_income24 301-307 emp_data_year25 308-311 emp_data_quarter25 312  emp_data_income25 313-319 emp_data_year26 320-323 emp_data_quarter26 324  emp_data_income26 325-331 emp_data_year27 332-335 emp_data_quarter27 336  emp_data_income27 337-343  using stanf0611empr.txt
cap destring, replace
format id %11.0g
gen date = mdy(last_payment_month , last_payment_d, last_payment_y)
sort id date
drop if id==id[_n-1] & date==date[_n-1]
compress
save post_benefit_employment_data, replace

gen last_payment_quarter = quarter(date)
gen paid_last_quarter_or_next = (last_payment_quarter==emp_data_quarter1 & last_payment_year ==emp_data_year1 & emp_data_income1!=.)|(last_payment_quarter==emp_data_quarter2 & last_payment_year ==emp_data_year2 & emp_data_income2!=.)|(last_payment_quarter==emp_data_quarter1-1 & last_payment_year ==emp_data_year1 & emp_data_income1!=.)|(last_payment_quarter==4 & emp_data_quarter1==1 & last_payment_year ==emp_data_year1-1 & emp_data_income1!=.)
keep id date paid_last_quarter_or_next
save post_benefit_employment_data_small
clear all
*/

infix str id 1-9 ui_year 10-13 ui_month 15-16 ui_day 18-19 str tier 20-22 str city 23-42 county_fips 43-45 zip 46-50 weekly_ben_amt 51-53 max_ben_amt 54-58 using stanf0611pay1.txt
cap destring, replace
format id %11.0g
encode city, gen(city_code)
encode tier, gen(tier_code)
drop city tier
compress
save ui_pay_data1, replace
clear all

infix str id 1-9 ui_year 10-13 ui_month 15-16 ui_day 18-19 str tier 20-22 str city 23-42 county_fips 43-45 zip 46-50 weekly_ben_amt 51-53 max_ben_amt 54-58 using stanf0611pay2.txt
cap destring, replace
format id %11.0g
encode city, gen(city_code)
encode tier, gen(tier_code)
drop city tier
compress
save ui_pay_data2, replace
clear all

infix str id 1-9 ui_year 10-13 ui_month 15-16 ui_day 18-19 earned_inc_amt 20-24 actual_ui_payment 25-29 using stanford0611pay-additional.txt
cap destring, replace
format id %11.0g
compress
save ui_actual_payment_data, replace
clear all

infix str id 1-9 ui_year 10-13 ui_month 15-16 ui_day 18-19 str tier 20-22 str city 23-42 county_fips 43-45 zip 46-50 weekly_ben_amt 51-53 max_ben_amt 54-58 using stanfpaymentsupp.txt
cap destring, replace
format id %11.0g
encode city, gen(city_code)
encode tier, gen(tier_code)
drop city tier
compress
save ui_pay_supplemental, replace
clear all

infix str id 1-9 last_payment_year 10-13 last_payment_month 15-16 last_payment_day 18-19 emp_data_year1 20-23 emp_data_quarter1 24  emp_data_income1 25-31 emp_data_year2 32-35 emp_data_quarter2 36  emp_data_income2 37-43 emp_data_year3 44-47 emp_data_quarter3 48  emp_data_income3 49-55 emp_data_year4 56-59 emp_data_quarter4 60  emp_data_income4 61-67 emp_data_year5 68-71 emp_data_quarter5 72  emp_data_income5 73-79 emp_data_year6 80-83 emp_data_quarter6 84  emp_data_income6 85-91 emp_data_year7 92-95 emp_data_quarter7 96  emp_data_income7 97-103 emp_data_year8 104-107 emp_data_quarter8 108  emp_data_income8 109-115 emp_data_year9 116-119 emp_data_quarter9 120  emp_data_income9 121-127 emp_data_year10 128-131 emp_data_quarter10 132  emp_data_income10 133-139 emp_data_year11 140-143 emp_data_quarter11 144  emp_data_income11 145-151 emp_data_year12 152-155 emp_data_quarter12 156  emp_data_income12 157-163 emp_data_year13 164-167 emp_data_quarter13 168  emp_data_income13 169-175 emp_data_year14 176-179 emp_data_quarter14 180  emp_data_income14 181-187 emp_data_year15 188-191 emp_data_quarter15 192  emp_data_income15 193-199 emp_data_year16 200-203 emp_data_quarter16 204  emp_data_income16 205-211 emp_data_year17 212-215 emp_data_quarter17 216  emp_data_income17 217-223 emp_data_year18 224-227 emp_data_quarter18 228  emp_data_income18 229-235 emp_data_year19 236-239 emp_data_quarter19 240  emp_data_income19 241-247 emp_data_year20 248-251 emp_data_quarter20 252  emp_data_income20 253-259 emp_data_year21 260-263 emp_data_quarter21 264  emp_data_income21 265-271 emp_data_year22 272-275 emp_data_quarter22 276  emp_data_income22 277-283 emp_data_year23 284-287 emp_data_quarter23 288  emp_data_income23 289-295 emp_data_year24 296-299 emp_data_quarter24 300  emp_data_income24 301-307 emp_data_year25 308-311 emp_data_quarter25 312  emp_data_income25 313-319 emp_data_year26 320-323 emp_data_quarter26 324  emp_data_income26 325-331 emp_data_year27 332-335 emp_data_quarter27 336  emp_data_income27 337-343  using stanf0611empr2.txt
cap destring, replace
format id %11.0g
gen date = mdy(last_payment_month , last_payment_d, last_payment_y)
sort id date
drop if id==id[_n-1] & date==date[_n-1]
compress
save post_benefit_employment_data, replace

gen last_payment_quarter = quarter(date)
gen paid_last_quarter_or_next = (last_payment_quarter==emp_data_quarter1 & last_payment_year ==emp_data_year1 & emp_data_income1!=.)|(last_payment_quarter==emp_data_quarter2 & last_payment_year ==emp_data_year2 & emp_data_income2!=.)|(last_payment_quarter==emp_data_quarter1-1 & last_payment_year ==emp_data_year1 & emp_data_income1!=.)|(last_payment_quarter==4 & emp_data_quarter1==1 & last_payment_year ==emp_data_year1-1 & emp_data_income1!=.)
keep id date paid_last_quarter_or_next
save post_benefit_employment_data_small
clear all

use ui_pay_data1
append using ui_pay_data2
append using ui_pay_supplemental
compress
save all_pay_data, replace
clear all
