### This Script Runs the Panel Data Analysis for Seeing the Effects of UI expansions on search.
rm(list = ls())
library(data.table)
library(haven)
library(lfe)
library(stargazer)
library(lubridate)
library(RCurl)
library(tidyr)
library(magrittr)
library(stringr)
library(statar)
library(broom)
### source("~/Dropbox/stargazer_copy.R")

table_folder <- "~/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables/Tables/"
tab <- function(x){table(x, useNA = 'always')}
setwd("~/Dropbox/Texas_Job_Search_New/National_Analysis_Data")

### Read Main Data
data <- data.table(read_dta("final_merged_data.dta"))
data <- data[year<2015 & year>2005]

data[, alt_totwks := as.numeric(alt_totwks)]
data[, year := as.numeric(year)]
data[, month := as.numeric(month)]
data[, quarter := floor(month/4)]
setorder(data, state, year, month)
data[, seq_obs := seq(.N), by = list(state)]

data[, ljobs_search := log(jobs_search)]
data[, max_pop := max(population), by = state]
data[, unemp_rate := unemp_rate/100]
data[, total_ui := cont_claims + init_claims]
data[, frac_ui := total_ui/population]
data[, lpop := log(population)]
data[, total_not_ui := labor_force*unemp_rate - total_ui]
data[, employed := labor_force - total_ui - total_not_ui]
### data[, unemp_rate := (labor_force - employed)/labor_force]
data[, frac_employed := employed/population]
data[, frac_total_ui := total_ui/population]
data[, frac_init_claims := init_claims/population]
data[, frac_not_ui := total_not_ui/population]

### Calculate Close to Expiration Amount
# weeks_left_names <- names(data)[grep("weeks_left",names(data))]
# for(this_var in weeks_left_names){
# 	data[, eval(this_var) := as.numeric(get(this_var)) ]
# 	data[, eval(paste('frac_', this_var, sep = '')) := frac_ui*get(this_var)/cps_count]
# }
# data[, frac_near_exp := frac_weeks_left_0_9 + frac_weeks_left_10_19]

### Identify biggest jump in benefits:
data[, year_month := paste(year, month, sep="-")]
data[, year_month_date := ymd(paste(year, month, 1, sep="-"))]
data[, year_month_small := as.numeric(year_month_date - ymd("2005-01-01"))/100]

### For 'blips' in weeks left of 2 months or less, smooth them out:
setorder(data, state, year, month)
data[, new_totwks := alt_totwks]
data[, prev_altwks1 := c(NA, alt_totwks[pmax(.I - 1, 0)])]
data[, prev_altwks2 := c(NA, NA, alt_totwks[pmax(.I - 2, 0)])]
data[, prev_altwks3 := c(NA, NA, NA, alt_totwks[pmax(.I - 3, 0)])]
data[, prev_altwks_max := pmax(prev_altwks1, prev_altwks2, prev_altwks3)]
data[year_month %in% c('2010-7', '2010-6') & !(state %in% c("AK", "VT")), new_totwks := prev_altwks_max]
data[year==2010 & month==12, new_totwks := prev_altwks1]

data[, prev_totwks := c(NA, new_totwks[pmax(.I - 1, 0)])]
data[, diff_weeks := new_totwks - prev_totwks]
data[is.na(diff_weeks), diff_weeks := 0]
data[, max_diff_weeks := max(diff_weeks, na.rm = TRUE), by = state]

### Pull large jump dates and pick first:
jumps <- data[max_diff_weeks==diff_weeks, list(state, year_month)]
jumps[, seq_N := seq(.N), by = list(state)]
jumps_include_schedule_change <- jumps[seq_N==1]
data <- merge(data, jumps_include_schedule_change[, list(state, year_month, seq_N)], by = c("state", "year_month"), all.x = TRUE)
data[, biggest_jump := as.numeric(!is.na(seq_N))]
data[, seq_N := NULL]

