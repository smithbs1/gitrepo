clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\02_01_01_Regression_RDRobust_MainResults.txt, text replace

/**********************************************************/
/*                                                        */
/*    2.I.) Estimate RD Robust regressions                */
/*			for both experiments.                         */
/*                                                        */
/**********************************************************/
set matsize 800

/****************************************************/
/*                                                  */
/*    2.I.I.) Restrict to experiment sample.        */ 
/*                                                  */ 
/****************************************************/ 

forvalues t=1/2 {
if `t'==1 {
local exp_name WebTourML
local exp_var web
local stderrors "nn 3"
}
if `t'==2 {
local exp_name QSchool
local exp_var qs
local stderrors "nncluster clusterid 3"
}
/* 2.I.I.a.) Import experiment estimation sample */
use data\sample_`exp_name'.dta , clear

/* 2.I.I.b.) Create a quadratic term in age 
	as a covariate */
gen `exp_var'_id_age2=`exp_var'_id_age^2

/* 2.I.I.c.) Create a variables with which to 
	cluster standard errors. Only clustering
	for Q School treatment because at the year
	level treatment can be assigned to groups
	if there are ties. */
egen clusterid=group(`exp_var'_id_position `exp_var'_id_year)

/* 2.I.I.d.) Create year dummies */
forvalues y=1990/2012 {
gen y_`y'=(`exp_var'_id_year==`y')
}

/**********************************************************/
/*                                                        */
/*    2.I.II.) Regress and export.                          */
/*                                                        */
/**********************************************************/

/* 2.I.II.a.) Loops for dependent variable, bandwidth type,
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
forvalues r=1/4 {
if `r'==1 {
local poly=1
local qpoly=2
local bwtype cerrd
}
if `r'==2 {
local poly=1
local qpoly=2
local bwtype mserd
}
if `r'==3 {
local poly=1
local qpoly=2
local bwtype certwo
}
if `r'==4 {
local poly=1
local qpoly=2
local bwtype msetwo
}

/* 2.I.II.b.) Set matrix */ 
matrix A= (. , . , . , . , . , . , . , . , . , ., . , . ///
		, . , . , . , . , . , . , . , . , . , . , . , .)

forvalues k=1/3 {
if `k'==1 {
local agerest 
}
if `k'==2 {
local agerest "& inrange(`exp_var'_id_age,17,30)" 
}
if `k'==3 {
local agerest "& inrange(`exp_var'_id_age,31,55)" 
}
forvalues e=1/2 {
if `e'==1 {
local exempt_rest "0"
}
if `e'==2 {
local exempt_rest "0,1"
}

forvalues i=-5/16 {

forvalues c=1/2 {
if `c'==1 {
local covs 
}
if `c'==2 & inrange(`i',-5,2) {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2012"
}
if `c'==2 & `i'==3 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2011"
}
if `c'==2 & `i'==4 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2010"
}
if `c'==2 & `i'==5 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2009"
}
if `c'==2 & `i'==6 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2008"
}
if `c'==2 & `i'==7 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2007"
}
if `c'==2 & `i'==8 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2006"
}
if `c'==2 & `i'==9 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2005"
}
if `c'==2 & `i'==10 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2004"
}
if `c'==2 & `i'==11 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2003"
}
if `c'==2 & `i'==12 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2002"
}
if `c'==2 & `i'==13 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2001"
}
if `c'==2 & `i'==14 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999-y_2000"
}
if `c'==2 & `i'==15 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997 y_1999"
}
if `c'==2 & `i'==16 {
local covs "`exp_var'_id_age `exp_var'_id_age2 `exp_var'_id_owgr y_1992-y_1997"
}

/* 2.I.II.c.) Regression equation */
di "exp=`exp_var', dvar=`dvar', bwtype=`bwtype' poly`poly', agerest=`agerest', year=`i'"
cap noisily rdrobust `dvar' `exp_var'_id_position ///
	if `exp_var'_time==`i' ///
	& inrange(`exp_var'_id_year,1992,2012) ///
	& inlist(`exp_var'_xmpt,`exempt_rest') ///
	`agerest'  ///
	, covs(`covs') bwselect(`bwtype') kernel(tri) ///
	p(`poly') q(`qpoly') vce(`stderrors') all

