### This Script Runs the Panel Data Analysis for the Effects of UI expansions on search.
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
library(coefplot)

table_folder <- "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables/Tables/"
figure_folder <- "~/Dropbox/Texas_Job_Search_New/replic_test_figures_and_tables/Figures/"
tab <- function(x){table(x, useNA = 'always')}
setwd("~/Dropbox/Texas_Job_Search_New/restat_data/National_Analysis_Data")

### Read Main Data
data <- data.table(read_dta("final_merged_data.dta"))
data <- data[year<=2015 & year>2005]

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
data[, frac_employed := employed/population]
data[, frac_total_ui := total_ui/population]
data[, frac_init_claims := init_claims/population]
data[, frac_not_ui := total_not_ui/population]

data[, year_month := paste(year, month, sep="-")]
data[, year_month_date := ymd(paste(year, month, 1, sep="-"))]
data[, year_month_small := as.numeric(year_month_date - ymd("2005-01-01"))/100]

### For 'blips' in weeks left of 2 months or less, smooth them out:
### Algorithm: 
### Step 1: Find previous weeks (up to 3 weeks back)
### Step 2: Find max weeks in that range
### Step 3: For most states, change the weeks in the blip weeks to the max prior value.
setorder(data, state, year, month)
data[, new_totwks := alt_totwks]
data[, prev_altwks1 := shift(alt_totwks, n = 1, type = 'lag'), by = list(state)]
data[, prev_altwks2 := shift(alt_totwks, n = 2, type = 'lag'), by = list(state)]
data[, prev_altwks3 := shift(alt_totwks, n = 3, type = 'lag'), by = list(state)]
data[, prev_altwks_max := pmax(prev_altwks1, prev_altwks2, prev_altwks3)]
data[year_month %in% c('2010-7', '2010-6') & !(state %in% c("AK", "VT")), new_totwks := prev_altwks_max]
data[year==2010 & month==12, new_totwks := prev_altwks1]

### Calculate prior weeks:
data[, prev_totwks := shift(new_totwks, n = 1, type = 'lag'), by = list(state)]
data[, diff_weeks := new_totwks - prev_totwks]
data[is.na(diff_weeks), diff_weeks := 0]
data[, max_diff_weeks := max(diff_weeks, na.rm = TRUE), by = state]

### Impulse functions to use:
# 1. Largest jump that is not concurrent with general expansion.
# 2. All jumps not concurrent with general expansion > 7 weeks.
# 3. Largest fall

### Specifications:
# 1. Just before and after.
# 2. Heterogeneity by jump size.
# 3. Using "control" states.
# 4. Pool impulses.

### Pull large positive jump dates, exclude those on common change dates and pick first:
setorder(data, state, year, month)
jumps <- data[diff_weeks>0, list(diff_weeks, state, year_month)]
exclude_dates <- c("2008-12", "2009-11", "2008-7", "2012-02-01")
jumps <- jumps[!(year_month %in% exclude_dates)]
jumps[, max_diff_weeks := max(diff_weeks), by = state]
jumps <- jumps[max_diff_weeks==diff_weeks]

### Pick First
jumps[, seq_N := seq(.N), by = list(state)]
jumps <- jumps[seq_N==1]
data <- merge(data, jumps[, list(state, year_month, seq_N)], by = c("state", "year_month"), all.x = TRUE)
data[, biggest_jump_nonsched := as.numeric(!is.na(seq_N))]
data[, seq_N := NULL]

setorder(data, state, year, month)
data[, seq_N_all := seq(.N), by = state]
data[, order_nonsched_jump := max(biggest_jump_nonsched*seq_N_all), by = state]
data[, diff_from_nonsched_jump := seq_N_all - order_nonsched_jump]

### Pick dates within 7 weeks of jump:
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

### Jump Data:
### 1. selected_jump_nonsched
### 2. selected_drops_jump_nonsched

### Maximum difference from time of benefits change:
max_diff <- 5

