clear all

******************************************************
******Google Placebos
clear all
cap use "C:\Users\Scott\Dropbox\Texas Job Search - New\Google_Data\all_aux_terms_national_daily.dta"
cap use "C:\Users\Scott Baker\Dropbox\Texas Job Search - New\Google_Data\all_aux_terms_national_daily.dta"
cap use "~/Dropbox/Texas_Job_Search_New/Google_Data/all_aux_terms_national_daily.dta"
gen date = mdy(month, day, year)
gen dow = dow(date)

tab dow, gen(dowfe)

gen lbenefits = log(searchBenefits)
gen lunemp = log(searchUnemp)
gen lunemp_emp = log(searchUnemp_Emp)

sum lbenefits
gen lbenefits_sd = lbenefits/r(sd)
sum lunemp
gen lunemp_sd = lunemp/r(sd)
sum lunemp_emp
gen lunemp_emp_sd = lunemp_emp/r(sd)
  
***Thanksgiving
gen hotg1=0 
gen hotg2=0 
gen hotg3=0 
gen hotg4=0

replace hotg1=1 if year==2005 & month==11 & day==24
replace hotg2=1 if year==2005 & month==11 & day==25
replace hotg3=1 if year==2005 & month==11 & day==26
replace hotg4=1 if year==2005 & month==11 & day==27
replace hotg1=1 if year==2006 & month==11 & day==23
replace hotg2=1 if year==2006 & month==11 & day==24
replace hotg3=1 if year==2006 & month==11 & day==25
replace hotg4=1 if year==2006 & month==11 & day==26
replace hotg1=1 if year==2007 & month==11 & day==22
replace hotg2=1 if year==2007 & month==11 & day==23
replace hotg3=1 if year==2007 & month==11 & day==24
replace hotg4=1 if year==2007 & month==11 & day==25
replace hotg1=1 if year==2008 & month==11 & day==27
replace hotg2=1 if year==2008 & month==11 & day==28
replace hotg3=1 if year==2008 & month==11 & day==29
replace hotg4=1 if year==2008 & month==11 & day==30
replace hotg1=1 if year==2009 & month==11 & day==26
replace hotg2=1 if year==2009 & month==11 & day==27
replace hotg3=1 if year==2009 & month==11 & day==28
replace hotg4=1 if year==2009 & month==11 & day==29
replace hotg1=1 if year==2010 & month==11 & day==25
replace hotg2=1 if year==2010 & month==11 & day==26
replace hotg3=1 if year==2010 & month==11 & day==27
replace hotg4=1 if year==2010 & month==11 & day==28

** Memorial day
gen homem3=0
gen homem2=0
gen homem1=0

replace homem3=1 if year==2005 & month==5 & day==30
replace homem2=1 if year==2005 & month==5 & day==29
replace homem1=1 if year==2005 & month==5 & day==28

** Christmas
gen hocmas1=0
gen hocmas2=0
replace hocmas1=1 if month==12&day==24
replace hocmas2=1 if month==12&day==25
** New years
gen hony1=0
gen hony2=0
replace hony1=1 if month==1&day==1
replace hony2=1 if month==12&day==31
** Presidents day
gen hopd1=0
gen hopd2=0
gen hopd3=0

replace hopd1=1 if year==2005&month==2&day==21
replace hopd2=1 if year==2005&month==2&day==20
replace hopd3=1 if year==2005&month==2&day==19
replace hopd1=1 if year==2006&month==2&day==20
replace hopd2=1 if year==2006&month==2&day==19
replace hopd3=1 if year==2006&month==2&day==18
replace hopd1=1 if year==2007&month==2&day==19
replace hopd2=1 if year==2007&month==2&day==18
replace hopd3=1 if year==2007&month==2&day==17
replace hopd1=1 if year==2008&month==2&day==18
replace hopd2=1 if year==2008&month==2&day==17
replace hopd3=1 if year==2008&month==2&day==16
replace hopd1=1 if year==2009&month==2&day==16
replace hopd2=1 if year==2009&month==2&day==15
replace hopd3=1 if year==2009&month==2&day==14
replace hopd1=1 if year==2010&month==2&day==15
replace hopd2=1 if year==2010&month==2&day==14
replace hopd3=1 if year==2010&month==2&day==13

** MLK
gen homlk1=0
gen homlk2=0
gen homlk3=0

