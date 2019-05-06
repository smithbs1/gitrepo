clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\01_03_FormatData_Years_AllTours.txt, text replace


/*****************************************/
/*                                       */
/*   1.III.) CREATE ANNUAL LEVEL DATA    */
/*                                       */
/*   - With PGA TOUR and Web.com Tour    */
/*		earnings and scoring data,       */
/*		earnings data from all other     */
/*		tours, and annual OWGR data      */
/*                                       */
/*****************************************/

set more off
use data/events_PGA_Web.dta, clear

/*********************************************************/
/*   1.III.1.) Create PGA TOUR/Web.com Tour Money Stats  */
/*********************************************************/

/* 1.III.1.a.) Create a variable for wins */
gen win=1 if finish==1
label variable win "Win"

/* 1.III.1.b.) Create a variable for european tour double counted event money */
gen euro_double=money if tour==1 & ///
	((per_tour_num==100 & inrange(year,1983,2014)) | ///
	(per_tour_num==14 & inrange(year,2000,2014)) | ///
	(per_tour_num==26 & inrange(year,1999,2014)) | ///
	(per_tour_num==33 & inrange(year,1999,2014)) | ///
	(per_tour_num==476 & inrange(year,1999,2014)) | ///
	(per_tour_num==470 & inrange(year,1999,2014)) | ///
	(per_tour_num==473 & inrange(year,1999,2014)) | ///
	(per_tour_num==489 & inrange(year,2009,2014)))


/* 1.III.1.c.) Recode all Q School money to 0.
	Not important for the overall story to count
	Q School money and it messes up the computation
	of world money in the year of the Q school event. */
replace money=0 if per_tour_num==88 & tour==1

tempfile eventdata
save "`eventdata'"

/* 1.III.1.d.) Collapse to annual level */
collapse (count) events=tour_num (sum) money euro_double wins=win  ///
		(mean) purse_mean=purse ///
		, by(id player yob year tour officialevent) 
*format
foreach i in events money euro_double wins purse_mean {
rename `i' `i'_
}

/* 1.III.1.e.) Reshape wide to accomodate PGA TOUR and Web.com Tour money stats */
reshape wide events_ money_ euro_double_ wins_ purse_mean_ , i(year id player yob officialevent) j(tour)
*format
foreach i in events money euro_double wins purse_mean {
foreach j in 1 2 {
if `j'==1 {
rename `i'_`j' `i'_pga_
}
if `j'==2 {
rename `i'_`j' `i'_web_
}
}
}

/* 1.III.1.f.) Reshape wide to accomodate official and unofficial money stats */
reshape wide events_pga_ events_web_ money_pga_ money_web_ ///
		wins_pga_ wins_web_ purse_mean_pga_ purse_mean_web_ ///
		euro_double_pga_ euro_double_web_, i(year id player yob) j(officialevent)
*format
foreach i in events money euro_double wins purse_mean {
foreach j in pga web {
foreach k in 0 1 {
if `k'==0 {
rename `i'_`j'_`k' `i'_`j'_unoff
}
if `k'==1 {
rename `i'_`j'_`k' `i'_`j'_off
}
}
}
}
*format
drop euro_double_web*
order id player year yob ///
	events_pga_off events_pga_unoff money_pga_off money_pga_unoff ///
	wins_pga_off wins_pga_unoff events_web_off events_web_unoff ///
	money_web_off money_web_unoff wins_web_off wins_web_unoff ///
	euro_double_pga_off euro_double_pga_unoff 

