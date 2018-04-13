*****************************************************************************
** DO FILE ******************************************************************
** LIVIA JAKOB **************************************************************
*****************************************************************************

**INITIAL SETTINGS***********************************
*set working directory
cd /Applications/Stata/ba_files

*create log-file
log using ba.log, append

**close logfile
*log close

**DATA SETTINGS & IMPORTS*****************************

** load dataset
use "EHPM 2015.DTA"

** save dataset
save "EHPM 2015.DTA", replace

** import traveltimes
import delim using traveltimes.csv, delim(",")
rename cod_mun4 r005
rename urb_rur area
save traveltimes.dta, replace


** merge traveltime with ehpm dataset
merge m:1 r005 area using traveltimes.dta
drop if _merge==2
save "EHPM 2015.DTA", replace

** Upper case variables
foreach v of varlist _all {
   capture rename `v' `=upper("`v'")'
}


*******************************************************************************
** SURVEY SETTINGS *******************************************

*VAR -- Generate household IDs ****

gen HH_temp=0
sort IDBOLETA
replace HH_temp=HH_temp+1 if IDBOLETA!=IDBOLETA[_n-1]
gen HH_ID=sum(HH_temp)
drop HH_temp

gen PERS_ID =_n

*VAR -- fpc1 = Number of PSUs (in population)****
sum LOTE // According to EHPM Publication 2012: 12423
gen fpc1=12423

*VAR -- fpc2 = number of households (in population)****
sum HH [w=FAC] // Sample: 88 184 people,  23670 households;  Population: 6 459 911 people
sum R021A if R101==1 [w=FAC00]
sum MIEMH  if R101==1 [w=FAC00] // 3.666712 (average # of household members)
dis 6459911/3.66647
gen fpc2= 1761887 // estimated number of households in population

drop if LOTE==3254 // Error in data!

*SVY -- set survey structure****
svyset LOTE [pweight=FAC00], strata(ESTRATOAREA) fpc(fpc1) || HH_ID, fpc(fpc2)
svyset LOTE [pweight=FAC00], strata(ESTRATOAREA)|| HH_ID // without finite pop correction


********************************************************************************
** GENERATE VARIABLES (VAR) *****************************************

clonevar age = R106
clonevar sex = R104
clonevar fam_income = INGFA
clonevar studying = R203 // 1=yes ;; 2=no

*VAR -- highest level of education
clonevar educ_level = R217A // not recorded when studying
tab educ_l
tab educ_level, nolab mis
recode educ_level (1=0) (2=1) (3=2) (4=3) (5=3) (6=.) (7=.) (8=0)
label define educ_level 0 "No Education/Kindergarten" 1"Basic Education" ///
2"Secondary Education" 3"Tertiary Education"
label values educ_level educ_level

*VAR -- actual level of education
clonevar study_what_ = R204
clonevar study_what = R204 // does not recorded when not studying at the moment
recode study_what (1=0) (2=1) (3=2) (4=3) (5=3) (6=.)
label values study_what educ_level //label
tab study_what

clonevar level_when_study = study_what
tab level_when
tab level_when, nolab
recode level_when (1=0) (2=1) (3=2) (4=2) //code the highest achieved level
tab level_when

*VAR -- merge highest level of educ for studying and finished studies****
replace educ_level = level_when if level_when!=. //now with records when studying (last finished level)

tab educ_level
clonevar ever_studied = R215
tab ever, nolab
replace educ_level = 0 if ever_studied==2
tab educ_level if age>4, mis

*VAR -- University****
tab R204, nolab // 4 = uni
gen uni_studying = R204==4
gen uni_level = R217A==4
gen uni_both = uni_level + uni_study

*VAR -- Tertiary****
tab R204, nolab // 4 = uni, 5 =tecnico
gen tert_studying = R204==4 | R204==5
gen tert_level = R217A==4 | R217A==5
gen tert_both = tert_level + tert_study // finished tertiary or still studying

*VAR -- Secondary****
tab R204
tab R204, nolab // 3 = High school
gen secondary_study = R204==3
gen secondary_level = educ_level>=2
gen secondary_both = secondary_study + secondary_level

