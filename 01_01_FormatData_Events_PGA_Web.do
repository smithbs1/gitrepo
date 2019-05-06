clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\01_01_FormatData_Events_PGA_Web.txt, text replace

/*****************************************/
/*                                       */
/*   1.I.) FORMAT EVENT LEVEL DATA       */
/*                                       */
/*   - From PGA TOUR and Web.com Tour    */
/*                                       */
/*****************************************/

/*****************************************/
/*  1.I.1.) Import PGA TOUR Events Data  */
/*****************************************/
insheet using data\1_PGATour\events\pgatourevents_1983_2014.txt, tab clear
*format
split playerageyearsmonthsdays, parse(" ") gen(age)
destring age1, gen(age)
drop age1 age2 age3
order age, after(playerageyearsmonthsdays)
drop playerageyearsmonthsdays
rename tournamentyear year
rename tournamentnumber tour_num
rename permanenttournamentnumber per_tour_num
rename playernumber id
rename playername player
rename officialeventyn officialevent
rename finishpositionnumeric finish
rename finishpositiontext finish_text
forvalues i=1/6 {
rename round`i'score score_round`i'
drop round`i'pos
}
rename totalstrokes score_total
rename totalrounds rounds
drop lowestround strokeaveragerank scoringavgtotaladjustment scoringavgtotaladjustmentrank

/*********************************************/
/* 1.I.2.) Import Web.com Tour Events Data   */
/*********************************************/
preserve
insheet using data\3_WebTour\webevents_1990_2014.txt, tab clear
replace money=regexr(money,",","")
destring money, gen(money1)
drop money
rename money1 money
tempfile webevents
save "`webevents'"
restore
append using "`webevents'"

/****************************/
/* 1.I.3.) Format Variables */
/****************************/

/* 1.I.3.a.) Format player name */
replace player=lower(player)
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"'","")
replace player=regexr(player,", jr,"," jr,")
replace player=regexr(player,",jr,"," jr,")
replace player=regexr(player,", sr,"," sr,")
replace player=regexr(player,", iii,"," iii,")
replace player=regexr(player,", iv,"," iv,")
split player, parse(",") gen(player)
gen playerXX=player2 + " " + player1
order playerXX, after(player)
drop player1 player2 player
rename playerXX player
replace player=regexr(player," ","")

/* 1.I.3.b.) Format tour variable */
gen tour2=1 if tour=="R"
replace tour2=2 if tour=="H"
label define tourv 1 "PGA TOUR" 2 "Web.com Tour"
label values tour2 tourv
order tour2, after(tour)
drop tour
rename tour2 tour

/* 1.I.3.c.) Recode money */
recode money (.=0)