replace homlk1=1 if year==2005&month==1&day==17
replace homlk2=1 if year==2005&month==1&day==16
replace homlk3=1 if year==2005&month==1&day==15
replace homlk1=1 if year==2006&month==1&day==16
replace homlk2=1 if year==2006&month==1&day==15
replace homlk3=1 if year==2006&month==1&day==14
replace homlk1=1 if year==2007&month==1&day==15
replace homlk2=1 if year==2007&month==1&day==14
replace homlk3=1 if year==2007&month==1&day==13
replace homlk1=1 if year==2008&month==1&day==21
replace homlk2=1 if year==2008&month==1&day==20
replace homlk3=1 if year==2008&month==1&day==19
replace homlk1=1 if year==2009&month==1&day==19
replace homlk2=1 if year==2009&month==1&day==18
replace homlk3=1 if year==2009&month==1&day==17
replace homlk1=1 if year==2010&month==1&day==17
replace homlk2=1 if year==2010&month==1&day==16
replace homlk3=1 if year==2010&month==1&day==15

** Indep day
gen hoid=0
replace hoid=1 if month==7&day==4
** Labor day
gen holab1=0
gen holab2=0
gen holab3=0

replace holab1=1 if year==2005&month==9&day==5
replace holab2=1 if year==2005&month==9&day==4
replace holab3=1 if year==2005&month==9&day==3
replace holab1=1 if year==2006&month==9&day==4
replace holab2=1 if year==2006&month==9&day==3
replace holab3=1 if year==2006&month==9&day==2
replace holab1=1 if year==2007&month==9&day==3
replace holab2=1 if year==2007&month==9&day==2
replace holab3=1 if year==2007&month==9&day==1
replace holab1=1 if year==2008&month==9&day==1
replace holab2=1 if year==2008&month==8&day==31
replace holab3=1 if year==2008&month==9&day==30
replace holab1=1 if year==2009&month==9&day==7
replace holab2=1 if year==2009&month==9&day==6
replace holab3=1 if year==2009&month==9&day==5
replace holab1=1 if year==2010&month==9&day==2
replace holab2=1 if year==2010&month==9&day==1
replace holab3=1 if year==2010&month==8&day==31

** 
gen holiday= hotg1+hotg2+ hotg3+ hotg4+ homem3+ homem2+ homem1+ hocmas1+ hocmas2+ hony1+ hony2+ hopd1+ hopd2+ hopd3+ homlk1+homlk2+ homlk3+ hoid+ holab1+ holab2+ holab3

gen weekend = dow==0|dow==6

gen year_month = (year + (month-1)/12)*12
tab year_month, gen(ym)

label var weekend "Weekend"
label var holiday "Holiday"
label var dowfe1 "Sunday"
label var dowfe2 "Monday"
label var dowfe3 "Tuesday"
label var dowfe4 "Wednesday"
label var dowfe5 "Thursday"
label var dowfe6 "Friday"
label var dowfe7 "Saturday"


cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"

areg lbenefits weekend holiday, cluster(year_month) absorb(year_month)
outreg2 using holiday_dow_placebo, tex(landscape pr frag) keep(holiday weekend) label addtext( Year FE, YES, Month FE, YES, State FE, YES) ctitle("Google Benefits") nocons nor2 replace

areg lbenefits dowfe2-dowfe7 holiday, cluster(year_month) absorb(year_month)
outreg2 using holiday_dow_placebo, tex(landscape pr frag) keep(dowfe2 dowfe3 dowfe4 dowfe5 dowfe6 dowfe7 holiday) label addtext( Year FE, YES, Month FE, YES, State FE, YES) ctitle("Google Benefits") nocons nor2

areg lunemp weekend holiday, cluster(year_month) absorb(year_month)
outreg2 using holiday_dow_placebo, tex(landscape pr frag) keep(holiday weekend) label addtext( Year FE, YES, Month FE, YES, State FE, YES) ctitle("Google Unemp") nocons nor2

areg lunemp dowfe2-dowfe7 holiday, cluster(year_month) absorb(year_month)
outreg2 using holiday_dow_placebo, tex(landscape pr frag) keep(dowfe2 dowfe3 dowfe4 dowfe5 dowfe6 dowfe7 holiday) label addtext( Year FE, YES, Month FE, YES, State FE, YES) ctitle("Google Unemp") nocons nor2

