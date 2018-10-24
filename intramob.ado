/*==================================================
project:       intra-generational economic mobility using cross-sectional data
Author:        Andres Castaneda & Leonardo Lucchetti 
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    23 Oct 2018 - 15:16:17
Modification Date:   
Do-file version:    01
References:          
Output:             dta xlsx
==================================================*/

/*==================================================
            0: Program set up
==================================================*/


program define intramob, rclass 
version 14
syntax [anything(name=equation id="equation list")] [if] [in] [using/] [aw fw iw pw] , [	/* 	
		*/  Yvar(varname)               /*  Y var
		*/  Xvar(varlist)               /*  Covariates
		*/  PLVALues(numlist)           /*  Poverty lines values
		*/  PLVARs(varlist)             /*  Poverty lines variable
		*/  METhod(string)              /*  Estimation methodology
		*/  by(varname numeric)         /*  by, in case using not selected
		*/  reverse                     /*  Reverse order in by(varname)
		*/  noLOG                       /*  Logarithmic form
		*/  noGEN                       /*  No generate variable
		*/  WFname(string)              /*  Welfare variable name
		*/  MBname(string)              /*  Mobility var name
		*/  APname(string)              /*  Actual poor var name
		*/  PPname(string)              /*  Predicted poor var name
		*/ 	*			                      /// options for other commands 
		]  

marksample touse
		
		
/*==================================================
              1: Conditions
==================================================*/

qui {

*---------- Logarithmic form
if ("`log'" == "nolog") {
	noi disp in y "Dependent variable and poverty lines won't be transformed to " /* 
	*/ "natural logarithmic scale. Either they are already in log scales or "  /* 
	*/ "you want to perform the analysis in nominal scale (not recommended)."
}
else {
	noi disp in y "Dependent variable and poverty lines {bf:will} be transformed to " /* 
	*/ "natural logarithmic scale."
}


*---------- Install SSC commands

local sscados "lasso2"

foreach ado of local sscados {
	cap which `ado'
	if _rc {
		ssc install `ado'
	}
}


* Methods available
if ("`method'" == "") local method "lasso"

local methods =  `" "lasso",  "synpan" "'   // add more methods
if !inlist("`method'", `methods') { // add other methods   
		noi disp in red `"you must select one of the following methods: `methods'"'
		error
}


*---------- `equation' and Yvar and Xvar

if ("`equation'" == "" & "`yvar'" == "" & "`xvar'" == "") {
	noi disp in r "you must specify either {it:depvar} and {it:indepvars}"
	error
}


if ("`equation'" != "" & ("`yvar'" != "" | "`xvar'" != "")) {
	noi disp in r "you must specify {it:depvar} and {it:indepvars} in using one of " /* 
  */  "the two syntaxes {help intramob}"
	error
}

*---------- Parse equation

if ("`equation'" != "") {
	gettoken yvar xvar: equation
}

*---------- Poverty line
if ("`plvalues'" != "" & "`plvars'" != "") {
	noi disp in r "you must select either {it:plvalues(numlist)} or {it:plvars(varlist)}"
	error
}
if ("`plvalues'" == "" & "`plvars'" == "") {
	sum `yvar' `wcond', det
	local plvalues = round(r(p50)/2)
} 

if ("`plvalues'" != "") {
	foreach pl of local plvalues {
		tempvar pl_`pl'
		gen `pl_`pl'' = `pl'
		local plvars = "`plvars' `pl_`pl''"
	}
}



*---------- Logarithmic form
if ("`log'" != "nolog") {
	replace `yvar' = ln(`yvar')
}


*---------- Weights and conditions
local allcond "`if' `in' [`weight' `exp']"
local wcond   "[`weight' `exp']"

*---------- using or by
if ( ("`using'" == "" & "`by'" == "") |      /* None of them  
 */  ("`using'" != "" & "`by'" != "")  ) {   // both of them
	noi disp in r "you must specify either {it:using} or {it:by}"
	error
}  

if ("`by'" != "") {
	* check it only has two values (this is faster than levelsof)
	tempvar uniq
	sort `by' `touse'
  by `by': gen byte `uniq' = (`touse' & _n==_N)
  summ `uniq'
	if (r(sum) != 2) {
		noi disp in r "{it:by(varname)} must contain only two unique values"
		error
	}
	
	* get main dataset
	tempvar by2
	if ("`reverse'" == "reverse") {
		gen `by2' = -1*`by'
	}
	else {
		gen `by2' = `by'
	}
	
	sum `by2', meanonly
	local year1 = abs(r(min))
	local year2 = abs(r(max))
	
	tempfile fy1 fy2
	preserve 
		keep if `by' == `year2'
		save `fy2'
	restore
	keep if `by' == `year1'
	
}

if ("`using'" != "") {
	local fy2 = `" "`using'" "'
}


*---------- Methodology

tokenize "`method'", parse(",")
local method = "`1'"

