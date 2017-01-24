clear all
set mem 8000m
set matsize 4000
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"

*** Current Policy Aggregation ***
forvalues x=0/2 {
	use user_weeks_left_roth_data
	keep if mod(id,3)==`x'
	drop if county_fips>900
	gen count=1
	drop city tier_code weekly_ben total_ben

	*** Merge with Zip
	merge m:1 zip using DMA_zip_crosswalk_small
	drop if _merge==2|_merge==1
	drop _merge county_fips county
	*** total_weeks_left
	collapse (sum) count, by(date naive_total_weeks_left msa_code)

	sort msa_code date naive
	compress
	save collapsed_data_by_weeks_left_msa_date, replace

	**Reshape data to have weeks_left as columns
	drop if naive_total_weeks_left<-9|naive_total_weeks_left>99
	tostring naive_total_weeks_left, replace
	replace naive_total_weeks_left = regexr(naive_total_weeks_left, "-", "neg")
	reshape wide count, i(date msa) j(naive_total_weeks_left) string

	sort msa_code date
	order msa_code date count0  count1  count2  count3  count4  count5  count6  count7  count8  count9  count10 count11 count12 count13 count14 count15 count16 count17 count18 count19 count20 count21 count22 count23 count24 count25 count26 count27 count28 count29 count30 count31 count32 count33 count34 count35 count36 count37 count38 count39 count40 count41 count42 count43 count44 count45 count46 count47 count48 count49 count50 count51 count52 count53 count54 count55 count56 count57 count58 count59 count60 count61 count62 count63 count64 count65 count66 count67 count68 count69 count70 count71 count72 count73 count74 count75 count76 count77 count78 count79 count80 count81 count82 count83 count84 count85 count86 count87 count88 count89 count90 count91 count92 count93 count94 count95 count96 count97 count98 count99

	**Add in UI law data
	merge m:1 date using TX_Weeks_Left_Data_Alt.dta
	drop if _merge==2
	drop _merge
	sort msa_code date 

	egen total_extensions = rowtotal(tier1-tier4)
	gen law_change_indicator = total_extensions!=total_extensions[_n-1] & msa==msa[_n-1]

	compress
	save naive_weeks_left_data`x', replace
}

*** Current Law Aggregation ***

clear all
set mem 8000m
set matsize 8000
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"

forvalues x=0/2 {
	use user_weeks_left_roth_data
	keep if mod(id,3)==`x'
	drop if county_fips>900
	gen count=1
	drop city tier_code weekly_ben total_ben

	*** Merge with Zip
	merge m:1 zip using DMA_zip_crosswalk_small
	drop if _merge==2|_merge==1
	drop _merge county_fips county

	collapse (sum) count, by(date soph_total_weeks_left msa_code)

	sort msa_code date soph
	compress
	save collapsed_data_by_weeks_left_msa_date, replace

	**Reshape data to have weeks_left as columns
	drop if soph_total_weeks_left<-9|soph_total_weeks_left>99
	tostring soph_total_weeks_left, replace
	replace soph_total_weeks_left = regexr(soph_total_weeks_left, "-", "neg")
	reshape wide count, i(date msa) j(soph_total_weeks_left) string

	sort msa_code date
	order msa_code date count0  count1  count2  count3  count4  count5  count6  count7  count8  count9  count10 count11 count12 count13 count14 count15 count16 count17 count18 count19 count20 count21 count22 count23 count24 count25 count26 count27 count28 count29 count30 count31 count32 count33 count34 count35 count36 count37 count38 count39 count40 count41 count42 count43 count44 count45 count46 count47 count48 count49 count50 count51 count52 count53 count54 count55 count56 count57 count58 count59 count60 count61 count62 count63 count64 count65 count66 count67 count68 count69 count70 count71 count72 count73 count74 count75 count76 count77 count78 count79 count80 count81 count82 count83 count84 count85 count86 count87 
	**Add in UI law data
	merge m:1 date using TX_Weeks_Left_Data_Alt.dta
	drop if _merge==2
	drop _merge
	sort msa_code date 

	egen total_extensions = rowtotal(tier1-tier4)
	gen law_change_indicator = total_extensions!=total_extensions[_n-1] & msa==msa[_n-1]

	compress
	save soph_weeks_left_data`x', replace
}

*** Weeks On Aggregation ***

clear all
set mem 8000m
set matsize 4000
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"

forvalues x=0/2 {
	use user_weeks_left_roth_data
	keep if mod(id,3)==`x'
	drop if county_fips>900
	gen count=1
	drop city tier_code weekly_ben total_ben

	*** Merge with Zip
	merge m:1 zip using DMA_zip_crosswalk_small
	drop if _merge==2|_merge==1
	drop _merge county_fips county

	**This drops people who were on EUC before Regular

	**Drop weird dates that are off by 1
	replace weekson=120 if weekson>120

	collapse (sum) count, by(date weekson msa_code)

	compress
	save collapsed_data_by_weeks_on_msa_date, replace

	**Reshape data to have weeks_left as columns

	tostring weekson, replace
	replace weekson = regexr(weekson, "-", "neg")
	reshape wide count, i(date msa) j(weekson) string

	sort msa_code date
	order msa_code date count1  count2  count3  count4  count5  count6  count7  count8  count9  count10 count11 count12 count13 count14 count15 count16 count17 count18 count19 count20 count21 count22 count23 count24 count25 count26 count27 count28 count29 count30 count31 count32 count33 count34 count35 count36 count37 count38 count39 count40 count41 count42 count43 count44 count45 count46 count47 count48 count49 count50 count51 count52 count53 count54 count55 count56 count57 count58 count59 count60 count61 count62 count63 count64 count65 count66 count67 count68 count69 count70 count71 count72 count73 count74 count75 count76 count77 count78 count79 count80 count81 count82 count83 count84 count85 count86 count87 count88 count89 count90 count91 count92 count93 count94 count95 count96 count97 count98 count99

	**Add in UI law data
	merge m:1 date using TX_Weeks_Left_Data_Alt.dta
	drop if _merge==2
	drop _merge
	sort msa_code date 

	egen total_extensions = rowtotal(tier1-tier4)
	gen law_change_indicator = total_extensions!=total_extensions[_n-1] & msa==msa[_n-1]

	forvalues num = 0/120{
		rename count`num' num_weeks_on`num'
	}

	compress
	save number_weeks_on_data`x', replace
}

*** Combine All Files
clear all
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data"
set mem 8000m

use number_weeks_on_data0
forvalues x=1/2 {
    append using number_weeks_on_data`x'
}
collapse (sum) num_weeks*, by(msa_code date tier1 - law_change_indicator)
save number_weeks_on_data, replace

clear
use soph_weeks_left_data0
forvalues x=1/2 {
    append using soph_weeks_left_data`x'
}
collapse (sum) count*, by(msa_code date tier1 - law_change_indicator)

save soph_weeks_left_data, replace

clear
use naive_weeks_left_data0
forvalues x=1/2 {
    append using naive_weeks_left_data`x'
}
collapse (sum) count*, by(msa_code date tier1 - law_change_indicator)
save naive_weeks_left_data, replace
