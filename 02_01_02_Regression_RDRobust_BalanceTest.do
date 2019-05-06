clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\02_01_02_Regression_RDRobust_BalanceTest.txt, text replace

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
local stderrors "nncluster `exp_var'_id_age 3"
}
if `t'==2 {
local exp_name QSchool
local exp_var qs
local stderrors "nncluster `exp_var'_id_age 3"
}
/* 2.I.I.a.) Import experiment estimation sample */
use data\sample_`exp_name'.dta , clear

/* 2.I.I.b.) Create a quadratic term in age 
	as a covariate */
gen `exp_var'_id_age2=`exp_var'_id_age^2

/* 2.I.I.c.) Create year dummies */
forvalues y=1990/2012 {
gen y_`y'=(`exp_var'_id_year==`y')
}

/**********************************************************/
/*                                                        */
/*    2.I.II.) Regress and export.                         */
/*                                                        */
/**********************************************************/
/* 2.I.II.a.) Loops for dependent variable, bandwidth type,
	age restriction, and years past experiment */
forvalues q=1/27 {
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
local dvar ihs_money_world
}
if `q'==6 {
local dvar ihs_money_usa_tot
}
if `q'==7 {
local dvar ihs_money_pga_tot
}
if `q'==8 {
local dvar ihs_money_web_tot
}
if `q'==9 {
local dvar lcpmoney_world
}
if `q'==10 {
local dvar lcpmoney_usa_tot
}
if `q'==11 {
local dvar lcpmoney_pga_tot
}
if `q'==12 {
local dvar ihs_cpmoney_world
}
if `q'==13 {
local dvar ihs_cpmoney_usa_tot
}
if `q'==14 {
local dvar ihs_cpmoney_pga_tot
}
if `q'==15 {
local dvar pos_money_world
}
if `q'==16 {
local dvar pos_money_usa_tot
}
if `q'==17 {
local dvar pos_money_pga_tot
}
if `q'==18 {
local dvar pos_money_web_tot
}
if `q'==19 {
local dvar events_usa_tot
}
if `q'==20 {
local dvar events_usa_off
}
if `q'==21 {
local dvar events_pga_total
}
if `q'==22 {
local dvar events_pga_off
}
if `q'==23 {
local dvar events_web_total
}
if `q'==24 {
local dvar ontour_pga_off
}
if `q'==25 {
local dvar adj_rel_score
}
if `q'==26 {
local dvar owgr
}
if `q'==27 {
local dvar age
}

forvalues r=2/2 {
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
/* Set matrix */ 
matrix A= (. , . , . , . , . , . , . , . , . , ., . , . ///
		, . , . , . , . , . , . , . , . , . , . , . , .)
forvalues k=1/1 {
if `k'==1 {
local agerest 
}
if `k'==2 {
local agerest "& inrange(`exp_var'_id_age,17,30)"
}
if `k'==3 {
local agerest "& inrange(`exp_var'_id_age,31,55)" 
}
forvalues c=1/2 {
if `c'==1 {
local covs 
}
if `c'==2 {
local covs "y_1992-y_1997 y_1999-y_2012"
}
forvalues e=1/2 {
if `e'==1 {
local exempt_rest "0"
}
if `e'==2 {
local exempt_rest "0,1"
}

forvalues i=-5/0 {
/* 2.I.II.c.) Regression equation */
di "exp=`exp_var', dvar=`dvar', bwtype=`bwtype' poly`poly', agerest=`agerest', lag_year=`i'"
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
forvalues q=1/27 {
forvalues r=2/2 {
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
		5 "IHS world earnings" 6 "IHS tot US earnings" ///
		7 "IHS tot PGA earnings" 8 "IHS tot Web earnings" ///
		9 "Log cum past world earnings" 10 "Log cum past tot US earnings" ///
		11 "Log cum past tot PGA earnings" 12 "IHS cum past world earnings" ///
		13 "IHS cum past tot US earnings" 14 "IHS cum past tot PGA earnings" ///
		15 "Positive world earnings" 16 "Positive tot US earnings" ///
		17 "Positive tot PGA earnings" 18 "Positive tot Web earnings" ///
		19 "Tot US events" 20 "Off US events" 21 "Tot PGA events" ///
		22 "Off PGA events" 23 "Tot Web events" ///
		24 "On PGA TOUR, 20+ off events" 25 "Mean adj relative score" ///
		26 "Year-end OWGR" 27 "Age", replace
label values dvar dvar_val

label define bwtype_val 1 "CER, 1Side" 2 "MSE, 1Side" ///
		3 "CER, 2Side" 4 "MSE, 2Side", replace
label values bwtype bwtype_val

label define agerest_val 1 "None" 2 "<=30" 3 ">30", replace
label values agerest agerest_val

label define cov_rest_val 1 "None" 2 "Year effects", replace
label values cov_rest cov_rest_val

label define exempt_rest_val 1 "Drop exempt" 2 "All", replace
label values exempt_rest exempt_rest_val

/* 2.I.II.i.) Save */
save output/Regressions/01_02_RegResults_RDRobust_SampleBalance.dta, replace
export excel output/Regressions/01_02_RegResults_RDRobust_SampleBalance.xlsx ///
	, firstrow(variables) sheetmodify sheet("results") cell(B1) 

cap log close