/* 1.III.1.g.) Create total events, money, and wins */
foreach i in events money wins {
foreach j in pga web {
egen `i'_`j'_total=rowtotal(`i'_`j'_off `i'_`j'_unoff)
order `i'_`j'_total, after(`i'_`j'_unoff)
}
}

/* 1.III.1.h.) Compute mean purse over all tours, offical, and unoffical events */
preserve
use "`eventdata'", clear
collapse (mean) purse_mean_all_total=purse ///
		, by(id player year)		
tempfile purse_mean_all_total
save "`purse_mean_all_total'"
restore

/* 1.III.1.i.) Merge average purse over all events back in */
merge 1:1 id player year using "`purse_mean_all_total'"
drop if _merge!=3
drop _merge

/* 1.III.1.j.) Create money list rank variables */
foreach i in pga web {
gsort year -money_`i'_off
by year: gen rank_`i'_off=_n
replace rank_`i'_off=. if money_`i'_off==0 | money_`i'_off==.
}
sort year id player

*format
label variable events_pga_off "Official PGA TOUR Events"
label variable events_pga_unoff "Unofficial PGA TOUR Events"
label variable events_pga_total "All PGA TOUR Events"
label variable money_pga_off "Official PGA TOUR Money"
label variable money_pga_unoff "Unofficial PGA TOUR Money"
label variable money_pga_total "All PGA TOUR Money"
label variable wins_pga_off "Official PGA TOUR Wins"
label variable wins_pga_unoff "Unofficial PGA TOUR Wins"
label variable wins_pga_total "All PGA TOUR Wins"
label variable events_web_off "Official Web.com Tour Events"
label variable events_web_unoff "Unofficial Web.com Tour Events"
label variable events_web_total "All Web.com Tour Events"
label variable money_web_off "Official Web.com Tour Money"
label variable money_web_unoff "Unofficial Web.com Tour Money"
label variable money_web_total "All Web.com Tour Money"
label variable wins_web_off "Official Web.com Tour Wins"
label variable wins_web_unoff "Unofficial Web.com Tour Wins"
label variable wins_web_total "All Web.com Tour Wins"
label variable rank_pga_off "Offical PGA TOUR Money List Ranking"
label variable rank_web_off "Offical Web.com Tour Money List Ranking"
label variable year "Year"
label variable player "Golfer Name"
label variable yob "Year of Birth"
label variable purse_mean_web_off "Average Purse Web.com Tour Official Events"
label variable purse_mean_web_unoff "Average Purse Web.com Tour Unofficial Events"
label variable purse_mean_pga_off "Average Purse PGA TOUR Unofficial Events"
label variable purse_mean_pga_unoff "Average Purse PGA TOUR Tour Unofficial Events"
label variable purse_mean_all_total "Average Purse on PGA and Web.com Tour for Un + Official Events"
label variable euro_double_pga_off "Potentially doubled counted Off PGA TOUR earnings on Euro Tour"
label variable euro_double_pga_unoff "Potentially doubled counted Unoff PGA TOUR earnings on Euro Tour"

duplicates list player year

/****************************************************/
/*                                                  */
/*  1.III.2.) Add Official PGA TOUR Money List Rank */
/*                                                  */
/*		-The official PGA TOUR Money List rank      */
/*		excludes non-members which are mostly       */
/*		international players.					    */
/*                                                  */
/****************************************************/
tempfile test1
save "`test1'"

/* 1.III.2.a.) Format PGA TOUR Money List data */
import excel using data\1_PGATour\moneylists\PGATour_MoneyList_1980_2014.xlsx, clear sheet("moneylist") first
*format
rename rank rank_pga_off2
rename oevents events_pga_off2
rename v wins_pga_off2
rename money money_pga_off2
recode wins_pga_off2 (.=0)
replace player =regexr(player,"'","")
tempfile pgamoneylist
save "`pgamoneylist'"

	/* 1.III.2.a.1) Find names that don't merge */

	* pga money list names
	drop if year<1983
	keep player
	duplicates drop
	tempfile pgamoneylistnames
	save "`pgamoneylistnames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`pgamoneylistnames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\1_PGATour\moneylists\MergeNameFail_PGAMoneyList.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in PGA Money list for proper merging
	use "`pgamoneylist'", clear

	replace player="andrew oldcorn" if player=="andy oldcorn"
	replace player="bradley king" if player=="brad king"
	replace player="christy oconnor jr" if player=="christy oconnor"
	replace player="danny mijovic" if player=="danny mijovich"
	replace player="jamie spence" if player=="jamie e spence"
	replace player="lu-liang huan" if player=="lu liang-huan"
	replace player="stephen allan" if player=="steve allan"
	replace player="ricky kawagishi" if player=="ryoken kawagishi"
	replace player="des smyth" if player=="desmond smyth"
	replace player="richard s johnson" if player=="richard johnson" & year==2011
	replace player="masahiro kuramoto" if player=="massy kuramoto"
	replace player="ej pfister" if player=="ed pfister"

*save in stata format
save data\1_PGATour\moneylists\PGATour_MoneyList_1980_2014.dta, replace
tempfile pgamoneylist
save "`pgamoneylist'"

/* 1.III.2.b.) Merge official money list standing with earnings data */
use "`test1'", clear
merge 1:1 year player using "`pgamoneylist'"

/* 1.III.2.c.) Check the comparability of money and events played from the different sources */
preserve
keep if _merge==3
keep if inrange(year,1983,2014)
display "Golfers whose official events don't match"
list player year events_pga_off events_pga_off2 money_pga_off money_pga_off2 ///
	if events_pga_off!=events_pga_off2, sep(10000) N(year)
display "Golfers whose official wins don't match"
list player year events_pga_off events_pga_off2 money_pga_off money_pga_off2 wins_pga_off wins_pga_off2 ///
	if wins_pga_off!=wins_pga_off2, sep(10000) N(year)
/* this measure of wins is not consistent with official events, 
	Open Championship included in wins and tournaments held the 
	same week as major are sometimes not counted as wins */
restore
drop _merge

/* 1.III.2.d.) Replace stats prior to 1983 with money list standings */
foreach i in events money wins {
replace `i'_pga_off=`i'_pga_off2 if inrange(year,1980,1982)
}

/* 1.III.2.e.) Drop money and events from money list standings data */
drop events_pga_off2 money_pga_off2 wins_pga_off2
label variable rank_pga_off "Money list ranking including all golfers"
label variable rank_pga_off2 "Official Money List Ranking (only PGA TOUR Members)"
order rank_pga_off2 rank_pga_off rank_web_off, after(yob)

/********************************************************/
/*  1.III.3.) Add Official Web.com Tour Money List Rank */
/********************************************************/
tempfile test1
save "`test1'"

/* 1.III.3.a.) Format Web.com Tour Money List data */
import excel using data\3_WebTour\webmoneylist_1990_2014.xlsx, clear sheet("webmoneylist") first

*format
rename rank_web rank_web_off2
rename v_web wins_web_off2
rename money_web money_web_off2
rename web_exempt web_treat
replace web_treat=. if rank_web_off2>100
recode wins_web_off2 (.=0)
replace player=regexr(player,"'","")

* create Web.com Tour ML relative treatment position
gen web_position=.
replace web_position=rank_web_off2-5.5 ///
	if inrange(year,1990,1991)
replace web_position=rank_web_off2-10.5 ///
	if inrange(year,1992,1996)
replace web_position=rank_web_off2-15.5 ///
	if inrange(year,1997,2002)
replace web_position=rank_web_off2-20.5 ///
	if inrange(year,2003,2004)
replace web_position=rank_web_off2-21.5 ///
	if inrange(year,2005,2005)
replace web_position=rank_web_off2-22.5 ///
	if inrange(year,2006,2006)
replace web_position=rank_web_off2-25.5 ///
	if inrange(year,2007,2014)
replace web_position=. if web_treat==.

tempfile webmoneylist
save "`webmoneylist'"

	/* 1.III.3.a.1) Find names that don't merge */

	* web.com tour names
	keep player
	duplicates drop
	tempfile webmlnames
	save "`webmlnames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`webmlnames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\3_WebTour\MergeNameFail_WebML.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in web.com tour money list data for proper merging
	use "`webmoneylist'", clear

	replace player="alex quiroz" if player=="alejandro quiroz"
	replace player="alistair presnell" if player=="allistair presnell"
	replace player="ashley hall" if player=="ash hall"
	replace player="bill j murchison" if player=="bill murchison"
	replace player="blake d trimble" if player=="blake trimble"
	replace player="bradley king" if player=="brad king"
	replace player="brett waldman" if player=="bret waldman"
	replace player="cameron burke" if player=="cam burke"
	replace player="chris b brown" if player=="chris brown"
	replace player="daehyun kim" if player=="dae-hyun kim"
	replace player="daniel buchner" if player=="dan buchner"
	replace player="daniel vancsik" if player=="daniel alfredo vancsik"
	replace player="dan mccarthy" if player=="daniel mccarthy"
	replace player="dong-hwan lee" if player=="dh lee"
	replace player="todd x fisher" if player=="do not use fisher"
	replace player="donald gammon" if player=="don gammon"
	replace player="edward whitman" if player=="ed whitman"
	replace player="frank esposito" if player=="frank esposito jr"
	replace player="jake younan" if player=="jake younan-wise"
	replace player="james blair" if player=="jim blair"
	replace player="yeon jin jeong" if player=="jin jeong"
	replace player="jonas enander hedin" if player=="jonas hedin"
	replace player="hirokazu kuniyoshi" if player=="kuni kuniyoshi"
	replace player="kyle g morris" if player=="kyle morris"
	replace player="michael mccabe" if player=="mike mccabe"
	replace player="edward michaels" if player=="ned michaels"
	replace player="nickolas jones" if player=="nick jones"
	replace player="nico bollini" if player=="nicolas bollini"
	replace player="philippe gasnier" if player=="phillippe gasnier"
	replace player="rafa echenique" if player=="rafael echenique"
	replace player="richard fulkerson" if player=="rich fulkerson"
	replace player="richard greenwood" if player=="rich greenwood"
	replace player="ricky smallridge" if player=="rick smallridge"
	replace player="robert m sullivan" if player=="rob sullivan"
	replace player="bob gaus" if player=="robert gaus"
	replace player="robert thompson" if player=="robert l thompson"
	replace player="rodolfo gonzalez" if player=="rudolfo gonzalez"
	replace player="steve dartnall" if player=="stephen dartnall"
	replace player="stephen allan" if player=="steve allan"
	replace player="sung lee" if player=="sung man lee"
	replace player="sung kang" if player=="sunghoon kang"
	replace player="timothy oneal" if player=="tim oneal"
	replace player="taylor joseph vogel" if player=="tj vogel"
	replace player="tommy biershenk" if player=="tommy biershenk jr"
	replace player="wen-chong liang" if player=="wc liang"
	replace player="wesley heffernan" if player=="wes heffernan"
	replace player="walter staples" if player=="whit staples"
	replace player="zack miller" if player=="zach miller"
	replace player="richard s johnson" if player=="richard johnson" & inlist(year,2013,2014)
	replace player="michael d smith" if player=="michael smith" & year==2013
	replace player="chris x williams" if player=="chris williams" & inlist(year,1994,1995)
	replace player="richard h lee" if player=="richard lee" & year==2011 & rank_web_off2==37
	replace player="richard h lee" if player=="richard lee" & year==2012 & rank_web_off2==101
	replace player="richard h lee" if player=="richard lee" & year==2014 & rank_web_off2==163
	replace player="richard t lee" if player=="richard lee" & year==2011 & rank_web_off2==124
	replace player="richard t lee" if player=="richard lee" & year==2013 & rank_web_off2==273


*save in stata format
save data\3_WebTour\WebTour_MoneyList_1990_2014.dta, replace
tempfile webmoneylist
save "`webmoneylist'"

* 1.III.3.b.) Merge official money list standing with earnings data */
use "`test1'", clear
merge 1:1 year player using "`webmoneylist'"

