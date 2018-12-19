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
		*/  Yvar(varname)                         /*  Y var
		*/  Xvar(varlist)                         /*  Covariates
		*/  PLVALues(numlist)                     /*  Poverty lines values
		*/  PLVARs(varlist)                       /*  Poverty lines variable
		*/  by(varname numeric)                   /*  by, in case using not selected
		*/  reverse                               /*  Reverse order in by(varname)
		*/  LAMbdas(numlist)                      /*  Lambda
		*/  ALPhas(numlist >=0 <=1 sort)          /*  Alphas
		*/  GAMmas(numlist >=0 <=1 sort)          /*  Gammas
		*/  DELtas(numlist integer max=2 >=0 <=1) /*  Delta
		*/  REGModels(string)                     /*  Regression models
		*/  REGOpts(string)                       /*  options for regress command for REGModels == "reg"
		*/  LASOpts(string)                       /*  options for lassso2 command for REGModels == "las"
		*/  LASMINcrit(string)                    /*  options for lassso2 command for REGModels == "las"
		*/  retro1(string)                        /*  retrospective variables in time 1
		*/  retro2(string)                        /*  retrospective variables in time 2
		*/  hhid(string)                          /*  household ID of survey in year 2
		*/  noLOG                                 /*  Logarithmic form
		*/  noGENY                                /*  No generate welfare variable
		*/  GENP                                  /*  Generate pov status variable
		*/  NRep(integer 100)                     /*  Replace existing variables
		*/  replace                               /*  Replace existing variables
		*/  pause                                 /*  for debuggin. 
		*/ 	]  

marksample touse

		
/*==================================================
              1: Conditions
==================================================*/

if ("`pause'" == "pause") pause on
else                      pause off

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

*------- Consistency of forumulas

if ("`regmodels'" == "") local regmodels "lasso regress"

* -- Lasso or Reg
if ("`lambdas'" == "") {
	tempvar grid
	range `grid' 10 -2 100
	replace `grid' = (10^`grid')*-1
	levelsof `grid', local(lambdas)
	local lambdas: subinstr local lambdas "-" "", all
	local lambdas = "`lambdas'" // add zero
}


* including errors or not (i.e., Synthetic panel or no).
if ("`deltas'" == "") local deltas = 0

if !regexm("`deltas'","^[01]$|^0 +1$|^1 +0$") {
	noi disp in r "{it:deltas} must be either zero (0) or one (1) or zero and one (0 1)"
	error
}

*---- Alphas
if ("`alphas'" == "") local alphas 1
if ("`gammas'" == "") local gammas 0.5