/* I.3.d.) Recode  scores */
forvalues i=1/6 {
recode score_round`i' (0=.)
}

/* 1.I.3.e.) Recode official event variable */
gen x=1 if officialevent=="Y"
replace x=0 if officialevent=="N"
order x, after(officialevent)
drop officialevent
rename x officialevent

/* 1.I.3.f.) recode mistake for Pete Jordan:
	It looks like there is a clear mistake in the database for Pete Jordan.
	Pete P Jordan 11137 qualifies for the PGA TOUR through Q School but 
	subsquently plays in no PGA TOUR events in 1994 (or for that matter,
	never plays in another PGA TOUR event again). But Pete Jordan 6315 plays in lots
	of PGA TOUR events in 1994 despite not qualifying through Q School. And
	also, Pete Jordan didn't earn enough to qualify for the 1994 PGA TOUR
	through the Web.com Tour Money List.
	recode mistake for George Kelley, Jaime Spence, 
	John Dal Corobbo, Hirokazu Kuniyoshi, Wei-Tze Yeh,
	Chang Tse-Peng, Chin-Sheng Hsieh, Ralph Howe III, change
	Mike Higgins to Don M Higgins in one event,
	Ricky Kawagishi for one event */
replace age=29 if id==11137 & tour_num==888
replace age=26 if id==11137 & tour_num==380
replace age=30 if id==11137 & tour_num==340
replace player="pete jordan" if player=="pete p jordan" & id==11137
replace id=6315 if id==11137
replace id=6319 if player=="george kelley" & id==7823
replace player="jamie e spence" if id==19982
replace id=20881 if id==19982
replace id=12668 if inlist(id,12403,36756)
replace player="john dal corobbo" if id==12668
replace player="hirokazu kuniyoshi" if player=="kuni kuniyoshi"
replace id=24359 if id==21974
replace id=24368 if id==24509
replace player="wei-tze yeh" if id==24368
replace id=24532 if id==22258
replace player="chang tse-peng" if id==24532
replace id=11226 if inlist(id,6232,6408)
replace player="chin-sheng hsieh" if id==11226
replace id=8813 if id==6298
replace player="ralph howe iii" if id==8813
replace player="don m higgins" if player=="mike higgins" & tour_num==420 & year==1990
replace player="sung yoon kim" if id==24363
replace player="gregor main" if id==33047
replace player="george kelley" if id==6319
replace id=6483 if id==20381
replace player="ricky kawagishi" if id==6483
replace id=10906 if player=="jimmy jones"
replace id=21047 if player=="mike deuel"
replace id=21221 if player=="joe jackson"
replace player="zhang lian-wei" if player=="lian-wei zhang"
replace id=20487 if player=="zhang lian-wei"
replace id=11086 if id==1659
replace player="masahiro kuramoto" if player=="massy kuramoto"
replace id=1239 if id==12123
replace player="michael cunning" if player=="mike cunning"
replace id=6383 if id==1950
replace player="ej pfister" if player=="ed pfister"
replace id=8559 if id==20507
replace player="tom r shaw" if player=="tom j shaw  jr"

/* 1.I.3.g.) change some names in PGA TOUR data for proper merging */

/* 1.I.3.g.1.) euro tour name corrections */
replace player="andy stubbs" if player=="andrew stubbs"
replace player="daniel denison" if player=="danny denison"
replace player="daniel vancsik" if player=="daniel alfredo vancsik"
replace player="danny mijovic" if player=="danny mijovich"
replace player="donald gammon" if player=="don gammon"
replace player="gary cullen" if player=="garry cullen"
replace player="heinz peter thul" if player=="heinz thul"
replace player="jamie spence" if player=="jamie e spence"
replace player="jean-baptiste gonnet" if player=="jean baptiste gonnet"
replace player="jeff pinsent" if player=="jeffrey pinsent"
replace player="nicholas brown" if player=="nick brown"
replace player="orrin vincent iii" if player=="orrin vincent"
replace player="pedro linhart" if player=="peter linhart"
replace player="peter a smith" if player=="peter smith"
replace player="phil harrison" if player=="philip harrison"
replace player="philip talbot" if player=="phillip talbot"
replace player="phillip archer" if player=="philip archer"
replace player="rafa echenique" if player=="rafael echenique"
replace player="ronald stelten" if player=="ronald j stelten"
replace player="stephen allan" if player=="steve allan"
replace player="van phillips" if player=="vanslow phillips"
replace player="wen-yi huang" if player=="wenyi huang"
replace player="peter a smith" if player=="peter smith"
replace player="miguel angel jimenez" if player=="miguel a jimenez"
replace player="alex noren" if player=="alexander noren"
replace player="andrew oldcorn" if player=="andy oldcorn"
replace player="ben fox" if player=="benjamin fox"
replace player="basson de wet" if player=="de wet basson"
replace player="christy oconnor jr" if player=="christy oconnor"
replace player="damien mcgrane" if player=="damian mcgrane"
replace player="shaun p webster" if player=="shaun webster"
replace player="mark d smith" if player=="mark smith"
replace player="mark foster" if player=="mark b foster"

/* 1.I.3.g.2.) challenge tour name corrections */
replace player="bradley king" if player=="brad king"
replace player="dan olsson" if player=="daniel olsson"
replace player="dave coupland" if player=="david coupland"
replace player="matt mcguire" if player=="matthew mcguire"
replace player="michael green" if player=="mike green"
replace player="robert d steele" if player=="robert steele"
replace player="steven mattson" if player=="steve mattson"

/* 1.I.3.g.3.) other name corrections */
replace player="dohoon kim 752" if player=="do-hoon x kim"
replace player="david tentis" if player=="dave tentis"
replace player="edward michaels" if player=="ned michaels"

/* 1.I.3.h.) Create a variable denoting duplicate player names */
preserve
keep id player
duplicates drop
duplicates tag player, gen(dup_name)
duplicates list player
duplicates tag id, gen(dup_id)
drop dup_id
tempfile dupnames
save "`dupnames'"
restore
merge m:1 id player using "`dupnames'", nogen

/* 1.I.3.g.) Drop a duplicated tournament */
drop if tour_num==475 & year==1989

/*******************************************/
/* 1.I.4.) Add missing Q School data and   */
/*		format Q School data               */
/*******************************************/

/* 1.I.4.a.) Import/format missing Q School data.
	Merge by player, year, and tournament */
preserve
import excel using data\1_PGATour\MissingQSchoolYears.xlsx, ///
	firstrow clear
rename totalscore score_total
drop card
gen per_tour_num=88
gen tour_num=888
gen eventname="PGA TOUR Qualifying Tournament"
gen officialevent=0
gen tour=1
sort year score_total
by year: gen finish=_n
by year score_total: egen x=min(finish)
replace finish=x
drop x
duplicates drop
tempfile qschool
save "`qschool'"
restore

merge 1:1 tour year player per_tour_num tour_num using "`qschool'", update replace

/* 1.I.4.b.) Impute id and yob for missing Q School golfers */
sort player year per_tour_num
gen x=(inlist(_merge,2,5))
by player: egen x2=max(x)
gen yob=year-age
order yob, after(age)
by player: egen yob2=min(yob)
order yob2, after(yob)
replace age=year-yob2 if age==. & x2==1
by player: egen id2=max(id)
replace id=id2 if x2==1
drop yob yob2 x x2 _merge

/* 1.I.4.b.) Create an indicator denoting that golfer is in Q School experiment.
		Only use years for which I have found data on qualifiers and non-qualifiers
		and years in which there was also a Web.com Tour. */
sort tour year tour_num finish id
gen i_qs=1 if per_tour_num==88 & tour==1 & inrange(year,1990,2012)
*Q School does not have information on tournament total scores filled in
egen x1=rowtotal(score_round1 score_round2 score_round3 score_round4 score_round5 score_round6) if i_qs==1
egen x2=rownonmiss(score_round1 score_round2 score_round3 score_round4 score_round5 score_round6) if i_qs==1
replace rounds=x2 if i_qs==1 & inlist(score_total,.,0)
replace score_total=x1 if i_qs==1 & inlist(score_total,.,0)
drop x1 x2
gen qs_finish=finish if i_qs==1
gen qs_finish_text=finish_text if i_qs==1

/* 1.I.4.c.) Create a variable measuring strokes from QS cutoff    */
gen qs_position=.
replace qs_position=score_total-428.5 if year==1990 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-429.5 if year==1991 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-432.5 if year==1992 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-426.5 if year==1993 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-427.5 if year==1994 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-419.5 if year==1995 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-360.5 if year==1996 & qs_finish!=999 & i_qs==1 & rounds==5
replace qs_finish=999 if year==1996 & i_qs==1 & rounds<=4
replace qs_finish_text="CUT" if year==1996 & i_qs==1 & rounds==4
replace qs_position=score_total-423.5 if year==1997 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-422.5 if year==1998 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-412.5 if year==1999 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-417.5 if year==2000 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-415.5 if year==2001 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-424.5 if year==2002 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-425.5 if year==2003 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-425.5 if year==2004 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-421.5 if year==2005 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-424.5 if year==2006 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-418.5 if year==2007 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-413.5 if year==2008 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-423.5 if year==2009 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-420.5 if year==2010 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-424.5 if year==2011 & qs_finish!=999 & i_qs==1
replace qs_position=score_total-415.5 if year==2012 & qs_finish!=999 & i_qs==1

/* 1.I.4.d.) Create Q School treatment variable */
gen qs_treat=0 if qs_finish!=999 & i_qs==1
replace qs_treat=1 if qs_position<0 & qs_finish!=999 & i_qs==1

/* 1.I.4.e.) list individuals for which I have a duplicate name and in QS experiment */
list id player year if dup_name==1 & i_qs==1 & qs_finish!=999

/* 1.I.4.f.) Create an indicator denoting that golfer is in Web.com Tour ML experiment
		- Position 100 or less on the year-end Money list from 1990 to 2012.
		After postion 100 they are granted no playing privledges on the Web.com Tour for the next season */
preserve
keep if tour==2 & officialevent==1
collapse (sum) money, by(year id player)
gsort year -money
by year: gen webml_finish=_n
keep if year<=2012
gen i_webml=1 if webml_finish<=100
keep id year i_webml webml_finish
keep if i_webml==1
duplicates drop
tempfile webmlers
save "`webmlers'"
restore
merge m:1 id year using "`webmlers'", nogen
recode i_webml (.=0) if inrange(year,1990,2012)

/* 1.I.4.g.) List individuals for which I have a duplicate name and in Web.com Tour ML experiment */
list id player year if dup_name==1 & i_webml==1

/* 1.I.4.h.) Drop duplicate names

	I checked the names out and they seem like legitimately different
	people, can just drop the less significant ones
	
	chris thompson 29968 played in one Web.com Tour event in 1992 and missed the cut
	john hughes 22496 played in one Web.com Tour event and one PGA TOUR event in 1997 and missed the cut in both
	john roberston 5528 played in three Web.com Tour events from 2004 to 2007 and missed the cut in all of them
	*/
drop if player=="chris thompson" & id==29968
drop if player=="john hughes" & id==22496
drop if player=="john robertson" & id==5528

/****************************/
/* 1.I.5.) Add Missing Ages */
/****************************/

/* 1.I.5.a.) List golfers in each experiment without a recorded age */
preserve
gen yob=year-age
keep id player year yob i_qs i_webml qs_finish webml_finish
duplicates drop
sort id player year
by id: egen x=min(yob)
replace yob=x
drop x
duplicates drop
sort qs_finish id player year
display "Q School golfers without age in raw data"
list id player year qs_finish if yob==. & i_qs==1, separator(1000) N(id)
sort webml_finish id player year
display "Web.com Tour ML golfers without age in raw data"
list id player year webml_finish if yob==. & i_webml==1, separator(1000) N(id)
tempfile miss_age
save "`miss_age'"
restore

/* 1.I.5.b.) Add manually inputed year of birth */
preserve
import excel using data\1_PGATour\PGATour_MissingAges.xlsx, firstrow case(lower) sheet("Sheet1") clear
rename player player3
rename yob yob3
tempfile missingages
save "`missingages'"
restore

/* 1.I.5.c.) List golfers in each experiment without a recorded age after mannually inputing ages */
preserve
use "`miss_age'", clear
merge m:1 id using "`missingages'"
replace yob=yob3 if _merge==3
sort qs_finish id player year
display "Q School golfers without age after mannualy inputing age"
list id player year qs_finish  if yob==. & i_qs==1, separator(1000) N(id)
sort webml_finish id player year
display "Web.com Tour ML golfers without age after mannualy inputing age"
list id player year webml_finish  if yob==. & i_webml==1, separator(1000) N(id)
restore

/* 1.I.5.d.) Add missing YOBs to full dataset */
merge m:1 id using "`missingages'"
replace age=year-yob3 if _merge==3
drop _merge
drop yob3 player3

/* 1.I.5.e.) Create Year-of-Birth (YOB) variable */
sort id year tour_num
by id: gen yob=year-age
by id: egen x=min(yob)
replace yob=x
order yob, after(age)
drop x


/****************************/
/*  1.I.6.) Format Data     */
/****************************/

/* 1.I.6.a.) Change W/D to DNS for some events 
		- PGA TOUR coded DNSs as W/Ds prior to 1989 */
replace finish_text="DNS" if (year==1983 & id==2201 & per_tour_num==32) | ///
							  (year==1983 & id==2190 & per_tour_num==28) | ///
							  (year==1983 & id==1571 & per_tour_num==6) | ///
							  (year==1983 & id==1522 & per_tour_num==20) | ///
							  (year==1983 & id==2267 & per_tour_num==12) | ///
							  (year==1984 & id==1006 & per_tour_num==41) | ///
							  (year==1984 & id==1935 & per_tour_num==26) | ///
							  (year==1985 & id==1303 & per_tour_num==13) | ///
							  (year==1986 & id==1477 & per_tour_num==57) | ///
							  (year==1986 & id==1952 & per_tour_num==57) | ///
							  (year==1986 & id==1782 & per_tour_num==57) | ///
							  (year==1986 & id==1501 & per_tour_num==57) | ///
							  (year==1986 & id==2111 & per_tour_num==57) | ///
							  (year==1986 & id==2180 & per_tour_num==57) | ///
							  (year==1986 & id==1418 & per_tour_num==27) | ///
							  (year==1986 & id==1155 & per_tour_num==57) | ///
							  (year==1986 & id==1925 & per_tour_num==26) | ///
							  (year==1986 & id==1713 & per_tour_num==57) | ///
							  (year==1986 & id==1648 & per_tour_num==57) | ///
							  (year==1987 & id==1068 & per_tour_num==34) | ///
							  (year==1987 & id==1928 & per_tour_num==26) | ///
							  (year==1988 & id==1418 & per_tour_num==7)  | ///
							  (year==1996 & id==2010 & per_tour_num==60)	
							  
/* 1.I.6.b.) drop a DNS for Scott Verplank that isn't marked */					  
drop if id==2239 & year==1998 & per_tour_num==54	
						  
/* 1.I.6.c.) Drop tournament in which golfer does not start */
drop if finish_text=="DNS"

/* 1.I.6.d.) Recode The President's Cup as an unofficial event for all years
		- The official stats acutally count The President's Cup as an 
		official event in 1994, but I don't think that is appropriate so
		I will mark it as an unofficial event. */
replace officialevent=0 if per_tour_num==500

/* 1.I.6.e.) Change finish_text for Ryder Cup and President's Cup */
replace finish_text="WIN" if finish==1 & inlist(per_tour_num,468,500)
replace finish_text="LOSS" if finish==999 & inlist(per_tour_num,468,500)

/* 1.I.6.f.) Drop entries with no registered play and no stated reason for not playing */
drop if finish==999 & finish_text=="" & score_round1==.

/* 1.I.6.g.) Drop if tournament was cancelled */
drop if finish_text=="CNL"

/* 1.I.6.h.) Add year end bonus to TOUR Championship money from 1987 to 1990
	- per_tour_num 60 is the TOUR Championship
	- per_tour_num 495 is an entry for the Nabisco Individual Competition
		which is a year end bonus for a golfer's position on the money list */
sort id year tour tour_num
gen x=1 if inlist(per_tour_num,60,495)
bysort id year x: egen y=total(money)
replace money=y if inrange(year,1987,1990) & per_tour_num==60
drop if per_tour_num==495
drop x y

/********************************************/
/*  1.I.7.) Calculate tournament purse      */
/********************************************/
bysort year tour tour_num: egen purse=total(money)
recode purse (0=.)

/********************************************/
/*  1.I.8.) Save                            */
/********************************************/
sort id year tour tour_num
save data/events_PGA_Web.dta, replace
cap log close
