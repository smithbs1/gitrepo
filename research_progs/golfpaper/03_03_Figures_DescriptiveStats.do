clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\03_03_Figures_DescriptiveStats.txt, text replace


/*
forvalues t=1/2 {
if `t'==1 {
local exp_name WebTourML
local exp_var web
local exp_name2 "Web Tour ML"
local rest1=50 // restriction on how far to extend the graph to the right
}
if `t'==2 {
local exp_name QSchool
local exp_var qs
local exp_name2 "Q School"
local rest1=25 // restriction on how far to extend the graph to the right 
}
*/
/* I.) Count the number of treated golfers 
	in each experiment, in each year */
forvalues t=1/2 {
if `t'==1 {
local exp_name WebTourML
local exp_var web
}
if `t'==2 {
local exp_name QSchool
local exp_var qs
}
preserve
use data\sample_`exp_name'.dta, clear

/* Keep only necessary variables */
keep id-`exp_var'_position

/* Keep data only from experiment year */
keep if `exp_var'_time==0

/* Count the number of treated players
	by exemption status */
collapse (sum) n_`exp_var'_treat=`exp_var'_treat ///
		, by(`exp_var'_id_year `exp_var'_xmpt)
		
/* Reshape wide by exemption status */
reshape wide n_`exp_var'_treat, i(`exp_var'_id_year) j(`exp_var'_xmpt)
recode n_`exp_var'_treat0 (.=0)
recode n_`exp_var'_treat1 (.=0)
rename n_`exp_var'_treat0 n_`exp_var'_treat_nonxmpt
rename n_`exp_var'_treat1 n_`exp_var'_treat_xmpt
gen n_`exp_var'_treat=n_`exp_var'_treat_nonxmpt+n_`exp_var'_treat_xmpt

/* Format */
rename `exp_var'_id_year exp_year

/* Temp save */
tempfile n_`exp_var'treat
save "`n_`exp_var'treat'"
restore
}

/* Merge Web.com Tour ML and Q School counts together */
use "`n_webtreat'", clear
merge 1:1 exp_year using "`n_qstreat'", nogen


/* Plot number of treated golfers in each
	experiment year */

twoway ///
	(connected n_qs_treat_nonxmpt exp_year, ///
		m(triangle) lp(dash) lc("34 94 168") mlc("34 94 168") mfc("250 250 250")) ///
	(connected n_web_treat_nonxmpt exp_year, ///
		m(circle) lp(dash) lc("227 26 28") mlc("227 26 28") mfc("250 250 250")) ///
	(connected n_qs_treat exp_year, ///
		m(triangle) color("49 54 149")) ///
	(connected n_web_treat exp_year, ///
		m(circle) color("189 0 38")) ///
	, ///
	title("Treated golfers in each experiment by year", ///
		size(small) color("0 0 0") m(0 0 5 0)) ///
	xtitle("Experiment year", ///
		color("0 0 0") m(0 0 0 5)) ///
	ytitle("Number of treated golfers", ///
		color("0 0 0") m(0 5 0 0)) ///
	legend(order(3 "Q School (all)" 1 "Q School (non-exempt)" ///
		4 "Web.com ML (all)" 2 "Web.com ML (non-exempt)") ///
		ring(0) pos(4) col(1) symx(*.3) ///
		textwidth(*8) forcesize size(small) ///
		region(lcolor("220 220 220"))) ///
	ylabel(#6, angle(0) grid glc("250 250 250") glw(thin)) ///
	ymtick(##2, grid glc("250 250 250") glw(thin)) ///
	xlabel(1990(5)2010, angle(0) grid glc("250 250 250") glw(thin) ) ///	
	xmtick(##5, grid glc("250 250 250") glw(thin)) ///
	graphregion(color("255 255 255")) plotregion(color("235 235 235")) ///
	ysize(4) xsize(5.75) scale(.9)
graph set window fontface "Calibri"
graph export output\Figures\03_DescriptiveStats\01_test_TourCards.pdf, replace

cap log close
