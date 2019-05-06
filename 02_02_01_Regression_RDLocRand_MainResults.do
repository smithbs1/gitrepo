clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\02_02_01_Regression_RDLocRand_MainResults.txt, text replace

/**********************************************************/
/*                                                        */
/*    2.II.) Estimate RD Local Randomization regressions  */
/*			for both experiments.                         */
/*                                                        */
/**********************************************************/
set matsize 800

/****************************************************/
/*                                                  */
/*    2.II.I.) Restrict to experiment sample.       */ 
/*                                                  */ 
/****************************************************/ 

forvalues t=1/2 {
if `t'==1 {
local exp_name WebTourML
local exp_var web
local win0 1.5
local win1 2.5
}
if `t'==2 {
local exp_name QSchool
local exp_var qs
local win0 0.5
local win1 1.5
}
/* 2.I.I.a.) Import experiment estimation sample */
use data\sample_`exp_name'.dta , clear

/* 2.I.I.b.) Drop exempt golfers */
drop if `exp_var'_xmpt==1

/* 2.I.I.c.) Create a quadratic term in age 
	as a covariate */
gen age2=age^2

/* 2.I.I.d.) Create age groups to look for
	heterogeneous effects */
gen agegroup=1 if inrange(age,17,30)
replace agegroup=2 if inrange(age,31,55)

/* 2.I.I.e.) Create a group to cluster standard 
	errors on */
egen clusterid=group(`exp_var'_position)

/* 2.I.I.f. Set panel structure */
egen `exp_var'_id2=group(`exp_var'_id)
tsset `exp_var'_id2 year

/**********************************************************/
/*                                                        */
/*    2.II.II.) Regress and export.                       */
/*                                                        */
/**********************************************************/

/* 2.II.II.a.) Loops for dependent variable, bandwidth type,
	age restriction, and years past experiment */
forvalues q=1/49 {
if `q'==1 {
local dvar lmoney_world
}
if `q'==2 {
local dvar lmoney_usa_tot
}
if `q'==3 {
local dvar lmoney_pga_tot
}
if `q'==4 {
local dvar lmoney_web_tot 
}
if `q'==5 {
local dvar lmoney_euro_off
}
if `q'==6 {
local dvar lmoney_tier2 
}
if `q'==7 {
local dvar ihs_money_world
}
if `q'==8 {
local dvar ihs_money_usa_tot
}
if `q'==9 {
local dvar ihs_money_pga_tot
}
if `q'==10 {
local dvar ihs_money_web_tot
}
if `q'==11 {
local dvar ihs_money_euro_off
}
if `q'==12 {
local dvar ihs_money_tier2
}
if `q'==13 {
local dvar lcpmoney_world
}
if `q'==14 {
local dvar lcpmoney_usa_tot
}
if `q'==15 {
local dvar lcpmoney_pga_tot
}
if `q'==16 {
local dvar ihs_cpmoney_world
}
if `q'==17 {
local dvar ihs_cpmoney_usa_tot
}
if `q'==18 {
local dvar ihs_cpmoney_pga_tot
}
if `q'==19 {
local dvar pos_money_world
}
if `q'==20 {
local dvar pos_money_usa_tot
}
if `q'==21 {
local dvar pos_money_pga_tot
}
if `q'==22 {
local dvar pos_money_web_tot
}
if `q'==23 {
local dvar retire_money_world
}
if `q'==24 {
local dvar events_usa_tot
}
if `q'==25 {
local dvar events_usa_off
}
if `q'==26 {
local dvar events_pga_total
}
if `q'==27 {
local dvar events_pga_off
}
if `q'==28 {
local dvar events_web_total
}
if `q'==29 {
local dvar events_euro_off
}
if `q'==30 {
local dvar pos_events_usa_tot
}
if `q'==31 {
local dvar pos_events_pga_tot
}
if `q'==32 {
local dvar pos_events_web_tot
}
if `q'==33 {
local dvar pos_events_euro_off
}
if `q'==34 {
local dvar retire_events_usa
}
if `q'==35 {
local dvar ontour_pga_off
}
if `q'==36 {
local dvar adj_rel_score
}
if `q'==37 {
local dvar rel_score
}
if `q'==38 {
local dvar score
}
if `q'==39 {
local dvar purse_mean_all_total
}
if `q'==40 {
local dvar owgr
}
if `q'==41 {
local dvar lomean_field_owgr
}
if `q'==42 {
local dvar money_world
}
if `q'==43 {
local dvar money_usa_tot
}
if `q'==44 {
local dvar money_pga_tot
}
if `q'==45 {
local dvar money_web_tot
}
if `q'==46 {
local dvar cond_money_world
}
if `q'==47 {
local dvar cond_money_usa_tot
}
if `q'==48 {
local dvar cond_money_pga_tot
}
if `q'==49 {
local dvar cond_money_web_tot
}
forvalues r=0/1 {

/* 2.II.II..b.) Set matrix */ 
matrix A= (. , . , . , . , . , . , . , . , . , . ///
		, . , . , . )

forvalues k=1/3 {
forvalues i=1/16 {

/* 2.II.II.c.) Impose age restriction */
preserve
if `k'==1 {

}
if `k'==2 {
keep if agegroup==1
}
if `k'==3 {
keep if agegroup==2
}

/* 2.II.II.d.) Create dependent variable */
gen y=f`i'.`dvar'

/* 2.II.II.e.) Regression equation */
di "exp=`exp_var', dvar=`dvar', poly deg=`r', agerest=`agerest', year=`i'"
capture noisily rdrandinf y `exp_var'_position, ///
		wl(-`win`r'') wr(`win`r'') ci(.05) p(`r')
drop y
restore

/* 2.II.II.f.) Collect regression results */
if _rc==0 {
scalar treat = r(obs_stat)*(-1)
scalar pval = r(randpval) 
scalar ci_lb = r(ci_lb) 
scalar ci_ub  = r(ci_ub)
scalar N_l = r(N_left)
scalar N_r = r(N_right)
scalar bandw_l = r(wl)
scalar bandw_r = r(wr)
}
if _rc!=0 {
scalar treat = .
scalar pval = .
scalar ci_lb = . 
scalar ci_ub = .
scalar N_l = .
scalar N_r = .
scalar bandw_l = .
scalar bandw_r = .
}
matrix a=(`t', `q', `r', `k', `i', treat, pval, ci_lb, ci_ub, N_l, N_r , bandw_l, bandw_r)
matrix A = (A \ a )
}
}
preserve
/* 2.II.II.g.) Create dataset of regression results */
clear
matrix colnames A = exp dvar deg_poly agerest year treat pval ci_lb ci_ub ///
	N_l N_r bandw_l bandw_r
local x1=rowsof(A)
local x2=colsof(A)
matrix A=A[2..`x1', 1..`x2']
svmat A, names(col)

/* 2.II.II.fh.) Save results from each natural experiment */
tempfile results_`t'_`q'_`r'
save "`results_`t'_`q'_`r''"
restore
}
}
}
/* 2.I.II.i.) Append results from both experiments */
clear
forvalues t=1/2 {
forvalues q=1/49 {
forvalues r=0/1 {
append using "`results_`t'_`q'_`r''"
}
}
}