setorder(data, state, year, month)
### Create impulse:
data[, seq_N_all := seq(.N), by = state]
data[, order_biggest_jump := max(biggest_jump*seq_N_all), by = state]
data[, diff_from_big_jump := seq_N_all - order_biggest_jump]

biggest_jump_sample <- data[diff_from_big_jump<8 & diff_from_big_jump>-8]
### loop through data and exclude observations where pbd changed:
this_state <- data[1, state]
this_state_index <- 1
this_impulse <- -7
exclude_rows <- c()
for(i in 1:dim(biggest_jump_sample)[1]){
	this_impulse <- biggest_jump_sample[i, diff_from_big_jump]
	this_diff_weeks <- biggest_jump_sample[i, diff_weeks]

	if(this_impulse==-7){
		this_state <- biggest_jump_sample[1, state]
		this_state_index <- i
	}
	if(this_impulse!=0){
		if(this_impulse<0 & this_diff_weeks!=0){
		exclude_rows <- c(exclude_rows, this_state_index:i)
		} else if(this_impulse>0 & this_diff_weeks!=0){
		exclude_rows <- c(exclude_rows, i:(i+(7 - this_impulse)))
		}
	}
}

exclude_rows <- unique(exclude_rows)
biggest_jump_sample <- biggest_jump_sample[!exclude_rows]

### Pull large jump dates, exclude those on common change dates and pick first:
setorder(data, state, year, month)
jumps <- data[diff_weeks>0, list(diff_weeks, state, year_month)]
exclude_dates <- c("2008-12", "2009-11", "2008-7", "2012-02-01")
jumps <- jumps[!(year_month %in% exclude_dates)]
jumps[, max_diff_weeks := max(diff_weeks), by = state]
jumps <- jumps[max_diff_weeks==diff_weeks]
jumps[, seq_N := seq(.N), by = list(state)]
jumps <- jumps[seq_N==1]
data <- merge(data, jumps[, list(state, year_month, seq_N)], by = c("state", "year_month"), all.x = TRUE)
data[, biggest_jump_nonsched := as.numeric(!is.na(seq_N))]
data[, seq_N := NULL]

setorder(data, state, year, month)
data[, order_nonsched_jump := max(biggest_jump_nonsched*seq_N_all), by = state]
data[, diff_from_nonsched_jump := seq_N_all - order_nonsched_jump]

selected_jump_nonsched  <- data[diff_from_nonsched_jump<8 & diff_from_nonsched_jump>-8]
### loop through data and exclude observations where pbd changed:
this_state <- data[1, state]
this_state_index <- 1
this_impulse <- -7
exclude_rows <- c()
for(i in 1:dim(selected_jump_nonsched)[1]){
	this_impulse <- selected_jump_nonsched[i, diff_from_nonsched_jump]
	this_diff_weeks <- selected_jump_nonsched[i, diff_weeks]

	if(this_impulse==-7){
		this_state <- selected_jump_nonsched[1, state]
		this_state_index <- i
		this_state_last_obs <- max(selected_jump_nonsched[i:(i+14), diff_from_nonsched_jump])
	}
	if(this_impulse!=0){
		if(this_impulse<0 & this_diff_weeks!=0){
		exclude_rows <- c(exclude_rows, this_state_index:i)
		} else if(this_impulse>0 & this_diff_weeks!=0){
		exclude_rows <- c(exclude_rows, i:(i+(this_state_last_obs + 1 - this_impulse)))
		}
	}
}
exclude_rows <- unique(exclude_rows)

selected_jump_nonsched <- selected_jump_nonsched[!exclude_rows]

