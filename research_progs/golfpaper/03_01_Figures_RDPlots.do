clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\03_01_Figures_RDPlots.txt, text replace

/**********************************************************/
/*                                                        */
/*    2.I.) Estimate RD Robust regressions                */
/*			for both experiments.                         */
/*                                                        */
/**********************************************************/

/****************************************************/
/*                                                  */
/*    2.I.I.) Restrict to experiment sample.        */ 
/*                                                  */ 
/****************************************************/ 

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
local rest1=20 // restriction on how far to extend the graph to the right 
}
/* 2.I.I.a.) Import experiment estimation sample */
use data\sample_`exp_name'.dta , clear

/**********************************************************/
/*                                                        */
/*    2.I.II.) Regress and export.                        */
/*                                                        */
/**********************************************************/

/* 2.I.II.a.) Loops for dependent variable, bandwidth type,
	age restriction, and years past experiment */
forvalues q=1/27 {
if `q'==1 {
local dvar lmoney_world
local yname "Log World Money"
local q2="01"
}
if `q'==2 {
local dvar lmoney_pga_tot
local yname "Log PGA TOUR Money"
local q2="02"
}
if `q'==3 {
local dvar lmoney_web_tot 
local yname "Log Web.com Tour Money"
local q2="03"
}
if `q'==4 {
local dvar ihs_money_world
local yname "IHS World Money"
local q2="04"
}
if `q'==5 {
local dvar ihs_money_pga_tot
local yname "IHS PGA TOUR Money"
local q2="05"
}
if `q'==6 {
local dvar ihs_money_web_tot
local yname "IHS Web.com Tour Money"
local q2="06"
}
if `q'==7 {
local dvar lcpmoney_world
local yname "Lifetime Log World Money"
local q2="07"
}
if `q'==8 {
local dvar lcpmoney_usa_tot
local yname "Lifetime Log US Money"
local q2="08"
}
if `q'==9 {
local dvar lcpmoney_pga_tot
local yname "Lifetime Log PGA TOUR Money"
local q2="09"
}
if `q'==10 {
local dvar ihs_cpmoney_world
local yname "Lifetime IHS World Money"
local q2="10"
}
if `q'==11 {
local dvar ihs_cpmoney_usa_tot
local yname "Lifetime IHS US Money"
local q2="11"
}
if `q'==12 {
local dvar ihs_cpmoney_pga_tot
local yname "Lifetime IHS PGA TOUR Money"
local q2="12"
}
if `q'==13 {
local dvar pos_money_world
local yname "Positive World Money"
local q2="13"
}
if `q'==14 {
local dvar pos_money_pga_tot
local yname "Positive PGA TOUR Money"
local q2="14"
}
if `q'==15 {
local dvar pos_money_web_tot
local yname "Positive Web.com Tour Money"
local q2="15"
}
if `q'==16 {
local dvar events_usa_tot
local yname "Total US Events"
local q2="16"
}
if `q'==17 {
local dvar events_usa_off
local yname "Official US Events"
local q2="17"
}
if `q'==18 {
local dvar events_pga_total
local yname "Total PGA TOUR Events"
local q2="18"
}
if `q'==19 {
local dvar events_pga_off
local yname "Official PGA TOUR Events"
local q2="19"
}
if `q'==20 {
local dvar events_web_total
local yname "Total Web.com Tour Events"
local q2="20"
}
if `q'==21 {
local dvar ontour_pga_off
local yname "PGA TOUR 'Member'"
local q2="21"
}
if `q'==22 {
local dvar adj_rel_score
local yname "Season Scoring Average"
local q2="22"
}
if `q'==23 {
local dvar owgr
local yname "OWGR"
local q2="23"
}
if `q'==24 {
local dvar age
local yname "Age"
local q2="24"
}
/* 2.I.II.c.) Adjust by year means:
	Adjust all to 1998 level: This is 
	the most recent year with 16 years
	in the future. (15 years in the past
	as well).*/
bysort `exp_var'_time `exp_var'_id_year: egen y1=mean(`dvar')
gen y2=y1 if `exp_var'_id_year==1998
sort `exp_var'_time `exp_var'_id_year `exp_var'_id
by `exp_var'_time: egen y3=mean(y2)
gen y4=y3-y1
gen y=`dvar'+y4
drop y1-y4
sort `exp_var'_id `exp_var'_id_year `exp_var'_time 


foreach i in -3 -2 -1 0 1 2 3 4 5 6 10 14 {
if inlist(`i',-3,-2,-1,0) {
local step lag
local year_text1=-1*`i'
local year_text2="0`year_text1'"
local k=1
}
if inlist(`i',1,2,3,4,5,6) {
local step lead
local year_text2="0`i'"
local k=2
}
if inlist(`i',10,14) {
local step lead
local year_text2="`i'"
local k=2
}

/* 2.I.II.d.) Regression equation */
di "exp=`exp_var', dvar=`dvar', year=`i'"
set more off
noisily cap rdplot y `exp_var'_id_position ///
	if `exp_var'_time==`i' & inlist(`exp_var'_xmpt,0) ///
	& `exp_var'_id_position<=`rest1' ///
	, c(0) kernel(uniform) binselect(qsmv) ///
	graph_options( ///
		title("`exp_name2', `step' `i' year: Plot of binned values of `yname' at treatment threshold", ///
			size(small) color("0 0 0") m(0 0 5 0)) ///
		xtitle("Position relative to `exp_name2' treatment threshold", ///
			color("0 0 0") m(0 0 0 5)) ///
		ytitle("`yname'", ///
			color("0 0 0") m(0 5 0 0)) ///
		legend(cols(1) ring(0) pos(2) symx(*.4) textwidth(*8) forcesize size(small)) ///
		xlabel(#10,grid glc("255 255 255") glw(thin)) ///
		xmtick(##2, grid glc("255 255 255") glw(thin)) ///
		ylabel(#8,angle(0) gmin gmax grid glc("255 255 255") glw(thin)) ///
		ymtick(##2, grid glc("255 255 255") glw(thin)) ///
		graphregion(color("255 255 255")) plotregion(color("235 235 235")) ///
		ysize(4) xsize(5.75))
gr_edit .plotregion1.plot1.style.editstyle marker(fillcolor("49 54 149")) editcopy
gr_edit .plotregion1.plot1.style.editstyle marker(linestyle(color("49 54 149"))) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(color("165 0 38")) editcopy
gr_edit .plotregion1.plot2.style.editstyle line(pattern(dash)) editcopy
gr_edit .plotregion1.plot3.style.editstyle line(pattern(dash)) editcopy
graph set window fontface "Calibri"
di "exp=`exp_var', dvar=`dvar', year=`i', return code=" _rc
if _rc==0 {
graph export output\Figures\01_RDPlots\0`t'_`q2'_0`k'_`exp_name'_`dvar'_`step'year`year_text2'.pdf, replace
}
}
drop y
}
}
cap log close