*VAR -- Primary****
gen primary_study= R204==2
gen primary_level = educ_level>=1
gen primary_both = primary_study + primary_level


*VAR -- Status: Parents highest educational attainment ****

gen individual = R103 == 3 // R103: 3=son/daughter ;; individual=1 when hijo/a
gen jefe = .
replace jefe = educ_level if R103==1 // R103: 1=jefe(head)
sort HH_ID
egen level_jefe = max(jefe), by(HH_ID)
tab level_jefe

gen esposa = . //wife or husband (note: also stepparents allowed)
replace esposa = educ_level if R103==2
sort HH_ID
egen level_esposa = max(esposa), by(HH_ID)
tab level_esposa

gen father = .
replace father = level_jefe if R103==1 & sex==1
egen level_father = max(father), by(HH_ID)
tab level_father

gen mother = .
replace mother = level_jefe if R103==1 & sex==2
replace mother = level_esposa if R103==2
egen level_mother = max(mother), by(HH_ID)

tab level_mother
label values level_m level_f level_e level_j educ_level

svy: tab level_mother if individual==1
svy: tab level_father if individual==1

egen level_both_max = rowmax(level_mother level_father) //max of both parents education
label define levels_educ_ 0 "No education" 1"Primary" 2"Secondary" 3"Tertiary"
label values level_both_max levels_educ_

*VAR -- Household equivalence income****
tab MIEMH
gen plus14 = age>=14
sort HH_ID
egen miem14plus = sum(plus14), by(HH_ID)
gen zeroto13 = age <14
egen miem_under14 = sum(zeroto13 ), by(HH_ID)
gen memb_weight = 0.5 + 0.5*miem14plus + 0.3*miem_under14 //OECD definition: adult 1 is counted double: 2*0.5=1
tab memb_w

gen household_equivalence_income = fam_income/memb_w
gen log_household_equivalence_income =ln(household_equivalence_income)

*VAR -- Household equivalence income without own income****
gen household_income2 = fam_income-INGRE
gen equivalence_income2 = household_income2/memb_w
gen log_equivalence_income2 =ln(equivalence_income2)
label variable log_equivalence_income2 "Family income"

*VAR -- square root household income****
gen sqrt_income = fam_income/sqrt(MIEMH)

*VAR Income Quartiles
xtile income_quartile=household_equivalence_income [w=FAC], n(4)
xtile income_decile=household_equivalence_income [w=FAC], n(10)

*VAR -- children secondary_level, where famliy characteristics are known
gen child_secondary = (secondary_level == 1 & individual==1 & age <30 & age >18)

*VAR -- secondary level, where famliy characteristics are not known
gen notchild_secondary = (secondary_level == 1 & individual==0 & age <30 & age >18)

