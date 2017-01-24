clear all
set mem 2000m
set more off
cap cd "C:\Users\Public\Documents\comscorefiles\"
cap cd "C:\Users\Scott\Desktop\Comscore"

forvalues y = 1/9{
*local y=1
forvalues x=1/24{

*forvalues x = 1/24 {
clear
capture confirm file `y'splitfile`x'.csv
di _rc
if !_rc{
insheet using `y'splitfile`x'.csv
cap drop site_session_id pages_viewed connection_speed country_of_origin
cap drop if substr(domain_name,-4,4)==".exe"
cap drop if substr(domain_name,-4,4)==".EXE"
sort machine_id event_date event_time

cap drop jobsite
gen jobsite=0
replace jobsite = 1 if(regexm(domain_name, "([\-]*[0-9]*[ a-zA-Z]*)(job)|(career)|(work)|(jjj)|(hiring)([\-]*[0-9]*[ a-zA-Z]*)"))
replace jobsite = 1 if domain_name=="linkedin.com"|domain_name=="monster.com"| domain_name=="careerbuilder.com"| domain_name=="hotjobs.com"|domain_name=="linkstaffing"|domain_name=="employmentsolutions"
replace jobsite = 0 if(regexm(domain_name, "([\-]*[0-9]*[ a-zA-Z]*)(tit)|(network)|(blowjob)|(porn)|(xxx)|(videos)([\-]*[0-9]*[ a-zA-Z]*)"))
replace jobsite = 0 if(regexm(domain_name, "([\-]*[0-9]*[ a-zA-Z]*)(teen)|(fantasy)|(bathandbody)|(howstuff)|(sesame)|(marketworks)([\-]*[0-9]*[ a-zA-Z]*)"))
replace jobsite = 0 if(regexm(domain_name, "([\-]*[0-9]*[ a-zA-Z]*)(handjob)|(fantasy)|(bathandbody)|(howstuff)|(sesame)|(marketworks)([\-]*[0-9]*[ a-zA-Z]*)"))
replace jobsite = 0 if(regexm(domain_name, "([\-]*[0-9]*[ a-zA-Z]*)(fireworks)|(intentmediaworks)|(homework)([\-]*[0-9]*[ a-zA-Z]*)"))
**tab domain_name if jobsite==1, sort
**sum jobsite
**egen maxjobsite=max(jobsite), by(machine_id)
**sum maxjobsite

gen googlejobsearch = 0
replace googlejobsearch =1 if (ref_domain_name=="GOOGLE.COM"|ref_domain_name=="google.com") & jobsite==1
replace googlejobsearch=1 if jobsite==1 & googlejobsearch[_n-1]==1&machine_id==machine_id[_n-1]

gen googlecount=0
replace googlecount=1 if ref_domain_name=="google.com"|ref_domain_name=="GOOGLE.COM"

*** job search during year, can imagine a finer grained measure ***
egen jobsearcher = max(jobsite), by(machine_id)



gen totaljobsearchtime =0
replace totaljobsearchtime = duration if jobsite==1
gen totalgoogletime  =0
replace totalgoogletime = duration if domain_name=="google.com"|domain_name=="GOOGLE.COM"
gen totalgooglejobsearchtime=0
replace totalgooglejobsearchtime = duration if googlejobsearch==1

gen hour = hh(clock(event_time,"hms"))

gen temp = 1 if jobsite==1 & hour>6 & hour<14
replace temp=0 if temp==.
egen workhourjobsearch_7_1 = max(temp), by(machine_id)
drop temp

gen temp = 1 if jobsite==1 & hour>8 & hour<17
replace temp=0 if temp==.
egen workhourjobsearch_9_5 = max(temp), by(machine_id)
drop temp

gen temp = 1 if jobsite==1 & hour>9 & hour<16
replace temp=0 if temp==.
egen workhourjobsearch_10_4 = max(temp), by(machine_id)
drop temp

gen temp = duration if jobsite==1 & hour>6 & hour<14
replace temp=0 if temp==.
egen durworkhourjobsearch_7_1 = max(temp), by(machine_id)
drop temp

gen temp = duration if jobsite==1 & hour>8 & hour<17
replace temp=0 if temp==.
egen durworkhourjobsearch_9_5 = max(temp), by(machine_id)
drop temp

gen temp = duration if jobsite==1 & hour>9 & hour<16
replace temp=0 if temp==.
egen durworkhourjobsearch_10_4 = max(temp), by(machine_id)
drop temp

gen count = 1

drop  ref_domain_name domain_name event_time jobsite hour
*collapse hoh_most_education zip_code household_size hoh_oldest_age household_income children racial_background  connection_speed jobsearcher  (max) workhourjobsearch* (sum) durworkhourjobsearch* googlecount googlejobsearch totaljobsearchtime totalgoogletime totalgooglejobsearchtime count, by(machine_id) fast
collapse hoh_most_education zip_code household_size hoh_oldest_age household_income children racial_background (max) workhourjobsearch* jobsearcher (sum) durworkhourjobsearch* googlecount googlejobsearch totaljobsearchtime totalgoogletime totalgooglejobsearchtime count, by(machine_id event_date) fast

compress
save `y'compressed`x',replace
}
}
}

clear
set mem 3000m
use 1compressed1 
forvalues x = 2/24 {
append using 1compressed`x'
}
forvalues y = 2/9 {
forvalues x = 1/24 {
cap append using `y'compressed`x'
}
}


**Here we're going to winsorize to get rid of some crazy values
replace googlecount = 50 if googlecount>50
replace googlejobsearch = 15 if googlejobsearch>15
replace totaljobsearchtime = 180 if totaljobsearchtime>180
replace totalgooglejobsearchtime = 180 if totalgooglejobsearchtime>180
***

compress
save all2007_small, replace
collapse hoh_most_education zip_code household_size hoh_oldest_age household_income children racial_background (max) workhourjobsearch* jobsearcher (sum)durworkhourjobsearch* googlecount googlejobsearch totaljobsearchtime totalgoogletime totalgooglejobsearchtime count, by(machine_id event_date) fast
compress
save all2007_final, replace

