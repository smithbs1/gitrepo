clear all
set more off
cd C:\Users\smith\Dropbox\Research\GolfPaper

capture log close
log using logs\01_02_FormatData_Rounds_PGA_Web.txt, text replace

/*****************************************/
/*                                       */
/*   1.II.) FORMAT ROUND LEVEL DATA      */
/*                                       */
/*   - From PGA TOUR and Web.com Tour    */
/*                                       */
/*****************************************/

/*****************************************/
/*  1.II.1.) Import Rounds Data          */
/*****************************************/

/* 1.II.1.a.) Import PGA TOUR Rounds Data */
insheet using data\1_PGATour\rounds\pgatourrounds_1983_2014.txt, delimiter(";") clear
tempfile pgascore
save "`pgascore'"

/* 1.II.1.b.) Import Web.com Tour Rounds Data */
insheet using data\3_WebTour\webtourrounds_1990_2014.txt, delimiter(";") clear
tempfile webscore
save "`webscore'"

/* 1.II.1.c.) Combine PGA and Web Tour Rounds Data */
use "`pgascore'", clear
append using "`webscore'", force

/****************************/
/* 1.II.2.) Format Dataset  */
/****************************/

/* 1.II.2.a.) Format variables */
keep tour-endofeventpostext
drop teamid
rename tournamentyear year
rename tournament tour_num
rename permanenttournament per_tour_num
rename playernumber id
rename playername player
rename endofroundfinishposnumeric finish_round
rename endofroundfinishpostext finish_round_text
rename endofeventposnumeric finish_event
rename endofeventpostext finish_event_text
rename roundscore score
rename roundnumber round_num
gen tour2=1 if tour=="R"
replace tour2=2 if tour=="H"
label define tourv 1 "PGA TOUR" 2 "Web.com Tour"
label values tour2 tourv
order tour2, after(tour)
drop tour
rename tour2 tour

/* 1.II.2.b.) Add variable for official event 
	- Scoring data is mostly kept only in official events */
preserve
keep year tour per_tour_num eventname
duplicates drop year tour per_tour_num, force
sort year tour per_tour_num
tempfile r
save "`r'"

use data/events_PGA_Web.dta, clear
keep year tour per_tour_num eventname officialevent
duplicates drop year tour per_tour_num, force
sort year tour per_tour_num
tempfile e
save "`e'"

use "`r'", clear
merge 1:1 year tour per_tour_num using "`e'"
sort year tour per_tour_num
gen m=_merge
display "list of tournament that are not in rounds data"
display "m=2, in events data only"
display "m=1, in rounds data only"
list tour year eventname officialevent m ///
	if inlist(_merge,1,2), sep(100000) N(year) 
use "`e'", clear
drop eventname
sort year per_tour_num tour
save "`e'", replace
restore
merge m:1 year tour per_tour_num using "`e'"
drop if inlist(_merge,2)
drop _merge

/* 1.II.2.c.) Recode The President's Cup as an unofficial event for all years
		- The official stats acutally count The President's Cup as an 
		official event in 1994, but I don't think that is appropriate so
		I will mark it as an unofficial event. */
replace officialevent=0 if per_tour_num==500

/* 1.II.2.d.) Drop unofficial events */
preserve
keep if officialevent==0
keep year tour eventname
duplicates drop
display "unofficial events in rounds data"
list year tour eventname ///
 , sep(100000) N(year) 
restore
drop if officialevent==0

/* 1.II.2.e.) Format player name */
replace player=lower(player)
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"\.","")
replace player=regexr(player,"'","")
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

/* 1.II.2.f.) recode mistake for Pete Jordan:
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
	Ricky Kawagishi for one event, Jimmy Jones
	*/
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

/* 1.II.2.g.) corrections specific to rounds data */
drop if id==11429 & year==1990 & tour==2 & tour_num==80 // random entry from charles henley, for 3rd round only
replace id=2294 if id==11574 // willie wood
replace player="willie wood" if player=="willard wood"
replace id=32150 if id==22592
replace player="michael thompson" if id==32150

/* 1.II.2.h.) Change some names in PGA TOUR data for proper merging */

/* 1.II.2.h.1.) euro tour name corrections */
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

/* 1.II.2.h.2.) challenge tour name corrections */
replace player="bradley king" if player=="brad king"
replace player="dan olsson" if player=="daniel olsson"
replace player="dave coupland" if player=="david coupland"
replace player="matt mcguire" if player=="matthew mcguire"
replace player="michael green" if player=="mike green"
replace player="robert d steele" if player=="robert steele"
replace player="steven mattson" if player=="steve mattson"

