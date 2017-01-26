# Replication Repository: "The Impact of Unemployment Insurance on Job Search: Evidence from Google Search Data"
This file contains information regarding scripts, paper results, software versions, and data files for the paper:

*The Impact of Unemployment Insurance on Job Search: Evidence from Google Search Data*

**Code:**
- Main Analysis Code:
	- analysis/0_assign_msa_to_tx_data.do, Clean Texas Unemployment by MSA Data.
	- analysis/1_google_tx_daily.do, Combine raw Google daily data for Texas.
	- analysis/2_prep_week_data_curlaw.do, Merge Files Necessary for Non-Linear Least Squares Analysis of Texas Data.
	- analysis/3_nlls_cur_law.do, Run non-linear least squares analysis.
	- analysis/4a_national_googlse_serach_data.do, create national Google series from raw files.
	- analysis/4b_merge_serach_rothstein_UI_data.do, add CPS data to Google search data.
	- analysis/4c_national_regressions_restat.do, run national ols regressions.
	- analysis/4d_new_panel_restat.R, run impulse function panel regressions.
	- news_analysis/news_figures.do, create news figures.
	- comScore_analysis/comscore_comparison_table.do, comscore search correlations.
	- atus_analysis/search_term_correlations.do, compute atus correlations, Table A3.
	- atus_analysis/state_atus_correlations.do, generates numbers for Table A1.
	- atus_analysis/create_day_of_week_holiday_table.do, generates estimates for Table 4, Figure A1.
	- google_analysis/test_google_and_emp_corr.do, generates estimate for Table 5.
	- latex/*, generate paper and appendix.

**Results:**
- Tables:
	- Table 2: Correlation of Google Search to Online Job Search Time - comScore Data
		- File Name: GooglecomScore.tex
		- Script: comscore_analysis/comscore_comparison_table.do
	- Table 3: ATUS Search Time Correlation
		- File Name: ATUSCorr.tex
		- Script: state_atus_correlations.do
	- Table 4: Day of Week Fixed Effects for Google, comScore, and ATUS
		- File Name: holiday_dow.tex
		- Script: create_day_of_week_holiday_table.do
	- Table 5: Empirical Tests of Google Job Search Measure
		- File Name: Table1.tex
		- Script: test_google_and_emp_corr.do
	- Table 6: Effect of UI Status and Composition on Job Search (Non-linear Least Squares)
		- File Name: nllsregs_current_law.tex
		- Script: 3_nlls_cur_law.do
	- Table 7: Effects of UI Expansions and Composition by State
		- File Name: national_regs_new_restat.tex
		- Script: 4c_national_regressions_restat.do
	- Table 8: Event Study Regression Results.
		- File Name: all_impulse.tex
		- Script: 4d_new_panel_restat.R

	- Table A1: Google Search Term Correlations
		- File Name: manually inputted into paper latex file
		- Script: state_atus_correlations.do
	- Table A2: Change in log(GJSI) Following Expansions: Robustness
		- File Name: robust_expansion_restat.tex
		- Script: 4c_national_regressions_restat.do
	- Table A3: ATUS Summary Statistics
		- File Name: Table created manually following stata output.
		- Script: search_term_correlations.do

- Figures:
	- Figure 1: Day-of-week Fixed Effects and Placebos
		- File Name: Day_of_Week_Effects.xlsx, dayofweekgraph.png, dayofweekgraph_placebo.png
		- Script: create_day_of_week_holiday_table.do, paper figure made in excel
	- Figure 2: Average Weeks Left by Type
		- File Name: weeks_left_by_type.png
		- Script: 4b_Make_Rothstein_weeks_left_by_user.do
	- Figure 3: News Articles Regarding EUC
		- File Name: national_euc.png
		- Script: news_analysis/news_figures.do
	- Figure 4: Dynamic Response to Changes in UI Generosity
		- File Name: jump_shock_pre_2012.pdf, drop_shock_post_2011.pdf
		- Script: 4d_new_panel_restat.R

**Software Versions:**
- R: Revo.version       _
> platform       x86_64-apple-darwin15.6.0
> arch           x86_64
> os             darwin15.6.0
> system         x86_64, darwin15.6.0
> status
> major          3
> minor          3.2
> year           2016
> month          10
> day            31
> language       R
> version.string Microsoft R Open version 3.3.2 (2016-11-18 17:31:12 UTC)

- Stata: version 11.2

**Data Files:**
- National
	- final_merged_data.dta (file used for national level regressions of job search on UI variables.)
	- rothstein_data.dta (CPS data from Rothstein BPEA, 2011)
	- Folder: Google_Data/StateMonth_2004_2016: Most up to date Google Data in flat files for state by month.
	- Folder: Google_Data/StateMont2004_2013_1: Data used in old working paper versions of the paper. Only goes through 2013.
	- Google_Data/*: Contains aggregations of Google data, either at a daily, weekly, or monthly level.
- ComScore:
	- comScore_analysis/all2007_final.dta: Data on job search time by user in comScore
	- comScore_analysis/idtostate.dta: map comScore to state
	- comScore_analysis/state_population.dta: state population
	- comScore_analysis/comscorestateday.dta: state by day comscore
- American Time Use Survey (ATUS):
	- Gooogle_Data/all_aux_term_monthly_new.dta, jobs search for ATUS analysis.
	- ATUS/AllCPSATUS.dta ATUS and CPS data.
	- ATUS/statejobssearch, state level trends jobs
	- ATUS/statelocalsearch, state level trends local jobs
	- ATUS/stateweathersearch, state level trends weather
	- ATUS/StateUnemployment.dta, state unemployment
	- ATUS/gestcenstate.dta, GestfipsGestCen.dta, state and fips codes for merging.
- Google News:
	- Google_Data/all_news_search_data: Data on news articles from Google.
- Texas Designated Metropolitan Area (DMA)
	- tx_msa_unemp.dta (TX Unemployment)
	- clean_tx_msa_unemp.dta (TX Unemployment - Clean)
	- final_weekly_search_data (Combined Texas Google Search Data)
	- number_affected_data.dta (For each expansion / dma, how many people affected by getting more weeks?)
	- soph_weeks_left_data.dta (For each dma / week, how many individuals with specified weeks left of UI (current law)?)
	- number_weeks_on_data.dta (For each dma / week, how many individuals with specified weeks on UI?)
	- tx_msa_pop.dta (Population of texas msas.)
	- soph_readyforweeklyregs.dta (Combined all relevant weekly data for Texas NLLS analysis)
	- TX_Weeks_Left_Data_Alt.dta (Weeks left maximum by week in Texas by UI program)
	- Google_Data/TexasDailyData_* : Folders with csv and dta files of Google Data through 2013.