/* 1.III.3.c.) Check the comparability of money and events played from the different sources */
preserve
keep if _merge==3
keep if inrange(year,1990,2014)
display "Golfers whose official money list rank doesn't match"
list player year rank_web_off rank_web_off2 money_web_off money_web_off2 wins_web_off wins_web_off2 ///
	if rank_web_off!=rank_web_off2, sep(10000) N(year)
display "Golfers whose wins don't match"
list player year rank_web_off rank_web_off2 money_web_off money_web_off2 wins_web_off wins_web_off2 ///
	if wins_web_off!=wins_web_off2, sep(10000) N(year)
/* this measure of wins is not consistent with official events, 
	looks like a few mistakes on the official money lists especially in 1999 and 2009 */
restore
drop _merge

/* 1.III.3.d.) Drop money and wins from money list standings data */
drop money_web_off2 wins_web_off2
label variable rank_web_off "Web.com Tout Money List ranking including all golfers"
label variable rank_web_off2 "Official Web.com Tour Money List Ranking (members only)"
order rank_web_off2, before(rank_web_off)

/*******************************************************/
/*  1.III.4.) Add Q School treatment variables         */
/*******************************************************/
preserve
use data/events_PGA_Web.dta, clear
keep if i_qs==1
keep year id player qs_finish qs_finish_text i_qs qs_position qs_treat
tempfile qschool
save "`qschool'"
restore
preserve
keep if id==.
tempfile x
save "`x'"
restore
drop if id==.
merge 1:1 year id using "`qschool'", nogen
append using "`x'"
sort id year

/*******************************************************/
/*  1.III.5.) Add exemptions                           */
/*******************************************************/

/* 1.III.5.a.) Format exemptions spreadsheet */
preserve
import excel using data\1_PGATour\Exemptions.xlsx, first clear

/* 1.III.5.a.1) Remove some unecessary duplicates */
drop if year==1991 & player=="ian baker-finch" & xmpt_win==1
drop if year==1994 & player=="denis watson" & xmpt_medical==1
drop if year==1998 & player=="jeff sluman" & xmpt_win==1
tempfile exemp
save "`exemp'"

/* 1.III.5.a.1) Create a dataset with names only */
keep player
duplicates drop
tempfile exemp_names
save "`exemp_names'"
restore

/* 1.III.5.c.) Check for names that do not merge */
preserve
keep player
duplicates drop
merge 1:1 player using "`exemp_names'"
di "Golfers with an exemption whose names don't match in the database"
list player if _merge==2
restore

/* 1.III.5.b.) Merge with annual data */
merge 1:1 year player using "`exemp'"

/* 1.III.5.c.) Drop observations where golfers didn't play any events in a year 
	- I checked to make sure all of these are legitimate and have not failed
	to merge due to a spelling mistake. */
drop if _merge==2
drop _merge xmpt_year

/**********************************************************/
/*  1.III.6.) Add Earnings Data from Other Golf Tours     */
/**********************************************************/

/*******************************************************/
/*  1.III.6.1.) European Tour                          */
/*******************************************************/
tempfile test1
save "`test1'"

/* 1.III.6.1.a.) Import European Tour Earnings */
insheet using data\2_EuropeanTour\EuroTourMoneyList_1980_2014.csv, comma clear
replace player=regexr(player,"'","")
tempfile euromoney
save "`euromoney'"

	/* 1.III.6.1.a.1) Find names that don't merge */

	* euro tour names
	keep player
	duplicates drop
	tempfile euronames
	save "`euronames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`euronames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\2_EuropeanTour\MergeNameFail_Euro.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in euro tour for proper merging
	use "`euromoney'", clear
	
	replace player="alan t pate" if player=="alan pate"
	replace player="arthur russell" if player=="art russell"
	replace player="wu ashun" if player=="ashun wu"
	replace player="donald dubois" if player=="bois donald du"
	replace player="brad sherfy" if player=="bradley sherfy"
	replace player="charles bolling" if player=="charlie bolling"
	replace player="craig a spence" if player=="craig spence"
	replace player="danny goodman" if player=="dan goodman"
	replace player="david edwards" if player=="david m edwards"
	replace player="fran quinn" if player=="francis quinn"
	replace player="jack w nicklaus ii" if player=="jack nicklaus ii"
	replace player="james h mclean" if player=="james mclean"
	replace player="yeon jin jeong" if player=="jin jeong"
	replace player="john nichols" if player=="jonathan nichols"
	replace player="lian-wei zhang" if player=="lianwei zhang"
	replace player="manny zerman" if player=="manuel zerman"
	replace player="mark w johnson" if player=="mark johnson"
	replace player="mike miller" if player=="michael miller"
	replace player="miguel angel carballo" if player=="miguel carballo"
	replace player="nate smith" if player=="nathan smith"
	replace player="pat bates" if player=="patrick bates"
	replace player="rafael cabrera bello" if player=="rafa cabrera-bello"
	replace player="rob moss" if player=="robert moss"
	replace player="rod pampling" if player=="rodney pampling"
	replace player="seuk-hyun baek" if player=="seukhyun baek"
	replace player="stephan gross" if player=="stephan gross jr"
	replace player="steven alker" if player=="steve alker"
	replace player="sung kang" if player=="sunghoon kang"
	replace player="tom pernice jr" if player=="tom pernice"
	replace player="chris g williams" if player=="chris williams"

	save "`euromoney'", replace

/* 1.III.6.1.c.) Add euro to USD exchange rate */
import excel using data\FredExRateData.xlsx, first sheet("ExportData") clear
tempfile xrate
save "`xrate'"
use "`euromoney'", clear
merge m:1 year using "`xrate'", nogen

/* 1.III.6.1.d.) Change euros to USDs */
replace money=round(money*us_eu,0.01)
rename money money_euro_off
rename events events_euro_off
rename rank rank_euro_off
drop us*

*save in stata format
save data\2_EuropeanTour\EuroTourMoneyList_1980_2014.dta, replace
save "`euromoney'", replace

/* 1.III.6.1.e.) Merge Euro Tour earnings to PGA TOUR/Web.com Tour earnings */
use "`test1'", clear
merge 1:1 player year using "`euromoney'", nogen

/* 1.III.6.1.f.) Drop golfers than are only in the Euro Tour data */
preserve
import excel using data\2_EuropeanTour\MergeNameFail_Euro.xlsx, ///
	first sheet("euronames") clear
keep if inlist(inPGAdata,0,9)
replace player=replacement if replacement!=""
keep player inPGAdata
tempfile nonPGAnames
save "`nonPGAnames'"
restore
merge m:1 player using "`nonPGAnames'", nogen
drop if inPGAdata==0
drop inPGAdata

/* 1.III.6.1.g.) Label */
label variable rank_euro_off "European Tour Year-End Money List Ranking"
label variable events_euro_off "European Tour Events"
label variable money_euro_off "European Tour Earnings"

/* 1.III.6.1.h.) Replace euro double count = 0 if golfer
	has no official European tour earnings */