areg lunemp_emp weekend holiday, cluster(year_month) absorb(year_month)
outreg2 using holiday_dow_placebo, tex(landscape pr frag) keep(holiday weekend) label addtext( Year FE, YES, Month FE, YES, State FE, YES) ctitle("Google Unemp or Emp") nocons nor2

areg lunemp_emp dowfe2-dowfe7 holiday, cluster(year_month) absorb(year_month)
outreg2 using holiday_dow_placebo, tex(landscape pr frag) keep(dowfe2 dowfe3 dowfe4 dowfe5 dowfe6 dowfe7 holiday) label addtext( Year FE, YES, Month FE, YES, State FE, YES) ctitle("Google Unemp/Emp") nocons nor2


******************************************************
***Google Columns:
clear all
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas Job Search - Old\Google Trends\Master Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas Job Search - Old\Google Trends\Master Data"
use dailysearchandclaimsfe.dta

encode state, gen(state_code)
tsset state_code date

**Here remake everything to std dev 1
sum lsearch
gen lsearch_sd = lsearch/r(sd)
sum search
gen search_sd = search/r(sd)
rename aholiday holiday

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"

areg lsearch weekend holiday mfe*, cluster(seasonstate) absorb(seasonstate)
outreg2 using holiday_dow, tex(landscape pr frag) keep(holiday weekend) label addtext( Year FE, NO, Month FE, YES, State FE, YES) ctitle("Google Job Search") nocons nor2 replace

areg lsearch dowfe2-dowfe7 holiday mfe*, cluster(seasonstate) absorb(seasonstate)
outreg2 using holiday_dow, tex(landscape pr frag) keep(dowfe2 dowfe3 dowfe4 dowfe5 dowfe6 dowfe7 holiday) label addtext( Year FE, NO, Month FE, YES, State FE, YES) ctitle("Google Job Search") nocons nor2

clear

/*
log:  -.21; -.147
*/
******************************************************
****ATUS Columns:
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\ATUS"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\ATUS"

use ATUS_state

**Here remake everything to std dev 1
sum AllJobSearchTime
gen AllJobSearchTime_sd = AllJobSearchTime/r(sd)
gen lAllJobSearchTime = log(AllJobSearchTime+.01)
sum lAllJobSearchTime
gen lAllJobSearchTime_sd = lAllJobSearchTime/r(sd)

label var dw2 "Monday"
label var dw3 "Tuesday"
label var dw4 "Wednesday"
label var dw5 "Thursday"
label var dw6 "Friday"
label var dw7 "Saturday"

forvalues x = 1/7 {
	rename dw`x' dowfe`x'
}

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"

rename trholiday holiday
cap tab year, gen(yy)
cap tab month, gen(mm)

areg AllJobSearchTime_sd weekend holiday yy* mm*, ab(state)
outreg2 using holiday_dow, tex(landscape pr frag) keep(weekend holiday) label addtext(Year FE, YES, Month FE, YES, State FE, YES) ctitle("ATUS Job Search") nocons nor2

areg AllJobSearchTime_sd dowfe2-dowfe7 holiday yy* mm*, ab(state)
outreg2 using holiday_dow,  tex(landscape pr frag) keep(dowfe2 dowfe3 dowfe4 dowfe5 dowfe6 dowfe7 holiday) label addtext(Year FE, YES, Month FE, YES, State FE, YES) ctitle("ATUS Job Search") nocons nor2

clear

/*
reg: -1.7; -1
reg std: -.089; -.052

log = -.053; -.028
log std = -.1; -.057
*/
******************************************************
***ComScore Columns:

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas Job Search - Old\Google Trends\Master Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas Job Search - Old\Google Trends\Master Data"

use comscorestateday

**Here remake everything to std dev 1
sum totaljobsearchtime
gen totaljobsearchtime_sd = totaljobsearchtime/r(sd)

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables\Tables"

areg totaljobsearchtime weekend holiday mfe*, ab(state)
outreg2 using holiday_dow, tex(landscape pr frag) keep(weekend holiday) label addtext(Year FE, YES, Month FE, YES, State FE, YES) ctitle("comScore Job Search") nocons nor2

areg totaljobsearchtime holiday dowfe2-dowfe7 mfe*, ab(state)
outreg2 using holiday_dow,  tex(landscape pr frag) keep(dowfe2 dowfe3 dowfe4 dowfe5 dowfe6 dowfe7 holiday) label addtext(Year FE, YES, Month FE, YES, State FE, YES) ctitle("comScore Job Search") nocons nor2

clear