local subcmd: subinstr local 3 "(" `"=""', all
local subcmd: subinstr local subcmd ")" `"""', all


tokenize `"`subcmd'"', parse(" ")
local i = 1
while ("``i''" != "") {
	if regexm(`"``i''"', "=") {
		local ``i''
	}
	else {
		local ``i'' = "``i''"
	}
	local ++i
}	

if ("`method'" == "lasso") local regcmd = "lasso2"





*----------
*----------
*----------
*----------
*----------


/*==================================================
          Implementation of method
==================================================*/


*----------implementation

`regcmd' `yvar' `xvar', `options'
* noi return list 
* noi ereturn list 

if ("`method'" == "lasso") {
	
	if ("`mincrit'" == "") {
		local mincrit = "aic" // bic ebic aicc
	}
	local lmin  = r(l`mincrit'id)
}
return add
 

*----------predict
use `fy2', clear

tempvar yhat
predict double `yhat', xb lid(`lmin')

if ("`log'" != "nolog") {      // transform back to nominal scale
	replace `yhat' = exp(`yhat') 
}

* create 
if ("`using'" != "") {
	local v = 0
	foreach pl of local plvalues {
		local ++v
		local plvar: word `v' of `plvars'
		gen `plvar' = `pl'
	}
}


/*==================================================
       Calculate  poor status and mobility 
==================================================*/

*---------- define label

label define mobility         /* 
 */  1 "remained poor"        /* 
 */  2 "fell into poverty"    /*  
 */  3 "escaped poverty"      /* 
 */  4 "remained non-poor"
 
label define poor        /* 
 */ 1 "poor"             /* 
 */ 0 "non-poor"


local v = 0
foreach pl of local plvars {
	local ++v
	tempvar poor_`v' poor_`v'_pr mobility_`v'

	* Actual poor status
	gen `poor_`v'' = . 
	replace `poor_`v'' = 1 if `yvar' < `pl'
	replace `poor_`v'' = 0 if `yvar' > `pl' & `yvar' <.
	
	* predicted poor status
	gen `poor_`v'_pr' = . 
	replace `poor_`v'_pr' = 1 if `yhat' < `pl'
	replace `poor_`v'_pr' = 0 if `yhat' > `pl' & `yhat' <.
	
	*mobility
	gen `mobility_`v'' = .
	replace `mobility_`v'' = 1 if `poor_`v'' == 1 & `poor_`v'_pr' == 1 
	replace `mobility_`v'' = 2 if `poor_`v'' == 0 & `poor_`v'_pr' == 1 
	replace `mobility_`v'' = 3 if `poor_`v'' == 1 & `poor_`v'_pr' == 0 
	replace `mobility_`v'' = 4 if `poor_`v'' == 0 & `poor_`v'_pr' == 0 
	
	label values `mobility_`v'' mobility
	label values `poor_`v'_pr' `poor_`v'' poor
}



/*==================================================
        Display results
==================================================*/
*----------

*----------
*----------


/*==================================================
        gen variables
==================================================*/

if ("`gen'" != "nogen") {
	
	local v = 0
	foreach pl of local plvars {
		local ++v
		local i = `v'
		
		if (wordcount("`plvars'") == 1 ) local i = ""
		* Mobility
		if ("`mbname'" == "") local mbname2 = "mobility`i'"
		else                  local mbname2 = "`mbname'`i'"
		clonevar `mbname2' = `mobility_`v''
		
		* Actual poverty
		if ("`apname'" == "") local apname2 = "poor`i'"
		else                  local apname2 = "`apname'`i'"
		clonevar `apname2' = `poor_`v''
		
		* Predicted poverty 
		if ("`ppname'" == "") local ppname2 = "poor`i'_pr"
		else                  local ppname2 = "`ppname'`i'"
		clonevar `ppname2' = `poor_`v'_pr'
	}

}  // end of no gen

*welfare variable
if ("`wfname'" == "") local wfname = "`yvar'_p"
clonevar `wfname' = `yhat'


} // end of qui


end
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


local method "lasso2, mincrit(aic) hola(chao) adios"
local method "lasso2"
tokenize "`method'", parse(",")

local i = 1
while ("``i''" != "") {
	disp "`i': ``i''"
	local ++i
}

local subcmd: subinstr local 3 "(" `"=""', all
local subcmd: subinstr local subcmd ")" `"""', all


tokenize `"`subcmd'"', parse(" ")
local i = 1
while ("``i''" != "") {
	if regexm(`"``i''"', "=") {
		local ``i''
	}
	else {
		local ``i'' = "``i''"
	}
	gettoken nlocal : `i', parse("=")
	disp `"`i': `nlocal' : ``nlocal'' "'
	local ++i
}



/*==================================================
               
==================================================*/

/*==================================================
               
==================================================*/

/*==================================================
               
==================================================*/

/*==================================================
               
==================================================*/


*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------
*----------

*----------
*----------
*----------