/* 1.II.2.h.3.) other name corrections */
replace player="dohoon kim 752" if player=="do-hoon x kim"
replace player="david tentis" if player=="dave tentis"
replace player="edward michaels" if player=="ned michaels"

/* 1.II.2.i.) Drop duplicate names

	I checked the names out and they seem like legitimately different
	people, can just drop the less significant ones
	
	chris thompson 29968 played in one Web.com Tour event in 1992 and missed the cut
	john hughes 22496 played in one Web.com Tour event and one PGA TOUR event in 1997 and missed the cut in both
	john roberston 5528 played in three Web.com Tour events from 2004 to 2007 and missed the cut in all of them
	*/
drop if player=="chris thompson" & id==29968
drop if player=="john hughes" & id==22496
drop if player=="john robertson" & id==5528

/*****************************************/
/* 1.II.3.) Add dates of each tournament */
/*****************************************/

/* 1.II.3.a.) PGA Tour tournament dates */
preserve
insheet using data\1_PGATour\PGATour_TournamentDates.csv, comma clear
rename tournament eventname
drop if year==1995 & strpos(eventname,"WCG")
drop if strpos(eventname,"Williams World Challenge")
replace eventname="Houston Open" if eventname==" Houston Open"
gen tour=1
sort tour year eventname
keep year month day eventname tour
tempfile pgadates
save "`pgadates'"
restore

/* 1.II.3.b.) Web.com Tour tournament dates */
preserve
insheet using data\3_WebTour\WebTour_TournamentDates.csv, comma clear
rename tournament eventname
gen tour=2
sort tour year eventname
keep year month day eventname tour
rename month month2
rename day day2
tempfile webdates
save "`webdates'"
restore

/* 1.II.3.c.) PGA Tour merge check */
preserve
keep year tour tour_num per_tour_num eventname
duplicates drop
sort tour year eventname
replace eventname="Houston Open" if eventname=="I Houston Open"
keep if tour==1
merge 1:1 tour year eventname using "`pgadates'"
order tour year month day eventname _merge
display "PGA TOUR Events for which I don't have scoring data"
list year eventname _merge if inlist(_merge,1,2) ///
	, sep(100000) N(year) 
restore

/* 1.II.3.d.) Web.com Tour merge check */
preserve
keep year tour tour_num per_tour_num eventname
duplicates drop
sort tour year eventname
keep if tour==2
merge 1:1 tour year eventname using "`webdates'"
order tour year month day eventname _merge
display "Web.com Tournament for which I don't have scoring data"
list year eventname _merge if inlist(_merge,1,2) ///
	, sep(100000) N(year) 
restore

/* 1.II.3.e.) Merge in dates for PGA Tour */
replace eventname="Houston Open" if eventname=="I Houston Open"
merge m:1 tour year eventname using "`pgadates'"
drop if _merge==2
drop _merge 

/* 1.II.3.f.) Merge in dates from Web.com Tour */
merge m:1 tour year eventname using "`webdates'"
replace month=month2 if _merge==3
replace day=day2 if _merge==3
drop month2 day2
drop if _merge==2
drop _merge

/*****************************************/
/* 1.II.4.) Drop Accenture Match Play    */
/*****************************************/
drop if per_tour_num==470
drop teamnumber

/*****************************************/
/* 1.II.5.) Load OWGR Data               */
/*****************************************/

/* 1.II.5.a.) Import OWGR data from 1988 to 1999 */
preserve
insheet using data\OfficialWorldGolfRankings\OWGR_1988_1999.txt ///
	, tab clear
tempfile owgr1
save "`owgr1'"
restore

/* 1.II.5.b.) Import OWGR data from 2000 to 2014 */
preserve
insheet using data\OfficialWorldGolfRankings\OWGR_2000_2015.txt ///
	, delimiter("|") clear