### Use All Jumps w/ Diff > 12:
setorder(data, state, year, month)
jumps <- data[diff_weeks>13, list(diff_weeks, state, year_month)]
exclude_dates <- c("2008-12", "2009-11", "2008-7")
jumps <- jumps[!(year_month %in% exclude_dates)]
jumps[, seq_N := seq(.N), by = list(state)]
exclude_rows <- c()
for(i in 1:dim(jumps)[1]){
	exclude_rows <- c()
	this_jump <- jumps[i]
	data2 <- data[state==this_jump[, state]]
	data2 <- merge(data2, this_jump[, list(state, year_month, seq_N)], by = c("state", "year_month"), all.x = TRUE)
	data2[, all_jump_nonsched := as.numeric(!is.na(seq_N))]

	setorder(data2, state, year, month)
	data2[, order_all_nonsched_jump := max(all_jump_nonsched*seq_N_all)]
	data2[, diff_from_all_nonsched_jump := seq_N_all - order_all_nonsched_jump]
	these_obs <- data2[diff_from_all_nonsched_jump<8 & diff_from_all_nonsched_jump>-8]
	these_obs[, jump_id := i]
	num_obs <- dim(these_obs)[1]
	for(j in 1:num_obs){
		this_impulse <- these_obs[j, diff_from_all_nonsched_jump]
		this_diff_weeks <- these_obs[j, diff_weeks]
		### data2[, list(year_month, diff_from_all_nonsched_jump, new_totwks, diff_weeks)]
		if(this_impulse!=0){
			if(this_impulse<0 & this_diff_weeks!=0){
				exclude_rows <- c(exclude_rows, 1:j)
			} else if(this_impulse>0 & this_diff_weeks!=0){
				exclude_rows <- c(exclude_rows, j:num_obs)
			}
		}
	}
	exclude_rows <- unique(exclude_rows)
	these_obs <- these_obs[!exclude_rows]
	if(i==1){
		selected_all_jump_nonsched  <- these_obs
	} else{
		selected_all_jump_nonsched  <- rbind(selected_all_jump_nonsched, these_obs)

	}
}

### Run baseline regressions:
max_diff <- 5

### Use Scheduled Changes
### We have 475 obs and marinescu has 318.
### Why does Wyoming has 0 fraction on UI?
biggest_jump_sample[, after := as.numeric(diff_from_big_jump>=0)]
biggest_jump_sample[, impulse := diff_from_big_jump]
biggest_jump_sample[, frac_at_shock := max(frac_total_ui * (impulse==-1))*100, by = state]
biggest_jump_sample[, min_imp := min(impulse), by = state]
biggest_jump_sample <- biggest_jump_sample[min_imp < 0]
biggest_jump_sample[, pre_trend := as.numeric(impulse < 0)*impulse]
biggest_jump_sample[, post_trend := as.numeric(impulse >= 0)*impulse]
biggest_jump_sample[, max_diff_weeks := max(diff_weeks), by = list(state)]

this_reg_biggest_dummy <- felm(ljobs_search ~ after |state| 0 | state , data = biggest_jump_sample[abs(impulse)<max_diff])
this_reg_biggest_dummy_frac <- felm(ljobs_search ~ after + after:frac_at_shock |state | 0 | state, data = biggest_jump_sample[abs(impulse)<max_diff])
this_reg_biggest <- felm(ljobs_search ~ factor(impulse) | state | 0 | state, data = biggest_jump_sample[abs(impulse)<max_diff])

stargazer(this_reg_biggest_dummy, this_reg_biggest_dummy_frac, this_reg_biggest, type = 'text')

### Use Non-Scheduled Changes 
selected_jump_nonsched[, after := as.numeric(diff_from_nonsched_jump>=0)]
selected_jump_nonsched[, impulse := diff_from_nonsched_jump]
selected_jump_nonsched[, frac_at_shock := max(frac_total_ui * (impulse==-1))*100, by = state]
selected_jump_nonsched[, min_imp := min(impulse), by = state]
selected_jump_nonsched[, pre_trend := as.numeric(impulse < 0)*impulse]
selected_jump_nonsched[, post_trend := as.numeric(impulse >= 0)*impulse]
selected_jump_nonsched[, max_diff_weeks := max(diff_weeks), by = list(state)]
selected_jump_nonsched <- selected_jump_nonsched[min_imp < 0]