*---------- `equation' and Yvar and Xvar

if ("`equation'" == "" & "`yvar'" == "" & "`xvar'" == "") {
	noi disp in r "you must specify either {it:equation} of options {it:depvar} and {it:indepvars}"
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




*---------- Weights and conditions
local allcond "`if' `in' [`weight' `exp']"
local wcond   "[`weight' `exp']"


*---------- using or by
if ( ("`using'" == "" & "`by'" == "") |      /* None of them  
 */  ("`using'" != "" & "`by'" != "")  ) {   // both of them
	noi disp in r "you must specify either {it:using} or {it:by}"
	error
}  

tempfile idfile
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
		*--- Household ID
		if ("`hhid'" == "") {
			tempvar hhid
			gen `hhid' = _n
		}
		else {
			cap isid `hhid'
			if (_rc) {
				noi disp in r "Warning:" in y "Household ID variable is not unique." _n /* 
				 */ "an additional ID variable to identify members with household ID will be created."
					tempvar hhid
					gen `hhid' = _n
			}
		}
		
		save `fy2'
		sum `yvar', meanonly
		local N2  = `r(N)'
		
		keep `hhid'
		save `idfile'
 
	restore
	keep if `by' == `year1'	
	save `fy1'
}

if ("`using'" != "") {
	tempfile fy1
	save `fy1'
	
	local fy2 = `" "`using'" "'
	
	*--- Household ID
	if ("`hhid'" == "") {
		use `fy2', clear
		tempvar hhid
		gen `hhid' = _n
		
		tempfile fy2
		save `fy2'
		sum `yvar', meanonly
		keep `hhid'
	}
	else {
		use `hhid' using `fy2', clear
		des `yvar' using "`using'", short
	}
	local N2  = `r(N)'
	save `idfile'
	
}


*----------

/*==================================================
          Implementation of method
==================================================*/

foreach regm of local regmodels {
	local regcmd ""
	local alphause ""
	
	if regexm("`regm'", "^las") {
		local regcmd "lasso2"
		local modopt "`lasopts' lambda(`lambdas')"
		local l "p"
	
		local alphaoption "alpha(`alpha')"
	}
	if regexm("`regm'", "^reg") {
		local regcmd "regress"
		local modopt "`regopts'"
		local l "0"
		local alphaoption ""
	}
	if ("`regcmd'" == "") {
		noi disp in red "{it:`regm'} is not a {it:regmodels()} valid option."
		error
	}
	
	
/*==================================================
             implementation  
==================================================*/

*---------- Firs year
	foreach alpha of local alphas {
		
		if regexm("`regm'", "^las") {
			local alname = round(`alpha'*100, 1)
		}
		if regexm("`regm'", "^reg") {
			local alname      "na"
		}
		
		use `fy1', clear 
		*--- basic stats of Y1
		su `yvar' `wcond'
		local sd1 = `r(sd)'
		local mu1 = `r(mean)'
		local N1  = `r(N)'
			
		*---------- Logarithmic form
		if ("`log'" != "nolog") {
			replace `yvar' = .00001 if `yvar' == 0
			replace `yvar' = ln(`yvar')
		}
		
		
		`regcmd' `yvar' `xvar', `modopt' `alphaoption'
		if regexm("`regm'", "^las") {
			if ("`lasmincrit'" == "") {
					local mincrit = "aic" // bic ebic aicc
				}
			local lmin  = r(l`mincrit'id)
			local lmin = "lid(`lmin')"
		}
		else local lmin = ""

		tempvar res1
		predict double `res1' if e(sample), residuals `lmin'

		*---- get new order of population based on Y hat

		if ("`log'" != "nolog") {      // transform back to nominal scale
			tempvar y_m
			gen `y_m' = exp(`yvar') 
		}
		else {
			gen `y_m' = `yvar' 
		}
		drop if (`res1' == . | `y_m' == .)
		
		*--- random sample of survey 1 of size N2
		local c = ceil(`N2'/`N1')
		if (`c' > 1) expand `c'

		putmata Y=`y_m' res=`res1', replace 
		mata: _randvalues(`nrep', `N2', res, Y)		
		
		tempvar y1 res1
		
		drop _all
		getmata `y1' = Y 
		sort `y1'
		gen __order = _n
		tempfile match
		save `match'
		
		drop _all
		getmata `res1'=res
		label var `res1' " Residual in 1, varname `res1'"

		set seed 12345
		tempvar sortorder
		gen `sortorder' = runiform()
		sort `sortorder'
		gen __order = _n
		tempfile res1file
		save `res1file'


		*----------prediction in second year
		use `fy2', clear

		tempvar yhat
		predict double `yhat', xb `lmin'
		
		* rescale

		if ("`log'" != "nolog") {      // transform back to nominal scale
			replace `yhat' = exp(`yhat') 
		}
		sum `yhat' `wcond'
		local sd2 = `r(sd)'
		local mu2 = `r(mean)'
		
		
		*--- estimate residuals of second period
		if ("`log'" != "nolog") {
			replace `yvar' = .00001 if `yvar' == 0
			replace `yvar' = ln(`yvar')
		}
		
		`regcmd' `yvar' `xvar', `modopt' `alphaoption'
	
		tempvar res2
		predict double `res2', residuals `lmin'
		gen __order = _n
		merge 1:1 __order using `res1file', nogen 
		drop __order
		
		* create  if two data bases were used
		if ("`using'" != "") {
			local v = 0
			foreach pl of local plvalues {
				local ++v
				local plvar: word `v' of `plvars'
				gen `plvar' = `pl'
			}
		}
		

		foreach delta of local deltas {
			
			foreach gamma of local gammas {
		
				tempvar y_pred
				if (`delta' == 0) {
					local ganame = "na"
					gen double `y_pred' = (((`yhat'- `mu2') / `sd2') * `sd1') + `mu1'
				}
				
				else {
					local ganame = round(`gamma'*100, 1)
						
					gen double `y_pred' = `yhat' + ((`res1' *(1-`gamma')) +  /* 
					 */        (`res2' * `gamma' * (`sd1'/`sd2')))*`delta'
				}
				
				sort `y_pred'
				gen __order = _n
				merge 1:1 __order using `match',  nogen /* keep(match) */
				drop __order
				
				 
				local namer = "r_`l'_`alname'_`delta'_`ganame'" // rescaled
				local namem = "m_`l'_`alname'_`delta'_`ganame'" // matched
				
				tempvar Y_`namer' Y_`namem'
				
				gen double `Y_`namer'' = `y_pred'
				gen double `Y_`namem'' = `y1'
				
				* -------- Welfare variables
				if ("`geny'" != "nogeny") {
					foreach x in Y_`namer' Y_`namem' {
						cap confirm new var `x'
						if (_rc) {
							if ("`replace'" != "") drop `x'
							else {
								noi disp in red "variable `x' already exist. use option replace"
							}
						}
						clonevar `x' = ``x''
					} // end of loop of variables
				} // end of generate welfare variables condition
				

				/*==================================================
							 Calculate  poor status and mobility 
				==================================================*/
				local v = 0
				foreach pl of local plvars {
					local ++v
					
					tempvar p_a_a_a_a_a_`v'
          
					* Actual poor status
					gen     `p_a_a_a_a_a_`v'' = . 
					replace `p_a_a_a_a_a_`v'' = 1 if `yvar' < `pl'
					replace `p_a_a_a_a_a_`v'' = 0 if `yvar' > `pl' & `yvar' <.
					
					if ("`genp'" != "" & "`p_a_ok`v''" != "ok") {
							cap confirm new var p_a_a_a_a_a_`v'
							if (_rc) {
								if ("`replace'" != "") drop p_a_a_a_a_a_`v'
								else {
									noi disp in red "variable p_a_a_a_a_a_`v' already exist. use option replace"
									error
								}
							}
							clonevar p_a_a_a_a_a_`v' = `p_a_a_a_a_a_`v''
							local p_a_ok`v' "ok"
					}  // end of generate poverty status variables
					
					foreach n in namer namem {
						tempvar p_``n''_`v' m_``n''_`v'

						* predicted poor status
						gen     `p_``n''_`v'' = . 
						replace `p_``n''_`v'' = 1 if `Y_``n''' < `pl'
						replace `p_``n''_`v'' = 0 if `Y_``n''' > `pl' & `Y_``n''' <.
						
						*mobility
						gen     `m_``n''_`v'' = .
						replace `m_``n''_`v'' = 1 if `p_a_a_a_a_a_`v'' == 1 & `p_``n''_`v'' == 1 
						replace `m_``n''_`v'' = 2 if `p_a_a_a_a_a_`v'' == 0 & `p_``n''_`v'' == 1 
						replace `m_``n''_`v'' = 3 if `p_a_a_a_a_a_`v'' == 1 & `p_``n''_`v'' == 0 
						replace `m_``n''_`v'' = 4 if `p_a_a_a_a_a_`v'' == 0 & `p_``n''_`v'' == 0 
						
						/*==================================================
														gen variables
						==================================================*/
						* -------- Poverty Status
						if ("`genp'" != "") {
							
							foreach x in p_``n''_`v' m_``n''_`v' {
								
								cap confirm new var `x'
								if (_rc) {
									if ("`replace'" != "") drop `x'
									else {
										noi disp in red "variable `x' already exist. use option replace"
										error
									}
								}
								clonevar `x' = ``x''
							
							} // end of poor status and mobility
							
						}  // end of generate poverty status variables
						
						
					} // end of welfare loop
				} // end of poverty line loop
				
				if (`delta' == 0) continue, break
			} // end of gammas loop
		} // end of deltas loop (0, 1)
		*------- Save file
		
		pause before merging with  idfile 
		merge 1:1 `hhid' using `idfile',  nogen keep(using match)
		save `idfile', replace
		
		pause after merging with  idfile 
		
	} // end of alphas loop 
	
} // end of regression model selection 


use `idfile', clear

/*==================================================
							define label
==================================================*/


label define mobility         /* 
 */  1 "remained poor"        /* 
 */  2 "fell into poverty"    /*  
 */  3 "escaped poverty"      /* 
 */  4 "remained non-poor"
 
label define poor        /* 
 */ 1 "poor"             /* 
 */ 0 "non-poor"


 if ("`genp'" != "") {
	label values m_* mobility
	label values p_* `poor_`v'' poor
	local created "m p"
}

if ("`geny'" != "nogeny") {
	local created "`created' Y"
}


cap foreach x of local created {
	desc `x'_*, varlist
	local vars "`r(varlist)'"
	
	foreach var of local vars {
		
		tokenize `var', parse(_)
		
		
		if ("`1'" == "p") local type "Poverty,"
		else if ("`1'" == "m") local type "Mobility,"
		else if ("`1'" == "Y") local type "Welfare,"
		else local type ""
		
		
		if ("`3'" == "r") local adjt "re-scaled,"
		else if ("`3'" == "m") local adjt "matched,"
		else if ("`3'" == "a") local adjt "actual,"
		else local adjt  ""
		
		if      ("`5'" == "p") local method "elastic net,"
		else if ("`5'" == "0") local method "OLS,"
		else                   local method ""
		
		cap confirm number `7'
		if (_rc ==0) local alphat "Alpha: `=`7'/100',"
		else     local alphat ""
		
		if      ("`9'" == "0") local syntht "Simple,"
		else if ("`9'" == "1") local syntht "Synthetic panel,"
		else                   local syntht ""
		
		cap confirm number `11'
		if (_rc ==0) local gammat "Gamma: `=`11'/100',"
		else         local gammat ""
		
		cap confirm number `13'
		if (_rc ==0) local plt "Pov. line `13'"
		else local plt ""
		
		*noi disp "`type', `adjt', `method'`alphat' `syntht'`gammat' `plt'"
		label var `var' "`type' `adjt' `method' `alphat' `syntht' `gammat' `plt'"
	
	}
	
}




/*==================================================
        Display results
==================================================*/
*----------

*----------
*----------


} // end of qui


end

mata

void _randvalues(real scalar nrep, real scalar N2, 
                 real colvector res, real colvector Y) {

	rseed(76543219)
	
	yrows = rows(res)                            // No. of rows
	p = J(yrows,1,1/yrows)                       // matrix with probabilities
	index = rdiscrete(N2,nrep,p)                 // nrep random indeces 
	
	for(i=1;i<=nrep;i++) {                       // loop to create nrep 
		if  ( i == 1) R = res[index[,i],1]         
		else          R = R, res[index[,i],1]
	}
	
	res = mean(R')'
	
	index = rdiscrete(N2,1,p)
	Y = Y[index[,1],1]
}
			
end




exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

	
sysuse auto, clear
putmata Y=price  res=trunk, replace
drop _all
local N2 = 135
local nrep = 200
mata: _randvalues(`nrep', `N2', res, Y)		
getmata y_m=Y res1=res

*****************************8

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

 
gen a = `y_pred'
gen b = `y1'
sum b, det
mdensity a b if b < r(p90)


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


*----------
*----------
