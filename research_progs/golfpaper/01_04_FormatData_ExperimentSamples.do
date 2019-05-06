clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\01_04_FormatData_ExperimentSamples.txt, text replace

/*************************************************/
/*                                               */
/*   1.IV.) CREATE NATURAL EXPERIMENT SAMPLES    */
/*                                               */
/*   - From Q School and Web.com Tour ML         */
/*                                               */
/*************************************************/


/****************************************************************/
/*  1.IV.1.) Create a grid for every golfer in each experiment  */
/****************************************************************/
forvalues j=1/2 {

if `j'==1 {
local exp qs
local opp web
local name QSchool
}
if `j'==2 {
local exp web
local opp qs
local name WebTourML
}

use data\years_AllTours.dta, clear

/* 1.IV.1.a.) Restrict to experiment samples */
keep if inlist(`exp'_treat,0,1)

/* 1.IV.1.b.) Restrict to experiment year where
	I have data from both Q School and the Web.com Tour ML.
	Q School ends in 2012. I am ending the analysis the Web.com
	Tour ML there as well because the landscape changes quite
	signifcantly at this point. */
drop if inlist(year,2013,2014)

/* 1.IV.1.c.) Create experiment id for every potential 
	treatment instance */
sort id year
by id: gen n=_n
order n, after(id)
tostring id, gen(id_str)
tostring n, gen(n_str)
forvalues num=1/9 {
replace n_str="0`num'" if n_str=="`num'"
}
gen `exp'_id= id_str + "-" + n_str
order `exp'_id, after(id)
drop id_str n n_str
gen `exp'_id_year=year
order `exp'_id_year, after(year)

/* 1.IV.1.d.) Keep only necessary variables */ 	
keep id `exp'_id `exp'_treat `exp'_position ///
	`exp'_id_year player yob owgr cntry_code `exp'_xmpt ///
	`exp'_xmpt_medical `exp'_xmpt_pastchampions ///
	`exp'_xmpt_battlefield

/* 1.IV.1.e.) Drop if don't have YOB */
drop if yob==.

/* 1.IV.1.f.) Create variables at time of experiment */
rename `exp'_treat `exp'_id_treat
rename `exp'_position `exp'_id_position
gen `exp'_id_age=`exp'_id_year-yob
rename owgr `exp'_id_owgr
order `exp'_id_treat `exp'_id_position `exp'_id_age `exp'_id_owgr, after(`exp'_id_year)

/* 1.IV.1.g.) Create grid from 1983 to 2014 */
expand 32
bysort `exp'_id: gen year=_n+1982

/* 1.IV.1.h.) Create age */
gen age=year-yob
order year age yob, after(cntry_code)

/* 1.IV.1.i.) Keep if age is between 17 and 55 */
keep if inrange(age,17,55)

/*  1.IV.2.) Merge grid to annual-level data    */
merge m:1 id year using data\years_AllTours.dta
drop if _merge==2
drop _merge
sort `exp'_id year
drop xmpt* `opp'_xmpt*

/*  1.IV.3.) Create a time variable relative to
	the initial experiment year */
gen `exp'_time = year-`exp'_id_year
order `exp'_time, after(`exp'_id_year)

* format
label variable year "Year"
label variable age "Age"
if `j'==1 {
label variable qs_id "Unique ID at the player-QSchool experiment year level"
}
if `j'==2 {
label variable web_id "Unique ID at the player-Web.com ML experiment year level"
}

/* 1.IV.4.) Recode money and variables so that 
	"." is "0" for the appropriate years */

foreach i in money_pga_ events_pga_ wins_pga_ {
foreach j in off unoff total {
recode `i'`j' (.=0) if inrange(year,1983,2014)
}
}
foreach i in money_web_ events_web_ wins_web_ {
foreach j in off unoff total {
recode `i'`j' (.=0) if inrange(year,1990,2014)
}
}
foreach i in events money {
recode `i'_euro_off (.=0) if inrange(year,1980,2014)
recode `i'_chall_off (.=0) if inrange(year,1990,2014)
}
recode money_euro_off_NOdcount (.=0) if inrange(year,1980,2014)
/* only have career money from the Australasian Tour
	from 1980 to 2010 and its not clear whether it
	is comprehensive or not. Annual data from 2011 to 2014 */