/* 2.I.II.j.) Label variables denoting different
	sets of results */
label define exp_val 1 "Web.com Tour ML" 2 "Q School" , replace
label values exp exp_val

label define dvar_val 1 "Log world earnings" 2 "Log tot US earnings" ///
		3 "Log tot PGA earnings" 4 "Log tot Web earnings" ///
		5 "Log off Euro earnings" 6 "Log tier 2 earnings" ///
		7 "IHS world earnings" 8 "IHS tot US earnings" ///
		9 "IHS tot PGA earnings" 10 "IHS tot Web earnings" ///
		11 "IHS off Euro earnings" 12 "IHS tier 2 earnings" ///
		13 "Log cum past world earnings" 14 "Log cum past tot US earnings" ///
		15 "Log cum past tot PGA earnings" 16 "IHS cum past world earnings" ///
		17 "IHS cum past tot US earnings" 18 "IHS cum past tot PGA earnings" ///
		19 "Positive world earnings" 20 "Positive tot US earnings" ///
		21 "Positive tot PGA earnings" 22 "Positive tot Web earnings" ///
		23 "Retired from world earnings" 24 "Tot US events" ///
		25 "Off US events" 26 "Tot PGA events" ///
		27 "Off PGA events" 28 "Tot Web events" ///
		29 "Off Euro events" 30 "Positive tot US events" ///
		31 "Positive tot PGA events" 32 "Positive tot Web events" ///
		33 "Positive off Euro events" 34 "Retired from tot US events" ///
		35 "On PGA TOUR, 20+ off events" 36 "Mean adj relative score" ///
		37 "Mean relative score" 38 "Mean score" ///
		39 "Mean purse tot US events" 40 "Year-end OWGR" ///
		41 "Mean field quality, lo-mean field owgr" 42 "World earnings" ///
		43 "Tot US earnings" 44 "Tot PGA earnings" ///
		45 "Tot Web earnings" 46 "World earnings | pos earn" ///
		47 "Tot US earnings | pos earn" 48 "Tot PGA earnings | pos earn" ///
		49 "Tot Web earnings | pos earn", replace
label values dvar dvar_val

label define deg_poly_val 0 "Deg Poly 0" 1 "Deg Poly 1", replace
label values deg_poly deg_poly_val

label define agerest_val 1 "None" 2 "<=30" 3 ">30", replace
label values agerest agerest_val

/* 2.I.II.k.) Save */
save output/Regressions/01_01_RegResults_RDLocRand_MainResults.dta, replace

cap log close
