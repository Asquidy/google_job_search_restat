### This File Reads the Google Data, Concatenates It, Checks Correlations with the old Google Data, and Writes a New DTA file.
library(data.table)
library(haven)
library(ggplot2)

### Read old data:
### Old Data Goes to 2013m4
setwd("/Users/andrey_fradkin/Dropbox/Texas_Job_Search_New/Google_Data/StateMonthly_1")
old_data <- read_dta("final_monthly_search_data.dta")
old_data <- as.data.table(old_data)

### Read New Data:
### New Data Goes to 2016
setwd("~/Dropbox/Texas_Job_Search_New/RESTAT Revision Data (Updates)/Trends Update")
new_data_files <- list.files()
new_data_files <- new_data_files[grep('jobs', new_data_files)]

all_google_data <- data.frame(jobs_search=integer(), date=character(), state_abrv=character()) 

for(this_file in new_data_files){
	this_data <- fread(this_file, skip = 5, header = FALSE)
	this_data[, date := substr(V1, 1, 10)]
	this_data[, V1 := NULL]
	this_data[, state_abrv := substr(this_file, 1, 2)]
	setnames(this_data, "V2", "jobs_search")
	all_google_data <- rbind(all_google_data, this_data)
}

### Concatenate:
all_google_data[, year := year(as.Date(date))]
all_google_data[, month := month(as.Date(date))]
all_google_data <- all_google_data[, .(jobs_search = mean(jobs_search)), by = list(state_abrv, year, month)]

setnames(old_data, "jobs_search", "jobs_search_old")
### Check Correlation
old_and_new <- merge(all_google_data, old_data, by = c("state_abrv", "year", "month"))

### Add Long State Name
state_names <- unique(old_data[, list(state_abrv, state_long)])
all_google_data_final <- merge(all_google_data, state_names, by = c("state_abrv"))

### Write DTA
setwd("~/Dropbox/Texas_Job_Search_New/RESTAT Revision Data (Updates)")
write_dta(all_google_data_final, "final_monthly_search_data_2016.dta")