/* 2.I.II.d.) Collect regression results */
if _rc==0 {
scalar beta_l = e(tau_cl_l) 
scalar bc_beta_l = e(tau_bc_l)
scalar beta_r = e(tau_cl_r) 
scalar bc_beta_r = e(tau_bc_r)
scalar tau=e(tau_cl)*(-1)
scalar v=e(se_tau_cl)
scalar df=e(N_h_r)+e(N_h_l)-e(p)*2-2-3
scalar p=ttail(df,abs(e(tau_cl)/e(se_tau_cl)))*2
scalar bc_tau=e(tau_bc)*(-1)
scalar rob_v=e(se_tau_rb)
scalar bc_rob_p=ttail(df,abs(e(tau_bc)/e(se_tau_rb)))*2
scalar nl_eff = e(N_h_l)
scalar nr_eff = e(N_h_r)
scalar bl = e(h_l)
scalar br = e(h_r)
scalar N_l = e(N_l)
scalar N_r = e(N_r)
scalar N = e(N)
}
if _rc!=0 {
scalar beta_l=.
scalar bc_beta_l=.
scalar beta_r=.
scalar bc_beta_r=.
scalar tau=.
scalar v=.
scalar p=.
scalar bc_tau=.
scalar rob_v=.
scalar bc_rob_p=.
scalar nl_eff =.
scalar nr_eff =.
scalar bl =.
scalar br =.
scalar N_l = .
scalar N_r = .
scalar N = .
}
matrix a=(`t', `q', `r', `k', `c', `e', `i', beta_l, beta_r, tau, v , p , ///
	nl_eff, nr_eff , bl , br, bc_beta_l, bc_beta_r, bc_tau, rob_v, bc_rob_p, ///
	N_l, N_r, N)
matrix A = (A \ a )
}
}
}
}
preserve
/* 2.I.II.e.) Create dataset of regression results */
clear
matrix colnames A = exp dvar bwtype agerest cov_rest exempt_rest year limit_l limit_r treat_eff se pval N_l_eff ///
	N_r_eff bandw_l bandw_r biascorr_limit_l biascorr_limit_r biascorr_treat_eff ///
	robust_se biascorr_robust_pval N_l N_r N
local x1=rowsof(A)
local x2=colsof(A)
matrix A=A[2..`x1', 1..`x2']
svmat A, names(col)

/* 2.I.II.f.) Save results from each natural experiment */
tempfile results_`t'_`q'_`r'
save "`results_`t'_`q'_`r''"
restore
}
}
}

/* 2.I.II.g.) Append results from both experiments */
clear
forvalues t=1/2 {
forvalues q=1/49 {
forvalues r=1/4 {
append using "`results_`t'_`q'_`r''"
}
}
}

/* 2.I.II.h.) Label variables denoting different
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

label define bwtype_val 1 "CER, 1Side" 2 "MSE, 1Side" ///
		3 "CER, 2Side" 4 "MSE, 2Side", replace
label values bwtype bwtype_val

label define agerest_val 1 "None" 2 "<=30" 3 ">30", replace
label values agerest agerest_val

label define cov_rest_val 1 "nonexempt" 2 "all", replace
label values cov_rest cov_rest_val

label define exempt_rest_val 1 "nocovs" 2 "covs", replace
label values exempt_rest exempt_rest_val

/* 2.I.II.i.) Save */
sort exp dvar bwtype agerest cov_rest exempt_rest year
save output/Regressions/01_01_RegResults_RDRobust_MainResults.dta, replace
export excel output/Regressions/01_01_RegResults_RDRobust_MainResults.xlsx ///
	, firstrow(variables) sheetmodify sheet("results") cell(B1) 

cap log close