### Use Non-Scheduled Changes:
selected_jump_nonsched[, jump_size := max(diff_weeks), by = list(state)]
selected_jump_nonsched[, after := as.numeric(diff_from_nonsched_jump>=0)]
selected_jump_nonsched[, impulse := diff_from_nonsched_jump]
selected_jump_nonsched[, frac_at_shock := max(frac_total_ui * (impulse==-1))*100, by = state]
selected_jump_nonsched[, min_imp := min(impulse), by = state]
selected_jump_nonsched[, pre_trend := as.numeric(impulse < 0)*impulse]
selected_jump_nonsched[, post_trend := as.numeric(impulse >= 0)*impulse]
selected_jump_nonsched[, max_diff_weeks := max(diff_weeks), by = list(state)]
selected_jump_nonsched <- selected_jump_nonsched[min_imp < 0]
this_sample <-  selected_jump_nonsched[abs(impulse)<max_diff]
this_reg_jump_nonsched <- felm(ljobs_search ~ factor(impulse) |state| 0 | state, data = this_sample)

### Create control states - Biggest:
states <- unique(selected_jump_nonsched[, state])
rm(control_obs)
for(this_state in states){
	state_obs <- selected_jump_nonsched[state==this_state]
	setnames(state_obs, "diff_from_nonsched_jump", "diff_from_nonsched_jump_ctr" )
	control_obs <- merge(data, state_obs[, list(year_month, diff_from_nonsched_jump_ctr, jump_size)], by = "year_month")
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
full_control_obs[is_state_exp==0, jump_size := 0]

this_sample <- full_control_obs[abs(diff_from_nonsched_jump_ctr)<max_diff]
this_reg_case_after_imp <- felm(ljobs_search ~ factor(impulse) | state_exp_fe + year_month | 0 | state, data = this_sample, exactDOF=TRUE)

### Large Drop Sample:
### Use Biggest Drop:
setorder(data, state, year, month)
jumps <- data[diff_weeks < -7, list(diff_weeks, state, year_month)]
exclude_dates <- c("2008-12", "2009-11", "2008-7")
jumps <- jumps[!(year_month %in% exclude_dates)]
jumps[, min_diff_weeks := min(diff_weeks), by = state]
jumps <- jumps[min_diff_weeks==diff_weeks]

jumps[, seq_N := seq(.N), by = list(state)]
### Pick First
jumps <- jumps[seq_N==1]

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
    selected_drops_jump_nonsched  <- these_obs
  } else{
    selected_drops_jump_nonsched  <- rbind(selected_drops_jump_nonsched, these_obs)
  }
}

large_drop_sample <- data[as.Date(year_month_date) < '2014-05-01' & as.Date(year_month_date) > '2013-07-01']
large_drop_sample[, drop_size := min(diff_weeks * as.numeric(year_month=='2014-1')), by = state]
large_drop_sample[, impulse := seq(.N) - 5, by = state]
large_drop_sample[, after := as.numeric(impulse>=0)]
large_drop_sample[, large_drop := as.numeric(drop_size < -24)]
large_drop_sample[, impulse_factor := factor(impulse, c("-4", "-3", "-2", "-1", "0", "1", "2", "3", "4"))]
reg_drop_imp <- felm(ljobs_search ~ impulse_factor:large_drop + year_month + state + large_drop| 0 | 0 |state , data = large_drop_sample)

