clear all
set mem 1100m
set more off

cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\National_Analysis_Data"
cap cd "~/Dropbox/Texas_Job_Search_New/National_Analysis_Data"

insheet using "/Users/afradkin/Dropbox/Texas_Job_Search_New/Other_Data/all_unemp_emp.csv"
reshape long jan feb mar apr may jun jul aug sep oct nov dec, i(seriesid) j(year) 
reshape long, i(seriesid year) j(month) 