*** Generate correlations between search measures in ATUS: Table A3 *** 
clear all
cd "~/Dropbox/Texas_Job_Search_New/restat_data/ATUS/"
set mem 1000m
set more off

use AllCPSATUS.dta

*drop  gemetsta-pecohab
drop if teage>65
drop if teage<20

nsplit tucaseid, digits(4 2 8)

sort tucaseid
drop if tucaseid==tucaseid[_n-1]

**Limit households in same way as in Krueger and Mueller (2010)
drop if teage<20 | teage > 65

**Generate labor force status
gen unemp = 0
replace unemp = 1 if telfs==3|telfs==4
gen emp = 0
replace emp = 1 if telfs==1|telfs==2
gen nilf =0
replace nilf = 1 if telfs==5

**Generate weekend
gen weekend = tudiaryday==1|tudiaryday==7

**Generate total job search time
gen AllJobSearchTimeWTravel = t050403+ t050404 +t050405+ t050481+ t050499+  t180589 
gen AllJobSearchTime = t050403+ t050404 +t050405+ t050481+ t050499

***Average job search (min/day)
sum AllJobSearchTimeWTravel if emp==1
sum AllJobSearchTimeWTravel if unemp==1
sum AllJobSearchTimeWTravel if nilf==1

sum AllJobSearchTimeWTravel if trholiday==1
sum AllJobSearchTimeWTravel if trholiday==0

sum AllJobSearchTimeWTravel if weekend==1
sum AllJobSearchTimeWTravel if weekend==0

***Average job search excluding travel (min/day)
sum AllJobSearchTime if emp==1
sum AllJobSearchTime if unemp==1
sum AllJobSearchTime if nilf==1

sum AllJobSearchTime if trholiday==1
sum AllJobSearchTime if trholiday==0

sum AllJobSearchTime if weekend==1
sum AllJobSearchTime if weekend==0

**Generate job search indicator
gen JobSearchIndicator = AllJobSearchTime>0

***Frac Any Job Search
sum JobSearchIndicator if emp==1
sum JobSearchIndicator if unemp==1
sum JobSearchIndicator if nilf==1

sum JobSearchIndicator if trholiday==1
sum JobSearchIndicator if trholiday==0

sum JobSearchIndicator if weekend==1
sum JobSearchIndicator if weekend==0

gen JobSearchWTravelIndicator = AllJobSearchTimeWTravel>0

***Job search (min/day) conditional on any job search
sum AllJobSearchTimeWTravel if emp==1 & JobSearchWTravelIndicator==1
sum AllJobSearchTimeWTravel if unemp==1 & JobSearchWTravelIndicator==1
sum AllJobSearchTimeWTravel if nilf==1  & JobSearchWTravelIndicator==1

sum AllJobSearchTimeWTravel if trholiday==1 & JobSearchWTravelIndicator==1
sum AllJobSearchTimeWTravel if trholiday==0 & JobSearchWTravelIndicator==1

sum AllJobSearchTimeWTravel if weekend==1 & JobSearchWTravelIndicator==1
sum AllJobSearchTimeWTravel if weekend==0 & JobSearchWTravelIndicator==1