*VAR -- Hours to closest tertiary institution
gen minhours= MINDIST/60
label variable minhours `" "Hours to the"  "closest institution" "'

*VAR -- Hours to closest public university
gen pub_minhours= min_publ/60
label variable pub_minhours  "Hours to closest public university"

*VAR -- Income: Half, Tertile, Quartile
ssc install egenmore
sort log_equivalence_income2
egen rich = xtile(log_equivalence_income2), nq(2)

xtile income_third=log_equivalence_income2 [w=FAC], n(3)
label define tertile_label 1 "First Tertile" 2"Second Tertile" 3"Third Tertile"
label values income_third tertile_label

xtile income_quartile2=log_equivalence_income2 [w=FAC], n(4)
label define quartile_label 1 "First Quartile" 2"Second Quartile" 3"Third Quartile" 4"Fourth Quartile"
label values income_quartile2 quartile_label

egen income_third_whithInd = xtile(log_equivalence_income), nq(3)
label values income_third_whithInd tertile_label

*VAR -- centered income
ssc install center
center log_equivalence_income2, generate(c_income)

*VAR -- Labels
label define area_label 0 "Rural" 1"Urban"
label values AREA area_label
label define gender_label 1 "Male" 2"Female"
label values sex gender_label

**LAYOUT**********************************************************************
set scheme s2mono


******************************************************************************
*CALCULATIONS **************

*CALC -- MODEL 1: Time Radii with universities *******************************
svy: logit tert_both UNI30 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius1

svy: logit tert_both UNI45 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius2

svy: logit tert_both UNI60 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius3

svy: logit tert_both UNI90 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius4

svy: logit tert_both UNI120 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius5

svy: logit tert_both uni150 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius6 //not significant

svy: logit tert_both UNI180 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Radius7 //not significant

*Table*
esttab Radius1 Radius2 Radius3 Radius4 Radius5 Radius6 Radius7, ar2 se ///
varlabels( ///
2.sex "Gender (Female)" 0.AREA "Area (Ref. Rural)" 1.AREA "Urban" age "Age" ///
 ///
) starlevels(* 0.05 ** 0.01 *** 0.001)


*CALC -- MODEL 1. Time Radii with Carreras (study programs)
svy: logit tert_both CARR30 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr1

svy: logit tert_both CARR45 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr2

svy: logit tert_both CARR60 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr3

svy: logit tert_both CARR90 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr4

svy: logit tert_both CARR120 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr5

svy: logit tert_both CARR180 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr6 //not significant

*Table*
esttab Carr1 Carr2 Carr3 Carr4 Carr5 Carr6, ar2 se ///
varlabels( ///
2.sex "Gender (Female)" 0.AREA "Area (Ref. Rural)" 1.AREA "Urban" age "Age" ///
 ///
) starlevels(* 0.05 ** 0.01 *** 0.001) //similar effects like universities



*CALC -- MODEL 1: Time Radii with Carreras (study programs)
svy: logit tert_both CARR30 UNI30 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr11

svy: logit tert_both CARR45 UNI45 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr22

svy: logit tert_both CARR60 UNI60 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr33

svy: logit tert_both CARR90 UNI90 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr44

svy: logit tert_both CARR120 UNI120 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr55

svy: logit tert_both CARR180 UNI120 i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Carr66

esttab Carr11 Carr22 Carr33 Carr44 Carr55 Carr66, ar2 se ///
varlabels( ///
2.sex "Gender (Female)" 0.AREA "Area (Ref. Rural)" 1.AREA "Urban" age "Age" ///
) starlevels(* 0.05 ** 0.01 *** 0.001) //study programs have no significant effect anymore


****CALC MODEL 2 -- Without parents attributes
svy: logit tert_both c.minhours i.AREA i.sex age if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Margins_Superior_NoP
coefplot Margins_Superior_NoP, drop(_cons age) omitted baselevels xline(0) ///
coeflabels(minhours=`" "Hours to the "  "closest institution" "' 1.sex="Male (ref.)" ///
0.AREA="Rural (ref.)", labgap(5)) ysize(2) xsize(3)  ///
headings(1.sex= "{bf:Gender}" 0.AREA= "{bf:Area}" minhours = "{bf:Travel distance}" , labgap(5)) ///
title("Model 2: Individual and Spatial Characteristics", span) ///
name(superior_bac2, replace) xtitle(AMEs on study probability)

****CALC MODEL 3 -- With parents attributes (only hijos/hijas)
svy: logit tert_both c.log_equivalence_income2 i.level_both_max i.AREA i.sex c.age c.minhours ///
if age <30 & age >18 & secondary_level==1 & individual==1
margins , dydx(*) post
estimates store Margins_Superior_Parents
*GRAPH
coefplot Margins_Superior_Parents, drop(_cons age minhours 0.AREA 1.AREA 1.sex 2.sex) ///
omitted baselevels xline(0) coeflabels(0.level_both_max="No education (ref.)" ///
log_equivalence_income2="Equivalence income (log)", labgap(5))  ///
headings(0.level_both_max="{bf:Parents education}" ///
log_equivalence_income2= "{bf:Family income}" , labgap(5)) ///
title("Model 3: Family Income and Background", span) ///
name(superior_bac2, replace) xtitle(AMEs on study probability)

****CALC -- INTERACTIONS ****************************

*CALC INTERACTION 1 -- Interactions Income xx Distance
gen incomeXminhours = c_income*minhours