recode euro_double_pga_off (.=0)
recode euro_double_pga_unoff (.=0)
replace euro_double_pga_off=0 if inlist(money_euro_off,.,0)
replace euro_double_pga_unoff=0 if inlist(money_euro_off,.,0)
egen x1=rowtotal(euro_double_pga_off euro_double_pga_unoff)
gen x2=money_euro_off
recode x2 (.=0)
gen money_euro_off_NOdcount=x2-x1
replace money_euro_off_NOdcount=0 if money_euro_off_NOdcount<0
drop x1 x2 euro_double_pga_off euro_double_pga_unoff
label variable money_euro_off_NOdcoun "European Tour Earnings w/o double counting"

/*******************************************************/
/*  1.III.6.2.) Challenge Tour                         */
/*******************************************************/
tempfile test1
save "`test1'"

/* 1.III.6.2.a.) Import Challenge Tour Earnings */
insheet using data\2_EuropeanTour\ChallengeTour_1990_2014.csv, comma clear
replace player=regexr(player,"'","")
tempfile challmoney
save "`challmoney'"

	/* 1.III.6.2.a.1) Find names that don't merge */

	* chall tour names
	keep player
	duplicates drop
	tempfile challnames
	save "`challnames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`challnames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\2_EuropeanTour\MergeNameFail_Chall.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in challenge tour for proper merging
	use "`challmoney'", clear
	
	replace player="byeong-hun an" if player=="byeong hun an"
	replace player="freddie jacobson" if player=="fredrik jacobson"
	replace player="hao tong li" if player=="hao-tong li"
	replace player="john wilson" if player=="jonathan wilson"
	replace player="matt abbott" if player=="matthew abbott"
	replace player="miguel angel carballo" if player=="miguel carballo"
	replace player="nate smith" if player=="nathan smith"
	replace player="rafael cabrera bello" if player=="rafa cabrera-bello"
	replace player="steven russell" if player=="stephen russell"
	replace player="steven alker" if player=="steve alker"
	replace player="chris g williams" if player=="chris williams"
	
	save "`challmoney'", replace

/* 1.III.6.2.b.) Add euro to USD exchange rate */
import excel using data\FredExRateData.xlsx, first sheet("ExportData") clear
drop if year<1990
tempfile xrate
save "`xrate'"
use "`challmoney'", clear
merge m:1 year using "`xrate'", nogen

/* 1.III.6.2.c.) Change euros to USDs */
rename chall_events events_chall_off
rename chall_money money_chall_off
replace money_chall_off=round(money_chall_off*us_eu,0.01)
drop us*

*save in stata format
save data\2_EuropeanTour\ChallengeTour_1990_2014.dta, replace
save "`challmoney'", replace

/* 1.III.6.2.d.) Merge Challenge Tour earnings to PGA TOUR/Web.com Tour/Euro earnings */
use "`test1'", clear
merge 1:1 player year using "`challmoney'", nogen

/* 1.III.6.2.e.) Drop golfers than are only in Challenge Tour data */
preserve
import excel using data\2_EuropeanTour\MergeNameFail_Chall.xlsx, ///
	first sheet("challnames") clear
keep if inlist(inPGAdata,0,9)
replace player=replacement if replacement!=""
keep player inPGAdata
tempfile nonPGAnames
save "`nonPGAnames'"
restore
merge m:1 player using "`nonPGAnames'", nogen
drop if inPGAdata==0
drop inPGAdata

/* 1.III.5.2.f.) Label */
label variable money_chall "Challenge Tour Earnings"

sort player year

/*******************************************************/
/*  1.III.6.3.) PGA Tour of Australasia                */
/*******************************************************/
tempfile test1
save "`test1'"
/* 1.III.6.3.a) Import PGA Tour of Australasia Earnings */
import excel using data\4_PGATourOfAustralasia\Australasian_CareerMoney_1980_2010.xlsx, sheet("data") first clear
reshape long money, i(player) j(year)
rename money money_aus

tempfile aus
save "`aus'"

insheet using data\4_PGATourOfAustralasia\Australasia_2011_2014.csv, comma clear
rename aus_money money_aus

