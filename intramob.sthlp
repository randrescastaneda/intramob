{smcl}
{* *! version 1.0 24 Oct 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "intramob##syntax"}{...}
{viewerjumpto "Description" "intramob##description"}{...}
{viewerjumpto "Options" "intramob##options"}{...}
{viewerjumpto "Remarks" "intramob##remarks"}{...}
{viewerjumpto "Examples" "intramob##examples"}{...}
{title:Title}
{phang}
{bf:intramob} {hline 2} Intra-generational mobility in cross section

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:intramob}
[depvar regressors] [if] [{help in}] [using/]
[aw fw iw pw] {cmd:, } [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt plvar:s(varlist)}} set of variables with poverty lines values{p_end}
{synopt:{opt plval:ues(numlist)}} set of values of poverty lines{p_end}
{synopt:{opt noLOG}} no transformation to log scale of welfare variable.
default is to transform to log scale{p_end}
{synopt:{opt hhid}}{p_end}

{syntab:model specification}
{synopt:{opt lam:bda(numlist)}}{p_end}
{synopt:{opt alp:ha(>=0 <=1)}}{p_end}
{synopt:{opt gam:ma(>=0 <=1)}}{p_end}
{synopt:{opt del:ta(0|1|0 1)}}{p_end}
{synopt:{opt regm:odels(string)}}{p_end}

{syntab:generate}
{synopt:{opt genp}} generate mobility and poverty status variables. {p_end}
{synopt:{opt nogeny}} No generate predicted welfare variable. {p_end}
{synopt:{opt replace}} Replace existing output variables {p_end}

{syntab:Advance}
{synopt:{opt rego:pts}} specific options for regress command{p_end}
{synopt:{opt laso:pts}} specific options for lasso2 command{p_end}
{synopt:{opt lasmin:crit}} minimum criterion for lasso2{p_end}
{synopt:{opt nr:ep}} No. of repetitions for upper bound in synthetic panel{p_end}


{syntab:Alternative syntax}
{synopt:{opt y:var(varname)}} alternative syntax for dependent variable{p_end}
{synopt:{opt x:var(varlist)}} alternative syntax for regressors{p_end}
{synopt:{opt by(varname numeric)}} alternative syntax for {it:using}. It is assumed
that {it:by()} contains variable that splits data into master and using datasets.{p_end}
{synopt:{opt reverse}} reverse order between master and using datasets in 
{it:by()} variable.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:intramob} does ... <insert description>

{phang} 
The paremeters above correspond to the following ({stata intramob_eq equations :equations})

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt y:var(varname)}  

{phang}
{opt x:var(varlist)}  

{phang}
{opt plval:ues(numlist)}  

{phang}
{opt plvar:s(varlist)}  

{phang}
{opt met:hod(string)}  

{phang}
{opt by(varname numeric)}  

{phang}
{opt reverse}  

{phang}
{opt noLOG}  

{phang}
{opt noGEN}  

{phang}
{opt wf:name(string)}  

{phang}
{opt mb:name(string)}  

{phang}
{opt ap:name(string)}  

{phang}
{opt pp:name(string)}  

{phang}
{opt *			}  


{marker examples}{...}
{title:Examples}

{p 4 4 4}use "$input\modified dataset\cross 10.dta", clear{p_end}
{p 4 4 4}gen ipcf = exp(lipcf){p_end}
{p 4 4 4}drop lipcf{p_end}
{p 4 4 4}desc, varlist{p_end}
{p 4 4 4}local vars = "`r(varlist)'"{p_end}
{p 4 4 4}local  depvar ipcf{p_end}
{p 4 4 4}global depvar `depvar'{p_end}
{p 4 4 4}global indvars: list vars - depvar{p_end}

{p 4 4 4}{cmd:intramob} $depvar $indvars /* {p_end}
{p 8 8 4}*/  using "$input\modified dataset/cross 11.dta", genp /*{p_end}
{p 8 8 4}*/  alpha(0 0.5 1) gamma(0 0.5 1) delta(0 1) hhid(id) {p_end}


{title:Authors}

{p 4 4 4}R.Andres Castaneda, The World Bank{p_end}
{p 6 6 4}Email {browse "acastanedaa@worldbank.org":acastanedaa@worldbank.org}{p_end}

{p 4 4 4}Leonardo Lucchetti, The World Bank{p_end}
{p 6 6 4}Email {browse "llucchetti@worldbank.org":llucchetti@worldbank.org}{p_end}