recode money_aus (.=0) if inrange(year,2011,2014)
foreach i in events money {
recode `i'_japan (.=0) if inrange(year,1985,2014)
}
/* only have career money from the Asian Tour
	from 1993 to 2003 and it only includes the top 
	100 career earners. Annual data from 2004 to 2014 */
foreach i in events money {
recode `i'_asian (.=0) if inrange(year,2004,2014)
}
foreach i in events money {
recode `i'_sun (.=0) if inrange(year,1991,2014)
}

/* Denote 0's for US,  World, and Tier 2 Earnings  */
recode money_world (.=0) if inrange(year,1983,2014)
recode money_usa_tot (.=0) if inrange(year,1983,2014)
recode money_usa_off (.=0) if inrange(year,1983,2014)
recode money_tier2 (.=0) if inrange(year,1985,2014)

/* 1.IV.5.) Recode OWGR to max value if empty */
sort year
by year: egen x=max(max_owgr)
replace max_owgr=x
drop x
replace owgr=max_owgr if owgr==.
sort `exp'_id year

/* 1.IV.6.) Generate log earnings */
foreach i in world usa_tot usa_off pga_tot pga_off web_tot web_off euro_off euro_off_NOdcount tier2 {
gen lmoney_`i'=log(money_`i')
}
label variable lmoney_world "Log earnings from all tours"
label variable lmoney_usa_tot "Log Unoff + Off earnings from PGA & Web"
label variable lmoney_usa_off "Log Off earnings from PGA & Web"
label variable lmoney_pga_tot "Log Unoff + Off earnings from PGA"
label variable lmoney_pga_off "Log Off earnings from PGA"
label variable lmoney_web_tot "Log Unoff + Off earnings from PGA"
label variable lmoney_web_off "Log Off earnings from PGA"
label variable lmoney_euro_off "Log Off earnings from Euro"
label variable lmoney_tier2 "Log Off earnings from tier 2 tours"

/* 1.IV.7.) Generate ihs earnings */
foreach i in world usa_tot usa_off pga_tot pga_off web_tot web_off euro_off euro_off_NOdcount tier2 {
gen ihs_money_`i'=log(money_`i'+(money_`i'^2+1)^(1/2))
}
label variable ihs_money_world "IHS earnings from all tours"
label variable ihs_money_usa_tot "IHS Unoff + Off earnings from PGA & Web"
label variable ihs_money_usa_off "IHS Off earnings from PGA & Web"
label variable ihs_money_pga_tot "IHS Unoff + Off earnings from PGA"
label variable ihs_money_pga_off "IHS Off earnings from PGA"
label variable ihs_money_web_tot "IHS Unoff + Off earnings from PGA"
label variable ihs_money_web_off "IHS Off earnings from PGA"
label variable ihs_money_euro_off "IHS Off earnings from Euro"
label variable ihs_money_tier2 "IHS Off earnings from tier 2 tours"

/* 1.IV.8.) Generate positive earnings */
foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
gen pos_money_`i' = (money_`i'>0)
replace pos_money_`i'=. if missing(money_`i') 
}
label variable pos_money_world "Positive earnings from any tour"
label variable pos_money_usa_tot "Positive earnings from PGA or Web"
label variable pos_money_pga_tot "Positive earnings from PGA"
label variable pos_money_web_tot "Positive earnings from Web"
label variable pos_money_euro_off "Positive earnings from Euro"
label variable pos_money_tier2 "Positive earnings from any tier 2 tour"

/* 1.IV.9.) Generate cumulative past earnings */
sort `exp'_id year
foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
by `exp'_id: gen cpmoney_`i'=sum(money_`i')
}
label variable cpmoney_world "Cumulative past earnings from all tours"
label variable cpmoney_usa_tot "Cumulative past earnings from PGA and Web"
label variable cpmoney_pga_tot "Cumulative past earnings from PGA"
label variable cpmoney_web_tot "Cumulative past earnings from Web"
label variable cpmoney_euro_off "Cumulative past earnings from Euro"
label variable cpmoney_tier2 "Cumulative past earnings from any tier 2 tour"

/* 1.IV.10.) Generate cumulative future earnings */
gsort `exp'_id -year
foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
by `exp'_id: gen cfmoney_`i'=sum(money_`i')
}
label variable cfmoney_world "Cumulative future earnings from all tours"
label variable cfmoney_usa_tot "Cumulative future earnings from PGA and Web"
label variable cfmoney_pga_tot "Cumulative future earnings from PGA"
label variable cfmoney_web_tot "Cumulative future earnings from Web"
label variable cfmoney_euro_off "Cumulative future earnings from Euro"
label variable cfmoney_tier2 "Cumulative future earnings from any tier 2 tour"
sort `exp'_id year

/* 1.IV.11.) Generate log cumulative past and future earnings */
foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
gen lcpmoney_`i'=log(cpmoney_`i')
}
label variable lcpmoney_world "Log cumulative past earnings from all tours"
label variable lcpmoney_usa_tot "Log cumulative past earnings from PGA and Web"
label variable lcpmoney_pga_tot "Log cumulative past earnings from PGA"
label variable lcpmoney_web_tot "Log cumulative past earnings from Web"
label variable lcpmoney_euro_off "Log cumulative past earnings from Euro"
label variable lcpmoney_tier2 "Log cumulative past earnings from any tier 2 tour"

foreach i in world usa_tot pga_tot web_tot euro_off tier2 {
gen lcfmoney_`i'=log(cfmoney_`i')
}
label variable lcfmoney_world "Log cumulative future earnings from all tours"
label variable lcfmoney_usa_tot "Log cumulative future earnings from PGA and Web"
label variable lcfmoney_pga_tot "Log cumulative future earnings from PGA"
label variable lcfmoney_web_tot "Log cumulative future earnings from Web"
label variable lcfmoney_euro_off "Log cumulative future earnings from Euro"
label variable lcfmoney_tier2 "Log cumulative future earnings from any tier 2 tour"