append using "`aus'" 
*format
replace player=regexr(player,"'","")
replace player=regexr(player,"'","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,",","")
replace player=regexr(player,"jnr","jr")
replace player=regexr(player," $","")
replace player=regexr(player,"^ ","")
save "`aus'", replace

	/* 1.III.6.3.a.1) Find names that don't merge */

	* australasian tour names
	keep player
	duplicates drop
	tempfile ausnames
	save "`ausnames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`ausnames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\4_PGATourOfAustralasia\MergeNameFail_Aus.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in australasian tour for proper merging
	use "`aus'", clear
	
	replace player="lucas bates" if player=="bates lucas"
	replace player="ben j campbell" if player=="ben campbell"
	replace player="ben burge" if player=="benjamin burge"
	replace player="luke bleumink" if player=="bleumink luke"
	replace player="brad andrews" if player=="bradley andrews"
	replace player="brad lamb" if player=="bradley lamb"
	replace player="mitchell brown" if player=="brown mitchell"
	replace player="richie caracella" if player=="caracella richie"
	replace player="chris campbell" if player=="christopher campbell"
	replace player="peter cooke" if player=="cooke peter"
	replace player="craig a spence" if player=="craig spence"
	replace player="jim cusdin" if player=="cusdin jim"
	replace player="martin dive" if player=="dive martin"
	replace player="matthew docking" if player=="docking matthew"
	replace player="doug labelle ii" if player=="doug labelle"
	replace player="doug holloway" if player=="douglas holloway"
	replace player="ed stedman" if player=="edward stedman"
	replace player="daniel fox" if player=="fox daniel"
	replace player="bobby gates" if player=="gates bobby"
	replace player="glyn delany" if player=="glynn delany"
	replace player="greg norman" if player=="gregory norman ao"
	replace player="craig hancock" if player=="hancock craig"
	replace player="chris hartas" if player=="hartas chris"
	replace player="craig hasthorpe" if player=="hasthorpe craig"
	replace player="morgan haydn" if player=="haydn morgan"
	replace player="jim herman" if player=="herman jim"
	replace player="scott hill" if player=="hill scott"
	replace player="matt jager" if player=="jager matt"
	replace player="james h mclean" if player=="james mclean"
	replace player="jean louis guepy" if player=="jean-louis guepy"
	replace player="yeon jin jeong" if player=="jin jeong"
	replace player="josh carmichael" if player=="joshua carmichael"
	replace player="andrew kelly" if player=="kelly andrew"
	replace player="lee m williamson" if player=="lee williamson"
	replace player="matthew giles" if player=="matt giles"
	replace player="mathew holten" if player=="matthew holten"
	replace player="matt jones" if player=="matthew jones"
	replace player="brent mccullough" if player=="mccullough brent"
	replace player="mike harwood" if player=="michael harwood"
	replace player="mike hendry" if player=="michael hendry"
	replace player="miguel angel martin" if player=="miguel martin"
	replace player="mitchell brown" if player=="mitchell a brown"
	replace player="nick ohern" if player=="nicholas ohern"
	replace player="nigel p spence" if player=="nigel spence"
	replace player="john onions" if player=="onions john"
	replace player="nathan page" if player=="page nathan"
	replace player="luke paroz" if player=="paroz luke"
	replace player="peter x smith" if player=="peter smith"
	replace player="nicholas piani" if player=="piani nicholas"
	replace player="kieran pratt" if player=="pratt kieran"
	replace player="scott priest" if player=="priest scott"
	replace player="ray beaufils" if player=="raymond beaufils"
	replace player="robert willis" if player=="rob willis"
	replace player="rod pampling" if player=="rodney pampling"
	replace player="jason scrivener" if player=="scrivener jason"
	replace player="jordan sherratt" if player=="sherratt jordan"
	replace player="bob charles" if player=="sir bob charles"
	replace player="brad smith" if player=="smith brad"
	replace player="brendan smith" if player=="smith brendan"
	replace player="kyle stanley" if player=="stanley kyle"
	replace player="steve dartnall" if player=="stephen dartnall"
	replace player="adam stephens" if player=="stephens adam"
	replace player="steven alker" if player=="steve alker"
	replace player="steven conran" if player=="steve conran"
	replace player="timothy wood" if player=="tim wood"
	replace player="peter welden" if player=="welden peter"
	replace player="wen-teh lu" if player=="wen-the lu"
	replace player="won joon lee" if player=="won lee"
	replace player="young nam" if player=="young-woo nam"

	save "`aus'", replace

/* 1.III.6.3.b.) Add AUSD to USD exchange rate */
import excel using data\FredExRateData.xlsx, first sheet("ExportData") clear
tempfile xrate
save "`xrate'", replace
use "`aus'", clear
merge m:1 year using "`xrate'"
drop if inlist(_merge,1,2)
drop _merge

/* 1.III.6.3.c.) Change AUSDs to USDs */
replace money_aus=round(money_aus*us_aus,0.01)
drop us*
drop if money_aus==. | money_aus==0
sort player year

*save in stata format
save data\4_PGATourOfAustralasia\Australasia_1980_2014.dta, replace
save "`aus'", replace

/* 1.III.6.3.d.) Merge Australasian Tour earnings to other tours' earnings */
use "`test1'", clear
merge 1:1 player year using "`aus'", nogen

/* 1.III.6.3.e.) Drop golfers than are only in Australasian Tour data */
preserve
import excel using data\4_PGATourOfAustralasia\MergeNameFail_Aus.xlsx, ///
	first sheet("ausnames") clear
keep if inlist(inPGAdata,0,9)
replace player=replacement if replacement!=""
keep player inPGAdata
duplicates drop
tempfile nonPGAnames
save "`nonPGAnames'", replace
restore
merge m:1 player using "`nonPGAnames'", nogen
drop if inPGAdata==0
drop inPGAdata

/* 1.III.6.3.f.) Label */
label variable money_aus "PGA Tour of Australasia Earnings"

/*******************************************************/
/*  1.III.6.4.) Japan Tour                             */
/*******************************************************/
tempfile test1
save "`test1'"
/* 1.III.6.4.a.) Import Japan Tour Earnings */
insheet using data\5_JapanTour\JapanTourEarnings_1985_2014.csv, comma clear
rename japan_money money_japan
rename japan_events events_japan
*format some mistakes
duplicates drop
gsort year player -money_japan
by year player: gen count=_n
drop if count==2
drop count
*format
replace player=regexr(player,"'","")
replace player=regexr(player,"'","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
tempfile jap
save "`jap'"

	/* 1.III.6.4.a.1) Find names that don't merge */

	* japan tour names
	keep player
	duplicates drop
	tempfile japnames
	save "`japnames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`japnames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\5_JapanTour\MergeNameFail_Jap.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in japan tour for proper merging
	use "`jap'", clear
	
	replace player="arthur russell" if player=="art russel"
	replace player="wu ashun" if player=="ashun wu"
	replace player="ben burge" if player=="benjamin burge"
	replace player="brian claar" if player=="brain claar"
	replace player="craig a spence" if player=="craig spence"
	replace player="daehyun kim" if player=="dae-hyun kim"
	replace player="danny vera" if player=="daniel vera"
	replace player="davis love iii" if player=="davis love"
	replace player="da weibring" if player=="donald a weibring"
	replace player="esteban toledo" if player=="esterban toledo"
	replace player="greg meyer" if player=="gregory meyer"
	replace player="hendrick buhrmann" if player=="hendrik buhrmann"
	replace player="i j jang" if player=="ij jang"
	replace player="ivo giner" if player=="ivoginer"
	replace player="james h mclean" if player=="james mclean"
	replace player="jae-bum park" if player=="jb park"
	replace player="jb holmes" if player=="jbholmes"
	replace player="jim m johnson" if player=="jim johnson"
	replace player="joey snyder iii" if player=="joey snyder"
	replace player="josh carmichael" if player=="joshua carmichael"
	replace player="ken mattiace" if player=="kenneth mattiace"
	replace player="kyi hla han" if player=="kyi-hla han"
	replace player="kj choi" if player=="kyoung-ju choi"
	replace player="mike hulbert" if player=="m hulbert"
	replace player="masashi jumbo ozaki" if player=="masashi ozaki"
	replace player="mathew goggin" if player=="matthew goggin"
	replace player="matthew millar" if player=="matthew john millar"
	replace player="mike clayton" if player=="michael clayton"
	replace player="mike hendry" if player=="michael hendry"
	replace player="willie wood" if player=="millie wood"
	replace player="naomichi ozaki" if player=="naomichi joe ozaki"
	replace player="nicolas colsaerts" if player=="nicolas colserts"
	replace player="ph horgan iii" if player=="pat horgan"
	replace player="per-ulrik johansson" if player=="per ulrik johansson"
	replace player="peter baker" if player=="peter bakey"
	replace player="philip walton" if player=="philip walotn"
	replace player="rodger davis" if player=="roger davis"
	replace player="ron won" if player=="ronald won"
	replace player="ricky kawagishi" if player=="ryoken kawagishi"
	replace player="seong ho lee" if player=="seong-ho lee"
	replace player="scott simpson" if player=="soctt simpson"
	replace player="ssp chawrasia" if player=="ssp chowrasia"
	replace player="steve dartnall" if player=="stephen dartnall"
	replace player="sung lee" if player=="sung man lee"
	replace player="sung joon park" if player=="sung-joon park"
	replace player="sung yoon kim" if player=="sung-yoon kim"
	replace player="tateo ozaki" if player=="tateo jet ozaki"
	replace player="tom pernice jr" if player=="tom pernice"
	replace player="tomohiro watanabe" if player=="tomo watanabe"
	replace player="won joon lee" if player=="won-joon lee"
	replace player="yoshinori mizumaki" if player=="yoshi mizumaki"
	replace player="chris g williams" if player=="chris williams"

	save "`jap'", replace

/* 1.III.6.4.b.) Add Japanese Yen to USD exchange rate */
import excel using data\FredExRateData.xlsx, first sheet("ExportData") clear
tempfile xrate
save "`xrate'", replace
use "`jap'", clear
merge m:1 year using "`xrate'"
drop if inlist(_merge,1,2)
drop _merge

/* 1.III.6.4.c.) Change Japanese Yen to USDs */
replace money_japan=round(money_japan*us_jap,0.01)
drop us*
sort player year

*save in stata format
save data\5_JapanTour\JapanTourEarnings_1985_2014.dta, replace
save "`jap'", replace

/* 1.III.6.4.d.) Merge Japan Tour earnings to other tours' earnings */
use "`test1'", clear
merge 1:1 player year using "`jap'", nogen

/* 1.III.6.4.e.) Drop golfers than are only in Japan Tour data */
preserve
import excel using data\5_JapanTour\MergeNameFail_Jap.xlsx, ///
	first sheet("japannames") clear
keep if inlist(inPGAdata,0,9)
replace player=replacement if replacement!=""
keep player inPGAdata
duplicates drop
tempfile nonPGAnames
save "`nonPGAnames'", replace
restore
merge m:1 player using "`nonPGAnames'", nogen
drop if inlist(inPGAdata,0,9)
drop inPGAdata

/* 1.III.6.4.f.) Label */
label variable money_japan "Japan Tour Earnings"
label variable events_japan "Japan Tour Events"

/*******************************************************/
/*  1.III.6.5.) Asian Tour                             */
/*******************************************************/
tempfile test1
save "`test1'"
/* 1.III.6.5.a.) Import Asian Tour Earnings 
	- Asian Tour Earnings are in USD so no need to convert 
	- From 1995	to 2003 I just have a career earnings measure which
	only includes the top 100 earners and I have no events
	data. From 2004 to 2014 I have all earnings and events */
import excel using data\6_AsianTour\AsianTourCareer1995_2003.xlsx, ///
	sheet("Export") first clear
*format
reshape long asia_money, i(player) j(year)
rename asia_money money_asian
sort player year
drop if money_asian==0

tempfile asian
save "`asian'"

insheet using data\6_AsianTour\Asian_2004_2014.csv, ///
	comma clear
	
rename asian_events events_asian
rename asian_money money_asian
	
append using "`asian'"
*format
replace player=regexr(player,"'","")
replace player=regexr(player,"'","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,",","")
replace player=regexr(player,"jnr","jr")
replace player=regexr(player," $","")
replace player=regexr(player," $","")
replace player=regexr(player," $","")
replace player=regexr(player," $","")
replace player=regexr(player,"^ ","")
replace player=regexr(player,"^ ","")
replace player=regexr(player,"^ ","")
sort player year
save "`asian'", replace

	/* 1.III.6.5.a.1) Find names that don't merge */

	* asian tour names
	keep player
	duplicates drop
	tempfile asiannames
	save "`asiannames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`asiannames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\6_AsianTour\MergeNameFail_Asian.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in asian tour for proper merging
	use "`asian'", clear
	
	replace player="sang-moon bae" if player=="bae sang-moon"
	replace player="bradley iles" if player=="brad iles"
	replace player="bradley smith" if player=="brad smith"
	replace player="seung-su han" if player=="han seung-su"
	replace player="hendrick buhrmann" if player=="hendrik buhrmann"
	replace player="ss hong" if player=="hong soon-sang"
	replace player="jae-bum park" if player=="jb park"
	replace player="jeev milkha singh" if player=="jeev m singh"
	replace player="jim m johnson" if player=="jim johnson"
	replace player="sung kang" if player=="kang sung-hoon"
	replace player="wook-soon kang" if player=="kang wook-soon"
	replace player="bio kim" if player=="kim bi-o"
	replace player="daehyun kim" if player=="kim dae-hyun"
	replace player="hyung-sung kim" if player=="kim hyung-sung"
	replace player="kt kim" if player=="kim hyung-tae"
	replace player="kt kim" if player=="kim kyung-tae"
	replace player="chih-bing lam" if player=="lam chih bing"
	replace player="chih-bing lam" if player=="lam chih-bing"
	replace player="sung lee" if player=="lee sung"
	replace player="sung lee" if player=="lee sung-man"
	replace player="won joon lee" if player=="lee won-joon"
	replace player="wen-chong liang" if player=="liang wen-chong"
	replace player="wen-tan lin" if player=="lin wen-tang"
	replace player="wen-teh lu" if player=="lu wen teh"
	replace player="wen-teh lu" if player=="lu wen-teh"
	replace player="mahal pearce" if player=="mahal darren pearce"
	replace player="mathew holten" if player=="matt holten"
	replace player="matt rosenfeld" if player=="matthew rosenfeld"
	replace player="miguel tabuena" if player=="miguel luis lopez tabuena"
	replace player="seung-yul noh" if player=="noh seung-yul"
	replace player="ssp chawrasia" if player=="ssp chowrasia"
	replace player="timothy oneal" if player=="tim oneal"
	replace player="antonio lascuna" if player=="tony lascuna"
	replace player="tc wang" if player=="wang ter-chang"
	replace player="wei-tze yeh" if player=="yeh wei-tze"
	replace player="chris g williams" if player=="chris williams"
	replace player="zhang lian-wei" if player=="lian-wei zhang"

*save in stata format
save data\6_AsianTour\Asian_1995_2014.dta, replace
save "`asian'", replace

/* 1.III.6.5.c.) Merge Asian Tour earnings to other tours' earnings */
use "`test1'", clear
merge 1:1 player year using "`asian'", nogen

/* 1.III.6.5.d.) Drop golfers than are only in Asian Tour data */
preserve
import excel using data\6_AsianTour\MergeNameFail_Asian.xlsx, ///
	first sheet("asiannames") clear
keep if inlist(inPGAdata,0,9)
replace player=replacement if replacement!=""
keep player inPGAdata
tempfile nonPGAnames
save "`nonPGAnames'", replace
restore
merge m:1 player using "`nonPGAnames'", nogen
drop if inlist(inPGAdata,0,9)
drop inPGAdata

/* 1.III.6.5.e.) Label */
label variable money_asian "Asian Tour Earnings"
label variable events_asian "Asian Tour Events"

/*******************************************************/
/*  1.III.6.6.) Sunshine Tour                          */
/*******************************************************/
tempfile test1
save "`test1'"
/* 1.III.6.6.a.) Import Sunshine Tour Earnings */
import excel using data\7_SunshineTour\SunshineTour_1991_2014.xlsx, ///
	sheet("Sheet1") first clear
*format
keep year player sar events_sun
rename sar money_sun
*format
replace player=regexr(player,"'","")
replace player=regexr(player,"'","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,",","")
replace player=regexr(player,"jnr","jr")
replace player=regexr(player," $","")
replace player=regexr(player," $","")
replace player=regexr(player," $","")
replace player=regexr(player," $","")
replace player=regexr(player,"^ ","")
replace player=regexr(player,"^ ","")
replace player=regexr(player,"^ ","")
sort player year
duplicates drop player year, force
tempfile sunshine
save "`sunshine'", replace

	/* 1.III.6.6.a.1) Find names that don't merge */

	* sunshine tour names
	keep player
	duplicates drop
	tempfile sunnames
	save "`sunnames'"

	* pga events names
	use "`test1'", clear
	keep player
	duplicates drop
	
	*merge together
	merge 1:1 player using "`sunnames'"
	sort _merge player

	*export 
	keep if _merge==2
	export excel using data\7_SunshineTour\MergeNameFail_Sunshine.xlsx, ///
		cell(A1) sheet("usingonly") sheetreplace firstrow(variables)

	*replace names in sunshine tour for proper merging
	use "`sunshine'", clear
	
	replace player="andrew matthews" if player=="andy matthews"
	replace player="chris swanepoel" if player=="chris swanepoel jr"
	replace player="basson de wet" if player=="de wet basson"
	replace player="donald gammon" if player=="don gammon"
	replace player="hendrick buhrmann" if player=="hendrik buhrmann"
	replace player="jeev milkha singh" if player=="jeev m singh"
	replace player="joe daley" if player=="joseph daley"
	replace player="mike foster" if player=="michael foster"
	replace player="michael board" if player=="mike board"
	replace player="michael christie" if player=="mike christie"
	replace player="ph horgan iii" if player=="pat horgan"
	replace player="phillip archer" if player=="philip archer"
	replace player="bob bilbo" if player=="robert bilbo"
	replace player="steve van vuuren" if player=="stephen van vuuren"
	replace player="steve wilson" if player=="stephen wilson"
	replace player="peter eng wilson" if player=="peter wilson"
	replace player="chris g williams" if player=="chris williams"

	save "`sunshine'", replace

/* 1.III.6.6.c.) Add South Afrian Rand to USD exchange rate */
import excel using data\FredExRateData.xlsx, first sheet("ExportData") clear
tempfile xrate
save "`xrate'", replace
use "`sunshine'", clear
merge m:1 year using "`xrate'"
drop if inlist(_merge,1,2)
drop _merge

/* 1.III.6.6.d.) Change South Afrian Rand to USDs */
replace money_sun=round(money_sun*us_sa,0.01)
drop us*
sort player year

*save in stata format
save data\7_SunshineTour\SunshineTour_1991_2014.dta, replace
save "`sunshine'", replace

/* 1.III.6.6.e.) Merge Sunshine Tour earnings to other tours' earnings */
use "`test1'", clear
merge 1:1 player year using "`sunshine'", nogen

/* 1.III.6.6.f.) Drop golfers than are only in Sunshine Tour data */
preserve
import excel using data\7_SunshineTour\MergeNameFail_Sunshine.xlsx, ///
	first sheet("other") clear
tempfile other
save "`other'"
restore
preserve
import excel using data\7_SunshineTour\MergeNameFail_Sunshine.xlsx, ///
	first sheet("sunshinenames") clear
append using "`other'"
keep if inlist(inPGAdata,0,9)
replace player=replacement if replacement!=""
keep player inPGAdata
duplicates drop
tempfile nonPGAnames
save "`nonPGAnames'", replace
restore
merge m:1 player using "`nonPGAnames'", nogen
drop if inlist(inPGAdata,0,9)
drop inPGAdata

/* 1.III.6.6.g.) Label */
label variable money_sun "Sunshine Tour Earnings"
label variable events_sun "Sunshine Tour Events"

/*******************************************************/
/* If possible may want to add OneAsia and Korean Tour */
/*******************************************************/

/*******************************************************/
/*  1.III.7.) Add year end OWGR                        */
/*******************************************************/

/* 1.III.7.a.) Extract year-end OWGR only */
preserve
use data/owgr_month.dta, clear
keep if month==12
drop month
tempfile owgr
save "`owgr'"
restore

/* 1.III.7.b.) Merge year-end OWGR to earnings data */
merge 1:1 player year using "`owgr'"

/* 1.III.7.c.) Replace missing OWGR with maximum OWGR */
sort year
by year: egen x=mean(max_owgr)
replace max_owgr=x
drop x
replace owgr=max_owgr if owgr==.
sort player year

/* 1.III.7.d.) Drop golfers from year-end OWGR data that failed to merge */
drop if _merge==2
drop _merge

/*******************************************************/
/*		                                               */
/*  1.III.8.) Add annual scoring stats                 */
/*		                                               */
/*		- Annual mean score, adjusted score, and       */
/*		field adjusted score.                          */
/*		- Annual mean strength of field.               */
/*		- Annual number of rounds with scoring data    */
/*		                                               */
/*******************************************************/

/* 1.III.8.a.) Extrapolate id & yob to all obs of same golfer */
sort player
foreach i in id yob {
by player: egen x=mean(`i')
replace `i'=x
drop x
}

/* 1.III.8.b.) Assign an id to golfers without one.
	- These are golfers who in the PGA TOUR money list
	data prior to 1983 but not in the PGA TOUR events data
	after 1983 */
preserve
keep if id==.
keep player
duplicates drop
sort player
gen id2=999999+_n
tempfile fakeids
save "`fakeids'"
restore
*merge back to year-level data
merge m:1 player using "`fakeids'", nogen
replace id=id2 if id==.
drop id2

/* 1.III.8.c.) Import rounds data */
preserve
use data/rounds_PGA_Web.dta, clear

/* 1.III.8.d.) Collapse to annual level */
collapse (mean) score rel_score adj_rel_score ///
		lomean_field_owgr ///
		(count) n_score=score n_rel_score=rel_score n_adj_rel_score=adj_rel_score ///
		, by(id player year)
rename player player2
tempfile scorestats
save "`scorestats'"
restore

/* 1.III.8.e.) Merge to year-level data */
merge 1:1 id year using "`scorestats'"
order player2, after(player)
replace player=player2 if player==""
drop player2

/* The 1996 AT&T Pebble Beach Pro Am isn't in the events data. Therefore drop these observations
	that come from the rounds data:	charlie l gibson, david graham, jack w nicklaus ii, johnny miller,
	laird small, dave fowler.  */
drop if _merge==2 & inlist(player,"charlie l gibson","david graham","jack w nicklaus ii" ///
	,"johnny miller","laird small","dave fowler")
	
/* there should be no observations for which _merge==2 */
list id player year if _merge==2
drop _merge

/* 1.III.8.f.) Extrapolate nation of origin to all obs of same golfer */

/* 1.III.8.f.1) Find unique country code for each golfer */
preserve
keep player cntry_code
drop if cntry_code==""
duplicates drop
tempfile cntry
save "`cntry'"
restore

/* 1.III.8.f.2) Merge country code to all observations */
drop cntry_code
merge m:1 player using "`cntry'", nogen
order cntry_code, before(yob)

/*******************************************************/
/*  1.III.10.) Create age                                */
/*******************************************************/
gen age = year - yob
order age, after(yob)
sort player year 

/*******************************************************/
/*  1.III.11.) Create worldwide and US earnings.         */
/*******************************************************/

/* 1.III.11.a.) Recode money and events variables so that 
	"." is "0" for the appropriate years */

foreach i in money_pga_ events_pga_ wins_pga_ {
foreach j in off total {
recode `i'`j' (.=0) if inrange(year,1980,2014)
}
foreach j in unoff {
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

/* 1.III.11.b.) Calculate US, World, and Tier 2 Earnings 
		- For world earnings, use the version of euro earnings
		that doesn't double count money from joint PGA TOUR-Euro Tour
		events. */
egen money_usa_tot=rowtotal(money_pga_tot money_web_tot)
recode money_usa_tot (0=.) if money_pga_tot==. & money_web_tot==.
egen money_usa_off=rowtotal(money_pga_off money_web_off)
recode money_usa_tot (0=.) if money_pga_off==. & money_web_off==.
egen money_world=rowtotal(money_usa_tot money_euro_off_NOdcount money_chall money_aus money_japan money_asian money_sun)
recode money_world (0=.) if money_usa_tot==. & money_euro_off_NOdcount==. & money_chall==. & ///
	money_aus==. & money_japan==. & money_asian==. & money_sun==.
egen money_tier2=rowtotal(money_chall money_aus money_japan money_asian money_sun)
recode money_tier2 (0=.) if money_chall==. & money_aus==. & money_japan==. & money_asian==. & money_sun==.

/* 1.III.11.c.) Create earnings normalization term based 
	on average purse per tournament in 2012 */
	
/* 1.III.11.c.1.) Load events data, keep only official events */
preserve
use data\events_PGA_Web.dta, clear
keep if officialevent==1

/* 1.III.11.c.2.) Compute tournament purses */
collapse (sum) purse=money, by(tour year tour_num eventname)

/* 1.III.11.c.3.) Compute annual average tournament purse */
collapse (mean) m_purse=purse, by(year tour)
reshape wide m_purse, j(tour) i(year)
rename m_purse1 m_pga_purse
rename m_purse2 m_web_purse
label variable m_pga_purse "Annual Mean Official Tournament PGA TOUR Purse"
label variable m_web_purse "Annual Mean Official Tournament Web.com Tour Purse"

/* 1.III.11.c.3.) Create variable for mean purse in 2012 */
gen x1=m_pga_purse if year==2012
egen m_pga_purse_2012=mean(x1)
drop x1

/* 1.III.11.c.4.) Create normalization term */
gen norm_purse=m_pga_purse_2012/m_pga_purse
drop m_pga_purse_2012
label variable norm_purse "Normalization term based on mean official tournament PGA TOUR purse (2012)"
drop m_pga_purse m_web_purse
tempfile temp1
save "`temp1'"
restore

/* 1.III.11.c.5.) Merge back to annual level data */
merge m:1 year using "`temp1'", nogen

/* 1.III.11.d.) Normalize earnings to 2012 level  */
foreach i in world usa_tot usa_off tier2 pga_off pga_unoff pga_tot ///
	web_off web_unoff web_tot euro_off euro_off_NOdcount chall_off ///
	aus japan asian sun {
replace money_`i'=money_`i'*norm_purse if inrange(year,1983,2014)
}

/* 1.III.11.e.) Normalize purses to 2012 level   */
foreach i in pga_unoff web_unoff pga_off web_off all_total {
replace purse_mean_`i'=purse_mean_`i'*norm_purse  if inrange(year,1983,2014)
}

/* 1.III.11.f.) Add battlefield promotions from Web.com Tour */
gen xmpt_battlefield=1 if wins_web_off>=3 & wins_web_off!=. & year>=1997

/* 1.III.11.g.) Generate variables that summarize if a golfer is
	exempt of the Web.com Tour ML or the Q School experiment */
gen web_xmpt=0 if inlist(web_treat,0,1) 
replace web_xmpt=1 if inlist(web_treat,0,1) & (xmpt_major==1 | xmpt_2ndlevel==1 | ///
	xmpt_moneylead==1 | xmpt_win==1 | xmpt_career==1 | ///
	xmpt_medical==1 | xmpt_rydercup==1 | xmpt_wgc==1 | ///
	xmpt_pastchampions==1 | xmpt_battlefield==1)

gen qs_xmpt=0 if inlist(qs_treat,0,1) 
replace qs_xmpt=1 if inlist(qs_treat,0,1) & (xmpt_major==1 | xmpt_2ndlevel==1 | ///
	xmpt_moneylead==1 | xmpt_win==1 | xmpt_career==1 | ///
	xmpt_medical==1 | xmpt_rydercup==1 | xmpt_wgc==1 | ///
	xmpt_pastchampions==1 | xmpt_battlefield==1 | ///
	web_treat==1)

/* 1.III.11.h.) Generate variables denoting other important exemption categories */
foreach l in web qs {
foreach k in medical pastchampions battlefield {
gen `l'_xmpt_`k'=0 if inlist(`l'_treat,0,1)
replace `l'_xmpt_`k'=1 if xmpt_`k'==1
}
}

/* 1.III.11.i.) Format */
drop chall_rank // don't really need year-end ranking on Challenge Tour
order id player year cntry_code yob age ///
	qs_treat qs_position web_treat web_position ///
	owgr score rel_score adj_rel_score ///
	rank_pga_off2 rank_pga_off ///
	rank_web_off2 rank_web_off ///
	i_qs qs_finish qs_finish_text  ///
	money_world money_usa_tot money_usa_off money_tier2 ///
	events_pga_total money_pga_total ///
	events_pga_off money_pga_off events_pga_unoff money_pga_unoff ///
	events_web_total money_web_total ///
	events_web_off money_web_off events_web_unoff money_web_unoff ///
	wins_pga_total wins_pga_off wins_pga_unoff ///
	wins_web_total wins_web_off wins_web_unoff ///
	purse_mean_all_total purse_mean_pga_off purse_mean_web_off ///
	purse_mean_pga_unoff purse_mean_web_unoff ///
	rank_euro_off money_euro_off money_euro_off_NOdcount events_euro_off ///
	money_chall_off events_chall_off ///
	money_aus money_japan events_japan money_asian events_asian ///
	money_sun events_sun ///
	lomean_field_owgr max_owgr norm_purse ///
	n_score n_rel_score n_adj_rel_score ///
	xmpt_major xmpt_2ndlevel xmpt_moneylead ///
	xmpt_win xmpt_career xmpt_medical xmpt_rydercup ///
	xmpt_wgc xmpt_pastchampions xmpt_battlefield ///
	web_xmpt qs_xmpt ///
	web_xmpt_medical web_xmpt_pastchampions web_xmpt_battlefield ///
	qs_xmpt_medical qs_xmpt_pastchampions qs_xmpt_battlefield ///
	
label variable cntry_code "Nation of Origin (from OWGR)"
label variable age "Age"
label variable qs_treat "Q School Experiment Treatment Status"
label variable qs_position "Q School Experiment Running Variable"
label variable web_treat "Web.com ML Experiment Treatment Status"
label variable web_position "Web.com Tour ML Experiment Running Variable"
label variable owgr "Year-end OWGR"
label variable score "Annual Scoring Average"
label variable rel_score "Annual Scoring Average Relative to Field"
label variable adj_rel_score "Annual Field-Adjusted Relative Scoring Average"
label variable qs_finish "Q School Finish Position"
label variable qs_finish_text "Q School Finish Position (text)" 
label variable money_world "Worldwide Earnings (includes tot us earnings)"
label variable money_usa_off "US Official Earnings"
label variable money_usa_tot "US Official+Unofficial Earnings"
label variable money_tier2 "Foreign earnings on second tier tours"
label variable events_chall_off "Challeng Tour Events"
label variable lomean_field_owgr "Annual Mean Field Quality"
label variable max_owgr "Highest ranking in year-end OWGR"
label variable n_score "# of rounds used to calcuate scoring average"
drop n_rel_score
label variable n_adj_rel_score "# of rounds used to calcuate adjusted scoring average"
label variable i_qs "Played in Q School?"
label variable xmpt_major "PGA TOUR status through past major win"
label variable xmpt_2ndlevel "PGA TOUR status through past 2nd level win, e.g. TOUR/Players Champ"
label variable xmpt_moneylead "PGA TOUR status through past PGA TOUR money leader"
label variable xmpt_win "PGA TOUR status through past PGA TOUR win"
label variable xmpt_career "PGA TOUR status through career PGA TOUR earnings"
label variable xmpt_medical "PGA TOUR status through medical exemption"
label variable xmpt_rydercup "PGA TOUR status as past member of Ryder/President's Cup team"
label variable xmpt_wgc "PGA TOUR status through past WGC win"
label variable xmpt_pastchampions "PGA TOUR status through past win (past three years ago)"
label variable xmpt_battlefield "PGA TOUR status through 3 wins on Web.com Tour in previous year (after 1997)"
label variable web_xmpt "Exemption status for Web.com Tour ML Experiment"
label variable qs_xmpt "Exemption status for Q School Experiment"
label variable web_xmpt_medical "Web.com ML eligible + medical exemption"
label variable web_xmpt_pastchampions "Web.com ML eligible + exempt through past win (past three years ago)"
label variable web_xmpt_battlefield "Web.com ML eligible + battlefield promotion"
label variable qs_xmpt_medical "Q School eligible + medical exemption"
label variable qs_xmpt_pastchampions "Q School eligible + exempt through past win (past three years ago)"
label variable qs_xmpt_battlefield "Q School eligible + battlefield promotion"

/* 1.IV.) Save */
sort player year
save data\years_AllTours.dta, replace
cap log close
