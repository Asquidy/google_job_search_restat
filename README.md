# Replication Repository: "The Impact of Unemployment Insurance on Job Search: Evidence from Google Search Data"
This file contains information regarding data files, scripts, paper results, and software versions for the paper:

*The Impact of Unemployment Insurance on Job Search: Evidence from Google Search Data*


**TODO: Rename / Add Folder Names for Scripts**
**Figure 4 axis style**

**Data Files:**
- Google Data:
	- National
	- State by Month 
	- Texas Designated Metropolitan Area (DMA)
- NLSY:
- ComScore:
- American Time Use Survey (ATUS):
- Texas UI Data:
	**Where does this come from?**
	- Texas unemployment by MSA: tx_msa_unemp.dta, clean_tx_msa_unemp.dta
		- Important Variables:
	- TX_Weeks_Left_Data_Alt
		
**Code:**
- Main Analysis Code:
	- 0_assign_msa_to_tx_data.do, Clean Texas Unemployment by MSA Data
	- 1a_google_tx_daily.do, Combine raw Google daily data for Texas

**Results:**
- Tables:
	- Table 2: Correlation of Google Search to Online Job Search Time - comScore Data
		- File Name: GooglecomScore.tex
		- Script: 2. Make ComScore Table.do
	- Table 3: ATUS Search Time Correlation
		- File Name: ??? ATUSCorr.tex
		- Script: 1. FinalWorking - State.
	- Table 4: Day of Week Fixed Effects for Google, comScore, and ATUS
		- File Name: holiday_dow.tex
		- Script: 2. Make ATUS comScore Table.do
	- Table 5: Empirical Tests of Google Job Search Measure
		- File Name: Table1.tex
		- Script: Make Empirical Test Table.do
	- Table 6: Effect of UI Status and Composition on Job Search (Non-linear Least Squares)
		- File Name: nllsregs_current_law.tex
		- Script: 3_nlls_cur_law.do
	- Table 7: Effects of UI Expansions and Composition by State 
		- File Name: national_regs_new_restat.tex
		- Script: 4c_national_regressions_restat.do
	- Table 8: Event Study Regression Results. 
		- File Name: all_impulse.tex
		- Script: 4d_new_panel_restat.R

	- **TODO** Table A1: Google Search Term Correlations
		- File Name: ???
		- Script: ??? 
	- Table A2: Change in log(GJSI) Following Expansions: Robustness
		- File Name: robust_expansion_restat.tex
		- Script: 4c_national_regressions_restat.do
	- Table A3: ATUS Summary Statistics
		- File Name: Table created manually following stata output.
		- Script: "1. FinalWorking - State.do"

- Figures:
	- Figure 1: Day-of-week Fixed Effects and Placebos
		- File Name: Day_of_Week_Effects.xlsx, dayofweekgraph.png, dayofweekgraph_placebo.png
		- Script: "Make ATUS comScore Table.do ", paper figure made in excel
	- Figure 2: Average Weeks Left by Type
		- File Name: weeks_left_by_type.png
		- Script: 4b_Make_Rothstein_weeks_left_by_user.do
	- Figure 3: News Articles Regarding EUC
		- File Name: national_euc.png
		- Script: 2. Graphs with Texas and Nation.do
	- **TODO axis label size** Figure 4: Dynamic Response to Changes in UI Generosity
		- File Name: jump_shock_pre_2012.pdf, drop_shock_post_2011.pdf
		- Script: 4d_new_panel_restat.R
- Other:
	- NLSY:
	- CPS:

**Software Version:**
- R:
- Stata: 