svy: logit tert_both c.c_income c.minhours c.incomeXminhours i.sex i.AREA c.age ///
if age <30 & age >18 & secondary_level==1 & individual==1
margins , dydx(*) post
estimates store Interaction1
*GRAPH
coefplot Margins_Superior_Interact1, drop(_cons age) omitted baselevels xline(0) ///
coeflabels(0.level_both_max="No education (ref.)" , labgap(5))  ///
headings(0.level_both_max=`"{bf:Parents education}"' 0.log_equivalence_income2= "{bf:Family income}" ///
1.sex= "{bf:Gender}" 0.AREA= "{bf:Area}" , labgap(5)) ///
title("Logit Model", span) name(superior_bac2, replace) xtitle(AMEs on Study Probability)


*CALC INTERACTION 2 -- Interactions Parents education xx Distance
gen lev = level_both_max ==0 if level_both_max !=.
gen levXminhours = lev * minhours
gen lev1 = level_both_max ==1 if level_both_max !=.
gen lev1Xminhours = lev1 * minhours
gen lev2 = level_both_max ==2 if level_both_max !=.
gen lev2Xminhours = lev2 * minhours
gen lev3 = level_both_max ==3 if level_both_max !=.
gen lev3Xminhours = lev3 * minhours

svy: logit tert_both c.minhours i.level_both_max c.lev1X c.lev2X c.lev3X i.AREA i.sex c.age ///
if age <30 & age >18 & secondary_level==1 & individual==1
margins , dydx(*) post
estimates store Interaction2
*GRAPH
coefplot Margins_Superior_Interact, drop(_cons age) omitted baselevels xline(0) ///
coeflabels( , labgap(5))  ///
headings(0.level_both_max=`"{bf:Parents education}"' 0.log_equivalence_income2= "{bf:Family income}" ///
1.sex= "{bf:Gender}" 0.AREA= "{bf:Area}" , labgap(5)) ///
title("Interaction Model: Parental Education and Distance", span) name(superior_bac2, replace) ///
xtitle(AMEs on Study Probability)

****CALC INTERACTION 3 -- Interactions Gender xx Distance //not significant

gen men = sex ==1 if sex !=.
gen menXminhours = men * minhours
gen women = sex ==2 if sex !=.
gen womenXminhours = women * minhours

svy: logit tert_both i.sex c.minhours c.womenXminhours i.AREA c.age ///
if age <30 & age >18 & secondary_level==1
margins , dydx(*) post
estimates store Interaction3
*GRAPH
coefplot Margins_Superior_Interact4, drop(_cons age) omitted baselevels xline(0) ///
coeflabels( , labgap(5))  ///
headings(0.level_both_max=`"{bf:Parents education}"' ///
0.log_equivalence_income2= "{bf:Family income}" ///
1.sex= "{bf:Gender}" 0.AREA= "{bf:Area}" , labgap(5)) ///
title("Interaction Model: PGender and Distance", span) name(superior_bac2, replace) ///
xtitle(AMEs on Study Probability)


**TABLE INTERACTION 1 - 3 ****
esttab Interaction1 Interaction2 Interaction3, ar2 se ///
varlabels(1.sex "Gender (Ref. Male)" ///
2.sex "Female" 0.AREA "Area (Ref. Rural)" 1.AREA "Urban" age "Age" ///
c_income "Family Income (centered)" minhours "Hours to Closest Institution" ///
incomeXmin "Interaction Income and Distance" ///
) starlevels(* 0.05 ** 0.01 *** 0.001)


****************************************************************
**COMPARING SAMPLES

**SAMPLE 1 without family attributes
tab tert_both if age<30 & age>18 & secondary_level==1
tab sex if age<30 & age>18 & secondary_level==1
tab AREA if age<30 & age>18 & secondary_level==1
mean age if age<30 & age>18 & secondary_level==1
mean log_equivalence_income2 if age<30 & age>18 & secondary_level==1
mean minhours if age<30 & age>18 & secondary_level==1

**SAMPLE 2 for family attributes
tab tert_both if age<30 & age>18 & secondary_level==1 & individual==1
tab sex if age<30 & age>18 & secondary_level==1 & individual==1
tab AREA if age<30 & age>18 & secondary_level==1 & individual==1
mean age if age<30 & age>18 & secondary_level==1 & individual==1
mean log_equivalence_income2 if age<30 & age>18 & secondary_level==1 & individual==1
mean minhours if age<30 & age>18 & secondary_level==1 & individual==1
