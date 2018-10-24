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
{synopt:{opt met:hod(string)}} estimation method. default {it: lasso}{p_end}
{synopt:{opt noLOG}} no transformation to log scale of welfare variable.
default is to transform to log scale{p_end}

{syntab:generate}
{synopt:{opt noGEN}} no generate mobility and poverty status variables. 
Predicted welfare variable is always generated. {p_end}
{synopt:{opt wf:name(string)}} name for predicted welfare variable. Default is 
{it:depvar}_p{p_end}
{synopt:{opt mb:name(string)}} name for predicted mobility variable. Default is 
mobility{p_end}
{synopt:{opt ap:name(string)}} name for actual poverty status variable. Default is 
poor{p_end}
{synopt:{opt pp:name(string)}} name for predicted poverty status variable. Default is 
poor_p{p_end}
{synopt:{opt *			}} options for {p_end}

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

{phang} <insert example command>

{title:Authors}

{p 4 4 4}R.Andres Castaneda, The World Bank{p_end}
{p 6 6 4}Email {browse "acastanedaa@worldbank.org":acastanedaa@worldbank.org}{p_end}

{p 4 4 4}Leonardo Lucchetti, The World Bank{p_end}
{p 6 6 4}Email {browse "llucchetti@worldbank.org":llucchetti@worldbank.org}{p_end}