this_reg_jump_nonsched_dummy <- felm(ljobs_search ~ after |state | 0 | state, data = selected_jump_nonsched[abs(impulse)<max_diff])
this_reg_jump_nonsched_dummy_frac  <- felm(ljobs_search ~ after + after:frac_at_shock |state + quarter | 0 | state, data = selected_jump_nonsched[abs(impulse)<max_diff])
this_reg_jump_nonsched <- felm(ljobs_search ~ factor(impulse) |state| 0 | state, data = selected_jump_nonsched[abs(impulse)<max_diff])

stargazer(this_reg_jump_nonsched_dummy, this_reg_jump_nonsched_dummy_frac, this_reg_jump_nonsched, type = 'text')

# ### Use All Large Non-Scheduled Changes 
# selected_all_jump_nonsched[, after := as.numeric(diff_from_all_nonsched_jump>=0)]
# selected_all_jump_nonsched[, impulse := diff_from_all_nonsched_jump]
# selected_all_jump_nonsched[, frac_at_shock := max(frac_total_ui * (impulse==-1))*100, by = jump_id]
# selected_all_jump_nonsched[, min_imp := min(impulse), by = state]
# selected_all_jump_nonsched <- selected_all_jump_nonsched[min_imp < 0]

# this_reg_jump_all_nonsched_dummy <- felm(ljobs_search ~ after + year_month_date|jump_id + quarter | 0 | jump_id, data = selected_all_jump_nonsched[abs(impulse)<max_diff])
# this_reg_jump_all_nonsched <- felm(ljobs_search ~ factor(impulse) | jump_id + quarter  | 0 | jump_id, data = selected_all_jump_nonsched[abs(impulse)<max_diff])
# this_reg_jump_all_nonsched_dummy_frac  <- felm(ljobs_search ~ after + after:frac_at_shock + year_month_date|jump_id + quarter | 0 | state, data = selected_all_jump_nonsched[abs(impulse)<max_diff])

# stargazer2(this_reg_jump_all_nonsched_dummy, this_reg_jump_all_nonsched, this_reg_jump_all_nonsched_dummy_frac, type = 'text')


line1 <- c("Sample Expansions:", "\\multicolumn{3}{c}{Biggest}", "\\multicolumn{3}{c}{Non-Scheduled}")
line3 <- c("State FE:", rep("Yes", 6))
lines <- list(line1, line3)
### line4 <- c("Time Trend:", rep("Yes", 2), "No", rep("Yes", 2), "No")

### line4 <- c("Change in PBD FE:", rep("No", 4), rep("Yes", 2))

impulses_left <- lapply(names(coef(this_reg_biggest)), function(x) substr(x, 16, 17))
covariate_names <- c("After", "After * Share on UI Before Change", sapply(impulses_left, function(x) paste(x, "Months After Change")))
out <- stargazer2(this_reg_biggest_dummy, this_reg_biggest_dummy_frac, this_reg_biggest, this_reg_jump_nonsched_dummy, this_reg_jump_nonsched_dummy_frac, this_reg_jump_nonsched, add.lines = lines, dep.var.labels = rep("", 6), covariate.labels = covariate_names, dep.var.caption = "Log GJSI", float = FALSE, column.labels = NULL, omit.stat = c("f", "ser", "rsq", "adj.rsq"), column.separate = c(1, 1, 1), omit.table.layout = 'n', keep = c("impulse", "after", "frac"), dep.var.labels.include = FALSE)

### Make line 1 span columns
line1_line <- pmatch("Sample Expansions", out)
line1_new <- "Sample Expansions: & \\multicolumn{3}{c}{Biggest} & \\multicolumn{3}{c}{Biggest Non-Scheduled} \\\\"
sink(paste(table_folder, "baseline.tex", sep = ''))
cat(out[1:(line1_line-1)], line1_new, out[(line1_line + 1):length(out)], sep = '\n')
sink()