rename week_end_date date
split date, parse("/")
forvalues i=1/3 {
destring date`i', replace
}
rename date1 day
rename date2 month
rename date3 year
drop if year==2015
drop date
tempfile owgr2
save "`owgr2'"
restore

/* 1.II.5.c.) Combine both periods of OWGR data */
preserve 
use "`owgr1'", clear
append using "`owgr2'"

/* 1.II.5.d.) Format rank variable */
replace rank_txt=regexr(rank_txt,"=","")
destring rank_txt, replace
rename rank_txt owgr
order year month day first_name last_name owgr, first

/* 1.II.5.e.) Format names */
foreach i in first last {
replace `i'_name=lower(`i'_name)
replace `i'_name=regexr(`i'_name,"\.","")
replace `i'_name=regexr(`i'_name,"\.","")
replace `i'_name=regexr(`i'_name,"\.","")
replace `i'_name=regexr(`i'_name,"'","")
replace `i'_name=regexr(`i'_name,"'","")
}
replace last_name=regexr(last_name,"-jr"," jr")
replace last_name=regexr(last_name,"-jnr"," jr")
replace last_name=regexr(last_name,"-ii"," ii")
replace last_name=regexr(last_name,"-iii"," iii")
replace last_name=regexr(last_name,"-iv"," iv")
replace last_name=regexr(last_name,"\(usa\)","")
replace last_name=regexr(last_name,"\(am\)","")
replace last_name=regexr(last_name,"\(am","")
replace last_name=regexr(last_name,"\(sco\)","")
replace last_name=regexr(last_name,"\(eng\)","")
gen player=first_name + " " + last_name
order player, before(first_name)
drop first_name last_name

/* 1.II.5.f.) Keep only essential variables */
keep year month day player owgr cntry_code event_cnt

/* 1.II.5.g.) Compute maximum owgr in each month */
sort year month day owgr
by year month: egen max_owgr=max(owgr)

/* 1.II.5.h.) Change some names for proper merging */
replace player="chris g williams" if player=="chris williams" & cntry_code=="RSA"
replace player="peter eng wilson" if player=="peter wilson" & cntry_code=="ENG"
replace player="jose maria olazabal" if player=="jose m olazabal"
replace player="masashi jumbo ozaki" if player=="masashi ozaki"
replace player="miguel angel jimenez" if player=="miguel a jimenez"
replace player="mike harwood" if player=="michael harwood"
replace player="toshi izawa" if player=="toshimitsu izawa"
replace player="joe ozaki" if player=="naomichi joe ozaki"
replace player="da weibring" if player=="d a weibring"
replace player="alex noren" if player=="alexander noren"
replace player="wen-tang lin" if player=="lin wen-tang"
replace player="wc liang" if player=="liang wen-chong"
replace player="seung-yul noh" if player=="seungyul noh"
replace player="jet ozaki" if player=="tateo jet ozaki"
replace player="hyung-sung kim" if player=="hyungsung kim"
replace player="miguel angel martin" if player=="miguel a martin"
replace player="tc chen" if player=="chen tze-chung"
replace player="jose maria canizares" if player=="jose m canizares"
replace player="dj morris" if player=="d j morris"
replace player="lian-wei zhang" if player=="zhang lian-wei"
replace player="stephen allan" if player=="steve allan"
replace player="jean-francois remesy" if player=="jean-f remesy"
replace player="sung joon park" if player=="sungjoon park"
replace player="craig a spence" if player=="craig spence"
replace player="yoshinori mizumaki" if player=="yoshi mizumaki"
replace player="basson de wet" if player=="de wet basson"
replace player="katsunori takahashi" if player=="katsunari takahashi"
replace player="tm chen" if player=="chen tze-ming"
replace player="jc snead" if player=="j c snead"
replace player="chin-sheng hsieh" if player=="hsieh chin-sheng"
replace player="stephen mcallister" if player=="stn mcallister"
replace player="wen-teh lu" if player=="lu wen-teh"
replace player="dong-hwan lee" if player=="donghwan lee"
replace player="aki ohmachi" if player=="akiyoshi ohmachi"
replace player="jong-duck kim" if player=="jongduk kim"
replace player="mike hendry" if player=="michael hendry"
replace player="rafa echenique" if player=="rafael echenique"
replace player="toshi odate" if player=="toshiaki odate"
replace player="kyoung-hoon lee" if player=="kyounghoon lee"
replace player="jung-gon hwang" if player=="junggon hwang"
replace player="tc wang" if player=="wang ter-chang"
replace player="mamoru osanai" if player=="mamo osanai"
replace player="wei-tze yeh" if player=="yeh wei-tze"
replace player="byeong-hun an" if player=="byeong hun an"
replace player="seuk-hyun baek" if player=="seukhyun baek"
replace player="chih-bing lam" if player=="lam chih bing"
replace player="bradley king" if player=="brad king"
replace player="hendrick buhrmann" if player=="hendrik buhrmann"
replace player="i j jang" if player=="ikjae jang"
replace player="lance ten broeck" if player=="lance ten-broeck"
replace player="dong-kyu jang" if player=="dongkyu jang"
replace player="kohki idoki" if player=="kouki idoki"
replace player="jean-francois lucquin" if player=="jean-f lucquin"
replace player="jae-bum park" if player=="jaebum park"
replace player="sung kang" if player=="sunghoon kang"
replace player="chien soon lu" if player=="lu chien-soon"
replace player="rich bland" if player=="richard bland"
replace player="yu-shu hsieh" if player=="hsieh yu-shu"
replace player="hyung-tae kim" if player=="hyungtae kim 404"
replace player="andreas harto" if player=="andreas hartø"
replace player="lee james" if player=="lee s james"
replace player="min-nan hsieh" if player=="hsieh min-nan"
replace player="david tenis" if player=="david tentis"
replace player="whee kim" if player=="meenwhee kim"
replace player="sang ho choi" if player=="sangho choi"
replace player="nandesena perera" if player=="nanda perera"
replace player="liang-hsi chen" if player=="chen liang-hsi"
replace player="bernard gallacher" if player=="bnard gallacher"
replace player="steve bowman" if player=="steven bowman"
replace player="zack miller" if player=="zach miller"
replace player="phil harrison" if player=="philip harrison"
replace player="ss hong" if player=="soonsang hong"
replace player="nam-sin park" if player=="namsin park"
replace player="hao tong li" if player=="li haotong"
replace player="greg meyer" if player=="gregory meyer"
replace player="billy kratzert" if player=="bill kratzert"
replace player="ray barr jr" if player=="ray barr"
replace player="ej pfister" if player=="e j pfister"
replace player="griffin rudolph" if player=="griff rudolph"
replace player="russell beiersdorf" if player=="rusl beiersdorf"
replace player="christian chernock" if player=="chrin chernock"
replace player="rw eaks" if player=="r w eaks"
replace player="lee m williamson" if player=="lee williamson"
replace player="eddie kirby" if player=="ed kirby"
replace player="timothy oneal" if player=="tim oneal"
replace player="chris van der velde" if player=="c van der velde"
replace player="periasamy gunasagaran" if player=="p gunasegaran"
replace player="jc anderson" if player=="j c anderson"
replace player="alan t pate" if player=="alan pate"
replace player="david delong" if player=="david de long"
replace player="tim robyn" if player=="timothy robyn"
replace player="bill dodd" if player=="bill dodd jr"
replace player="steven veriato" if player=="steve veriato"
replace player="mark w johnson" if player=="mark johnson"
replace player="charlie bowles" if player=="charles bowles"
replace player="john deforest" if player=="john de forrest"
replace player="nathan gatehouse" if player=="nan gatehouse"
replace player="kip p byrne" if player=="kip byrne"
replace player="per nyman" if player=="per g nyman"
replace player="bob bilbo" if player=="robert bilbo"
replace player="chi chi rodriguez" if player=="c chi rodriguez"
replace player="gene elliott" if player=="eugene elliott"
replace player="charlie whittington" if player=="che whittington"
replace player="willie kane" if player=="william kane"
replace player="bill j murchison" if player=="bill murchison"
replace player="james m johnson" if player=="james johnson"
replace player="justin aus smith" if player=="justin smith"
replace player="justin smith" if player=="justin b smith"
replace player="ap botes" if player=="a p botes"
replace player="david j white" if player=="david white"
replace player="robert conrad" if player=="bob conrad"
replace player="stephan gross" if player=="stephan gross jr"
replace player="darryl donovan" if player=="darryl donavan"
replace player="orrin vincent iii" if player=="orn vincent iii"
replace player="troy denton" if player=="trey denton"
replace player="michael board" if player=="mike board"
replace player="dennis harrington" if player=="des harrington"
replace player="gary trivisonno" if player=="gary trevisonno"
replace player="michael burke jr" if player=="michael burke"
replace player="gene jones" if player=="t gene jones"
replace player="michael walton" if player=="mike walton"
replace player="michael pearson" if player=="mike pearson"
replace player="ralph howe iii" if player=="ralph howe"
replace player="clay ogden" if player=="clayton ogden"
replace player="john paul curley" if player=="john curley"
replace player="randall hutchison" if player=="randall hutchinson"
replace player="dan mccarthy" if player=="daniel mccarthy"
replace player="jeff rangel" if player=="jeffrey rangel"
replace player="olin d browne jr" if player=="olin browne jr"
replace player="bob gaus" if player=="robert gaus"
replace player="todd oneal" if player=="t oneal"
replace player="miguel rodriguez" if player=="miguel angel rodriguez"
replace player="heinz peter thul" if player=="heinz p thul"
replace player="lu-liang huan" if player=="lu liang-huan"
replace player="seong ho lee" if player=="seongho lee"
replace player="wook-soon kang" if player=="wooksoon kang"
replace player="xin-jun zhang" if player=="zhang xin-jun"
replace player="shin yong-jin" if player=="yongjin shin"
replace player="marc pucay" if player=="marciano pucay"
replace player="pedro martinez" if player=="pedro rodolfo martinez"
replace player="steve dartnall" if player=="stephen dartnall"
replace player="marimuthu ramyah" if player=="marthu ramayah"
replace player="amandeep singh johl" if player=="amandeep johl"
replace player="jeff wagner" if player=="jeffrey wagner"
replace player="michel besanceney" if player=="mil besanceney"
replace player="antonio o cerda" if player=="antonio cerda"
replace player="ho ming chung" if player=="ho ming-chung"
replace player="ricky kawagishi" if player=="ryoken kawagishi"
replace player="michael cunning" if player=="mike cunning"

/* 1.II.5.i.) Save OWGR data */
save data/owgr.dta, replace

/*******************************************************/
/* 1.II.6.) Merge OWGR and Rounds Data                 */
/*                                                     */
/*       - At the month level. Take a golfer's         */
/*		   medina OWGR in any given month. No need     */
/*		   to be precise on timnig.                    */
/*******************************************************/
use data/owgr.dta, clear

/* 1.II.6.a.) Collapse to OWGR data to monthly level
	- Take median OWGR for month    */
collapse (median) owgr max_owgr, ///
	by(year month player cntry_code)

/* 1.II.6.b.) Save OWGR data by month */
save data/owgr_month.dta, replace
replace month=11 if year==1988 & month==12
restore

/* 1.II.6.c.) Merge in OWGR data */
merge m:1 player year month using data/owgr_month.dta

/* 1.II.6.d.) Replace missing OWGR with maximum OWGR */
sort year month
by year month: egen x=mean(max_owgr)
replace max_owgr=x
drop x
replace owgr=max_owgr if owgr==.

/* 1.II.6.e.) Drop golfers than are only in OWGR data */
drop if _merge==2
drop _merge

/* 1.II.6.f.) Label and format */
sort tour year tour_num round_num finish_round
label variable owgr "Official World Golf Ranking"
label variable max_owgr "Maximum value of OWGR in contemporaneous month"

/* 1.II.6.g.) Drop outliers scores (unfinished rounds) */
drop if score<58

/*******************************************************/
/*                                                     */
/*     1.II.7.) Create adjusted round score based      */
/*			on field average OWGR.                     */
/*                                                     */
/*     - Don't estimate the adjustment equation        */
/*		separately for different OWGR quantiles.       */
/*		Need to be a constant adjustment factor for    */
/*		everyone or else performance measure can       */
/*		change simply b/c OWGR changes. 		       */
/*                                                     */
/*******************************************************/

/* 1.II.7.a.) Create field mean score, field mean/median OWGR */
bysort tour year tour_num round: egen field_score_round = mean(score)
label variable field_score_round "Round Scoring Average"
bysort tour year tour_num round: egen mean_field_owgr = mean(owgr)
label variable mean_field_owgr "Mean Field OWGR"
bysort tour year tour_num round: egen median_field_owgr = median(owgr)
label variable median_field_owgr "Median Field OWGR"
gen rel_score = score - field_score_round
label variable rel_score "Relative Score to Field Average"
gen adj_rel_score=.
label variable adj_rel_score "Field Adjusted Relative Score"
order rel_score adj_rel_score, after(score)

/* 1.II.7.b.) Create leave-out mean field */
bysort tour year tour_num round: egen n_field = count(owgr)
gen lomean_field_owgr=(mean_field_owgr-(owgr/n_field))*(n_field/(n_field-1))
label variable n_field "# of Golfers in Field"
label variable lomean_field_owgr "Leave-Out Mean Field OWGR"

/* 1.II.7.c.) Create alternative variables for adjusted score regressions */
gen x = lomean_field_owgr
gen z = owgr

/* 1.II.7.d.) Adjusted score regressions:	Score - Mean Score = f(OWGR,Field Average OWGR)
		+
		Create new adjusted score measure based on strength of the field */
sort year
forvalues i=1989/2014{
reg rel_score c.z##c.z##c.z c.x##c.x##c.x if year==`i'
/* 1.II.7.d.1.) predict residuals for estimation sample */
predict res if e(sample), residuals
/* 1.II.7.d.2.) change leave-out mean field to annual average leave-out mean field */
rename x x2
by year: egen x = mean(x2)
/* 1.II.7.d.3.) create predicted score with average quality field */
predict yhat if e(sample), xb
drop x
rename x2 x
/* 1.II.7.d.4.) field adjusted score = predicted score with average field + residual */
replace adj_rel_score = yhat + res if e(sample)
drop yhat res
}
drop x z 

/* 1.II.8.) Save  */
save data\rounds_PGA_Web.dta, replace
cap log close
