/*==================================================
project:       Equation of intragenerational mobility
Author:        Andres Castaneda 
----------------------------------------------------
Creation Date:    14 Dec 2018 - 11:29:32
==================================================*/

/*==================================================
                        0: Program set up
==================================================*/
program define intramob_eq
version 14
set more off
	`0'
end

program Msg
	di as txt
	di as txt "-> " as res `"`0'"'
end

program Xeq
	di as txt
	di as txt `"-> "' as res _asis `"`0'"'
	`0'
end


program equations 
Msg preserve
preserve
drop _all
set obs 2
gen x = 1  
gen y = _n 
#delimit ;

local formula1 (1)  {&sum}{sup:N}(Y{sub:1i}{sup:1i} {&minus}  
  X{sup:1}{&beta}) + {&lambda}{&sum}[{&alpha}|{&beta}{sub:s}| + 
 (1 {&minus} {&alpha}){&beta}{sub:s}{sup:2}]);


local formula2 (2)  Y{sup:^}{sup:2}{sub:1i}=X{sup:1}{&beta}{sub:1} +  
 [(1 {&minus} {&gamma}){&epsilon}{sup:~2}{sub:1i} +                   
  {&gamma}({&sigma}{sup:^}{sub:1} {&frasl} {&sigma}{sup:~}{sub:2})    
 {&epsilon}{sup:^2}{sub:i2}]{&lowast}{&delta};

Msg Creating equations;
twoway scatter y x, msymbol(i)               
 text(2 1 "`formula1'", place(e) size(large))    
 text(1 1 "`formula2'", place(e) size(large))    
 xscale(off range(1 5)) yscale(off range(0 3))   
 title("Equations");
 
#delimit cr 
Msg restore 
end 

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