/* 1.IV.12.) Generate ihs cumulative past and future earnings */
foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
gen ihs_cpmoney_`i'=log(cpmoney_`i'+(cpmoney_`i'^2+1)^(1/2))
}
label variable ihs_cpmoney_world "IHS cumulative past earnings from all tours"
label variable ihs_cpmoney_usa_tot "IHS cumulative past earnings from PGA and Web"
label variable ihs_cpmoney_pga_tot "IHS cumulative past earnings from PGA"
label variable ihs_cpmoney_web_tot "IHS cumulative past earnings from Web"
label variable ihs_cpmoney_euro_off "IHS cumulative past earnings from Euro"
label variable ihs_cpmoney_tier2 "IHS cumulative past earnings from any tier 2 tour"

foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
gen ihs_cfmoney_`i'=log(cfmoney_`i'+(cfmoney_`i'^2+1)^(1/2))
}
label variable ihs_cfmoney_world "IHS cumulative future earnings from all tours"
label variable ihs_cfmoney_usa_tot "IHS cumulative future earnings from PGA and Web"
label variable ihs_cfmoney_pga_tot "IHS cumulative future earnings from PGA"
label variable ihs_cfmoney_web_tot "IHS cumulative future earnings from Web"
label variable ihs_cfmoney_euro_off "IHS cumulative future earnings from Euro"
label variable ihs_cfmoney_tier2 "IHS cumulative future earnings from any tier 2 tour"

/* 1.IV.13.) Generate earnings conditional on positive earnings */
foreach i in world usa_tot pga_tot web_tot euro_off euro_off_NOdcount tier2 {
gen cond_money_`i'=money_`i' if pos_money_`i'==1
}
label variable cond_money_world "Log earnings from all tours | earnings>0 "
label variable cond_money_usa_tot "Log Unoff + Off earnings from PGA & Web | earnings>0 "
label variable cond_money_pga_tot "Log Unoff + Off earnings from PGA | earnings>0 "
label variable cond_money_web_tot "Log Unoff + Off earnings from PGA | earnings>0 "
label variable cond_money_euro_off "Log Off earnings from Euro | earnings>0 "
label variable cond_money_tier2 "Log Off earnings from tier 2 tours | earnings>0 "

/* 1.IV.14.) Generate retirement based on money */
gen retire_money_world=0 if cfmoney_world>0 & cfmoney_world!=.
replace retire_money_world=1 if cfmoney_world==0
label variable retire_money_world "Retired based on world earnings"

/* 1.IV.15.) Generate events USA */
egen events_usa_tot=rowtotal(events_pga_total events_web_total)
replace events_usa_tot=. if events_pga_total==. & events_web_total==.
egen events_usa_off=rowtotal(events_pga_off events_web_off)
replace events_usa_off=. if events_pga_off==. & events_web_off==.
label variable events_usa_tot "Official + Unofficial USA (PGA + Web) Events"
label variable events_usa_off "Official USA (PGA + Web) Events"

/* 1.IV.16.) Generate positive events */
foreach i in usa_tot pga_tot web_tot euro_off {
gen pos_events_`i'=(events_`i'>0)
replace pos_events_`i'=. if missing(events_`i') 
}
label variable pos_events_usa_tot "Positive events on PGA or Web"
label variable pos_events_pga_tot "Positive events on PGA"
label variable pos_events_web_tot "Positive events on Web"
label variable pos_events_euro_off "Positive events onEuro"

/* 1.IV.17.) Generate cumulative past events */
sort `exp'_id year
foreach i in usa_tot pga_tot web_tot euro_off {
by `exp'_id: gen cpevents_`i'=sum(events_`i')
}
label variable cpevents_usa_tot "Cumulative past events on PGA and Web"
label variable cpevents_pga_tot "Cumulative past events on PGA"
label variable cpevents_web_tot "Cumulative past events on Web"
label variable cpevents_euro_off "Cumulative past events on Euro"

/* 1.IV.18.) Generate cumulative future events */
gsort `exp'_id -year
foreach i in usa_tot pga_tot web_tot euro_off {
by `exp'_id: gen cfevents_`i'=sum(events_`i')
}
label variable cfevents_usa_tot "Cumulative future events on PGA and Web"
label variable cfevents_pga_tot "Cumulative future events on PGA"
label variable cfevents_web_tot "Cumulative future events on Web"
label variable cfevents_euro_off "Cumulative future events on Euro"
sort `exp'_id year

/* 1.IV.19.) Generate retirement based on events */
gen retire_events_usa=0 if cfevents_usa>0 & cfevents_usa!=.
replace retire_events_usa=1 if cfevents_usa==0
label variable retire_events_usa "Retired based on US events"

/* 1.IV.20.) Generate variable denoting on PGA TOUR */
gen ontour_pga_off=0 if events_pga_off<20 & events_pga_off!=.
replace ontour_pga_off=1 if events_pga_off>=20 & events_pga_off!=.
label variable ontour_pga_off "On PGA TOUR = at least 20 official events"

/* 1.IV.21.) Save experiment estimation sample */
sort `exp'_id year
save data\sample_`name'.dta, replace

}

cap log close
