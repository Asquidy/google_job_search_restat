clear all
set mem 1800m

insheet using 9splitfile2.csv

keep if zip_code==37411|zip_code== 92027|zip_code== 94108|zip_code==32065|zip_code==68037|zip_code==85304|zip_code==34974|zip_code==33125|zip_code==12586|zip_code==19149|zip_code==92064|zip_code==93534|zip_code==33014|zip_code==83647|zip_code==16602|zip_code==15642|zip_code==16648|zip_code==76148|zip_code==6614|zip_code==20706|zip_code==60193|zip_code==11756|zip_code==68124|zip_code==91709|zip_code==28382|zip_code==5131|zip_code==89523|zip_code==96001|zip_code==62449|zip_code==32571|zip_code==48827|zip_code==41102|zip_code==32542|zip_code==36360|zip_code==43506|zip_code==94538|zip_code==80501|zip_code==8096|zip_code==8251|zip_code==32244|zip_code==91784|zip_code==32210|zip_code==32207|zip_code==79938|zip_code==33565|zip_code==25139|zip_code==97523|zip_code==6854|zip_code==11204|zip_code== 21216|zip_code== 21012|zip_code== 29928|zip_code== 76105|zip_code== 11229|zip_code== 80236|zip_code== 27332|zip_code== 12302|zip_code== 71328|zip_code== 74066|zip_code== 32765|zip_code== 44473|zip_code== 75006|zip_code== 11752|zip_code== 77388|zip_code== 91340|zip_code== 8879|zip_code== 76248|zip_code== 56361|zip_code== 2719|zip_code== 49073|zip_code== 27265|zip_code== 61704|zip_code== 66076|zip_code== 19044|zip_code== 27549|zip_code== 37166|zip_code== 60137|zip_code== 83401|zip_code== 18411|zip_code== 1104|zip_code== 30721|zip_code== 55033|zip_code== 43207|zip_code== 24445|zip_code== 80634|zip_code== 75038|zip_code== 97402|zip_code== 94960


gen hour = regexs(1) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")
gen minute = regexs(2) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")
gen second = regexs(3) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")

destring hour, replace
destring minute, replace
destring second, replace

drop event_time

compress

save bigcombo, replace
clear all
insheet using 9splitfile3.csv

keep if zip_code==37411|zip_code== 92027|zip_code== 94108|zip_code==32065|zip_code==68037|zip_code==85304|zip_code==34974|zip_code==33125|zip_code==12586|zip_code==19149|zip_code==92064|zip_code==93534|zip_code==33014|zip_code==83647|zip_code==16602|zip_code==15642|zip_code==16648|zip_code==76148|zip_code==6614|zip_code==20706|zip_code==60193|zip_code==11756|zip_code==68124|zip_code==91709|zip_code==28382|zip_code==5131|zip_code==89523|zip_code==96001|zip_code==62449|zip_code==32571|zip_code==48827|zip_code==41102|zip_code==32542|zip_code==36360|zip_code==43506|zip_code==94538|zip_code==80501|zip_code==8096|zip_code==8251|zip_code==32244|zip_code==91784|zip_code==32210|zip_code==32207|zip_code==79938|zip_code==33565|zip_code==25139|zip_code==97523|zip_code==6854|zip_code==11204|zip_code== 21216|zip_code== 21012|zip_code== 29928|zip_code== 76105|zip_code== 11229|zip_code== 80236|zip_code== 27332|zip_code== 12302|zip_code== 71328|zip_code== 74066|zip_code== 32765|zip_code== 44473|zip_code== 75006|zip_code== 11752|zip_code== 77388|zip_code== 91340|zip_code== 8879|zip_code== 76248|zip_code== 56361|zip_code== 2719|zip_code== 49073|zip_code== 27265|zip_code== 61704|zip_code== 66076|zip_code== 19044|zip_code== 27549|zip_code== 37166|zip_code== 60137|zip_code== 83401|zip_code== 18411|zip_code== 1104|zip_code== 30721|zip_code== 55033|zip_code== 43207|zip_code== 24445|zip_code== 80634|zip_code== 75038|zip_code== 97402|zip_code== 94960

gen hour = regexs(1) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")
gen minute = regexs(2) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")
gen second = regexs(3) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")

destring hour, replace
destring minute, replace
destring second, replace

drop event_time

append  using bigcombo

compress

save bigcombo, replace

forvalues x= 1/8 {
forvalues y=1/24 {
clear all
cap insheet using `x'splitfile`y'.csv
if _rc==0 {
keep if zip_code==37411|zip_code== 92027|zip_code== 94108|zip_code==32065|zip_code==68037|zip_code==85304|zip_code==34974|zip_code==33125|zip_code==12586|zip_code==19149|zip_code==92064|zip_code==93534|zip_code==33014|zip_code==83647|zip_code==16602|zip_code==15642|zip_code==16648|zip_code==76148|zip_code==6614|zip_code==20706|zip_code==60193|zip_code==11756|zip_code==68124|zip_code==91709|zip_code==28382|zip_code==5131|zip_code==89523|zip_code==96001|zip_code==62449|zip_code==32571|zip_code==48827|zip_code==41102|zip_code==32542|zip_code==36360|zip_code==43506|zip_code==94538|zip_code==80501|zip_code==8096|zip_code==8251|zip_code==32244|zip_code==91784|zip_code==32210|zip_code==32207|zip_code==79938|zip_code==33565|zip_code==25139|zip_code==97523|zip_code==6854|zip_code==11204|zip_code== 21216|zip_code== 21012|zip_code== 29928|zip_code== 76105|zip_code== 11229|zip_code== 80236|zip_code== 27332|zip_code== 12302|zip_code== 71328|zip_code== 74066|zip_code== 32765|zip_code== 44473|zip_code== 75006|zip_code== 11752|zip_code== 77388|zip_code== 91340|zip_code== 8879|zip_code== 76248|zip_code== 56361|zip_code== 2719|zip_code== 49073|zip_code== 27265|zip_code== 61704|zip_code== 66076|zip_code== 19044|zip_code== 27549|zip_code== 37166|zip_code== 60137|zip_code== 83401|zip_code== 18411|zip_code== 1104|zip_code== 30721|zip_code== 55033|zip_code== 43207|zip_code== 24445|zip_code== 80634|zip_code== 75038|zip_code== 97402|zip_code== 94960

gen hour = regexs(1) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")
gen minute = regexs(2) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")
gen second = regexs(3) if regexm(event_time, "([0-9]+):([0-9][0-9]):([0-9][0-9])")

destring hour, replace
destring minute, replace
destring second, replace

drop event_time

append using bigcombo

compress

save bigcombo, replace

}
else {
}
}
}
*