### Create control states - Biggest:
states <- unique(selected_jump_nonsched[, state])
rm(control_obs)
for(this_state in states){
	state_obs <- selected_jump_nonsched[state==this_state]
	setnames(state_obs, "diff_from_nonsched_jump", "diff_from_nonsched_jump_ctr" )
	control_obs <- merge(data, state_obs[, list(year_month, diff_from_nonsched_jump_ctr)], by = "year_month")
	control_obs[, num_unique := length(unique(new_totwks)), by = state]
	control_obs <- control_obs[num_unique==1 | this_state==state]
	control_obs[, group_fe := this_state]
	control_obs[, is_state_exp := as.numeric(this_state==state)]
	if(this_state==states[1]){
		full_control_obs <- control_obs
	} else{
		full_control_obs <- rbind(full_control_obs, control_obs)
	}
}
full_control_obs[, group_year_month_fe := .GRP, by = list(year_month, group_fe)]
full_control_obs[, state_exp_fe := paste(group_fe, state, sep = '')]
full_control_obs[, after := as.numeric(diff_from_nonsched_jump_ctr>=0)*is_state_exp]
full_control_obs[, frac_at_shock := max(frac_total_ui * (diff_from_nonsched_jump_ctr==-1))*100, by = group_fe]
full_control_obs[, min_impulse := min(diff_from_nonsched_jump_ctr), by = group_fe]
full_control_obs[, impulse := diff_from_nonsched_jump*is_state_exp]
full_control_obs[is_state_exp==0, impulse := 100]

this_reg_case_after <- felm(ljobs_search ~ after | state_exp_fe + year_month | 0 | state, data = full_control_obs[abs(diff_from_nonsched_jump_ctr)<max_diff], exactDOF=TRUE)
this_reg_case_after_inter <- felm(ljobs_search ~ after + after:frac_at_shock| state_exp_fe + year_month | 0 | state, data = full_control_obs[abs(diff_from_nonsched_jump_ctr)<max_diff], exactDOF=TRUE)
this_reg_case_after_imp <- felm(ljobs_search ~ factor(impulse) | state_exp_fe + year_month | 0 | state, data = full_control_obs[abs(diff_from_nonsched_jump_ctr)<max_diff], exactDOF=TRUE)
stargazer(this_reg_case_after, this_reg_case_after_inter, this_reg_case_after_imp, type = 'text')

line2 <- c("Year-Month FE:", rep("Yes", 3))
line3 <- c("Jump-Control FE:", rep("Yes", 3))
imp_coef_names <- names(coef(this_reg_case_after_imp))
impulses_left <- lapply(names(coef(this_reg_case_after_imp)), function(x) substr(x, 16, 17))
covariate_names <- c("After", "After * Share on UI Before Change", sapply(impulses_left, function(x) paste(x, "Months After Change")))
out <- stargazer(this_reg_case_after, this_reg_case_after_inter, this_reg_case_after_imp, add.lines = list(line2, line3), float = FALSE, covariate.labels = covariate_names, column.labels = NULL, dep.var.caption = "Log GJSI", dep.var.labels = rep("", 6), omit.stat = c("f", "ser", "rsq", "adj.rsq"), column.separate = c(1, 1, 1), omit.table.layout = 'n', keep = c("new_totwks", "after", "date", "impulse"), omit = "factor(impulse)100", dep.var.labels.include = FALSE)
line_omit <- pmatch(" 10", out)

sink(paste(table_folder, "control.tex", sep = ''))
cat(out[1:(line_omit-1)], out[(line_omit + 3):length(out)], sep = '\n')
sink()


### Calculate Impulse for All obs:
data[, `:=` (neg_impulse_m3 = 0
	, neg_impulse_m2 = 0
	, neg_impulse_m1 = 0
	, neg_impulse_0 = 0
	, neg_impulse_p1 = 0
	, neg_impulse_p2 = 0
	, neg_impulse_p3 = 0
	, neg_impulse_p4 = 0)]