### Calculate Impulse for all obs:
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
	if(data[this_obs, diff_weeks]<=-7){
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

neg_impulse_panel <- felm(ljobs_search ~ neg_impulse_m3 + neg_impulse_m2 + neg_impulse_m1 + neg_impulse_0 + neg_impulse_p1 + neg_impulse_p2 + neg_impulse_p3 + neg_impulse_p4 + frac_total_ui| year_month_date + state | 0 | state, data = data[year>2011])
stargazer(neg_impulse_panel, type = 'text', omit = 'state')
coef_this_reg <- as.data.table(tidy(neg_impulse_panel))
coef_this_reg <- coef_this_reg[term!='unemp_rate' & term!='frac_total_ui']
coef_this_reg[, impulse := -3:4]
this_plot <- ggplot(coef_this_reg[1:8], aes(impulse, estimate)) + 
  geom_hline(yintercept=0, lty=2, lwd=1, colour="grey50") +
  geom_errorbar(aes(ymin=estimate - 1.96*std.error, ymax=estimate + 1.96*std.error), 
                lwd=1, colour="red", width=0) +
  geom_point(size=4, pch=21, fill="yellow") +
  theme_bw() + xlab('Month Relative to Drop in Potential Benefit Duration')

ggsave(this_plot, file = paste(figure_folder, "drop_shock_post_2011.pdf", sep = ''))

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

pos_impulse_panel <- felm(ljobs_search ~ pos_impulse_m3 + pos_impulse_m2 + pos_impulse_m1 + pos_impulse_0 + pos_impulse_p1 + pos_impulse_p2 + pos_impulse_p3 + pos_impulse_p4 + frac_total_ui| year_month_date + state | 0 | state, data = data[year < 2012])
stargazer(pos_impulse_panel, type = 'text')
coef_this_reg <- as.data.table(tidy(pos_impulse_panel))
coef_this_reg <- coef_this_reg[term!='unemp_rate' & term!='frac_total_ui']
coef_this_reg[, impulse := -3:4]
this_plot <- ggplot(coef_this_reg, aes(impulse, estimate)) + 
  geom_hline(yintercept=0, lty=2, lwd=1, colour="grey50") +
  geom_errorbar(aes(ymin=estimate - 1.96*std.error, ymax=estimate + 1.96*std.error), 
                lwd=1, colour="red", width=0) +
  geom_point(size=4, pch=21, fill="yellow") +
  theme_bw() + xlab('Month Relative to Jump in Potential Benefit Duration')
ggsave(this_plot, file = paste(figure_folder, "jump_shock_pre_2012.pdf"))


### Make rownames the same for all regressions:
rownames(this_reg_jump_nonsched$beta) <-  rownames(this_reg_jump_nonsched$beta)
rownames(this_reg_jump_nonsched$coefficients) <- rownames(this_reg_jump_nonsched$coefficients)

rownames(this_reg_case_after_imp$beta)[1:8] <-  rownames(this_reg_jump_nonsched$beta)
rownames(this_reg_case_after_imp$coefficients)[1:8] <- rownames(this_reg_jump_nonsched$coefficients)

### change name of factor(impulse)100
rownames(this_reg_case_after_imp$beta)[9] <- 'control'
rownames(this_reg_case_after_imp$coefficients)[9] <- 'control'

rownames(pos_impulse_panel$beta)[1:8] <-  rownames(this_reg_jump_nonsched$beta)
rownames(pos_impulse_panel$coefficients)[1:8] <- rownames(this_reg_jump_nonsched$coefficients)

which_imp <- grep('impulse', rownames(reg_drop_imp$beta))
rownames(reg_drop_imp$beta)[which_imp]  <-  rownames(this_reg_jump_nonsched$beta)
rownames(reg_drop_imp$coefficients)[which_imp]  <- rownames(this_reg_jump_nonsched$coefficients)

rownames(neg_impulse_panel$beta)[1:8] <-  rownames(this_reg_jump_nonsched$beta)
rownames(neg_impulse_panel$coefficients)[1:8] <- rownames(this_reg_jump_nonsched$coefficients)

### Table w/ all combined impulse regressions:
line2 <- c("Year-Month FE", rep("Yes", 5))
line3 <- c("State FE:", rep("Yes", 5))
line4 <- c("Full Panel:", c("No", "No", "Yes", "No", "Yes"))
line5 <- c("Sample:", c("Largest Increase", "Largest Increase + Control States", "$<$ 2012", "2014 EUC Lapse",  "$>$ 2011"))
lines <- list(line2, line3, line4, line5)
impulses_left <- lapply(seq(-3, 4), function(x) paste(x, " Months After Change"))

covariate_names <- unlist(impulses_left)

stargazer(this_reg_jump_nonsched, this_reg_case_after_imp, pos_impulse_panel, reg_drop_imp, neg_impulse_panel, covariate.labels = covariate_names, out = paste(table_folder, "all_impulse.tex", sep = ''),  add.lines = lines, dep.var.caption = "Log GJSI", float = FALSE, column.labels =  c(rep("Increases", 1), rep("Drops", 1)), omit.stat = c("f", "ser", "rsq", "adj.rsq"), keep = c("impulse"), column.separate = c(3, 2), dep.var.labels = NULL, dep.var.labels.include = FALSE)