### Loop Through Each Jump and Create Impulse:
setorder(data, state, year, month)
for(this_obs in 1:dim(data)[1]){
	if(data[this_obs, diff_weeks]<=-6){
		data[this_obs - 3, neg_impulse_m3 := 1]
		data[this_obs - 2, neg_impulse_m2 := 1]
		data[this_obs - 1, neg_impulse_m1 := 1]
		data[this_obs, neg_impulse_0  := 1]
		data[this_obs + 1, neg_impulse_p1 := 1]
		data[this_obs + 2, neg_impulse_p2 := 1]
		data[this_obs + 3, neg_impulse_p3 := 1]
		data[this_obs + 4, neg_impulse_p4 := 1]			
	}
}
data[, any_neg_impulse := pmax(neg_impulse_m3, neg_impulse_m2, neg_impulse_m1, neg_impulse_0, neg_impulse_p1, neg_impulse_p2, neg_impulse_p3, neg_impulse_p4)]

this_reg <- felm(ljobs_search ~ neg_impulse_m3 + neg_impulse_m2 + neg_impulse_m1 + neg_impulse_0 + neg_impulse_p1 + neg_impulse_p2 + neg_impulse_p3 + neg_impulse_p4 + unemp_rate | year_month_date + state | 0 | state, data = data) 
stargazer(this_reg, type = 'text', omit = 'state')

### Calculate Impulse for All obs:
data[, `:=` (pos_impulse_m3 = 0
	, pos_impulse_m2 = 0
	, pos_impulse_m1 = 0
	, pos_impulse_0 = 0
	, pos_impulse_p1 = 0
	, pos_impulse_p2 = 0
	, pos_impulse_p3 = 0
	, pos_impulse_p4 = 0)]

### Loop Through Each Jump and Create Impulse:
setorder(data, state, year, month)
for(this_obs in 1:dim(data)[1]){
	if(data[this_obs, diff_weeks]>=13){
		data[this_obs - 3, pos_impulse_m3 := 1]
		data[this_obs - 2, pos_impulse_m2 := 1]
		data[this_obs - 1, pos_impulse_m1 := 1]
		data[this_obs, pos_impulse_0  := 1]
		data[this_obs + 1, pos_impulse_p1 := 1]
		data[this_obs + 2, pos_impulse_p2 := 1]
		data[this_obs + 3, pos_impulse_p3 := 1]
		data[this_obs + 4, pos_impulse_p4 := 1]			
	}
}

data[, any_pos_impulse := pmax(pos_impulse_m3, pos_impulse_m2, pos_impulse_m1, pos_impulse_0, pos_impulse_p1, pos_impulse_p2, pos_impulse_p3, pos_impulse_p4)]

this_reg <- felm(ljobs_search ~ pos_impulse_m3 + pos_impulse_m2 + pos_impulse_m1 + pos_impulse_0 + pos_impulse_p1 + pos_impulse_p2 + pos_impulse_p3 + pos_impulse_p4 + unemp_rate | year_month_date + state | 0 | state, data = data)
stargazer(this_reg, type = 'text')

data[, after_pos := pmax(pos_impulse_0, pos_impulse_p1, pos_impulse_p2, pos_impulse_p3, pos_impulse_p4)]
this_reg <- felm(ljobs_search ~ pos_impulse_m3 + pos_impulse_m2 + pos_impulse_m1 + pos_impulse_0 + pos_impulse_p1 + pos_impulse_p2 + pos_impulse_p3 + pos_impulse_p4 | year_month_date + state | 0 | state, data = data)
stargazer(this_reg, type = 'text')
this_reg2 <- felm(ljobs_search ~ after_pos | year_month_date + state | 0 | state, data = data[any_pos_impulse==1])
this_reg3 <- felm(ljobs_search ~ after_pos + after_pos:unemp_rate | year_month_date + state | 0 | state, data = data[any_pos_impulse==1])
stargazer(this_reg, type = 'text')
stargazer(this_reg2, this_reg3, this_reg, type = 'text', omit = 'state')