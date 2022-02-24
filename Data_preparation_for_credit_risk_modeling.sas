/* Credit Risk project on Loan Data */

/* Data description :

Bad Good/bad indicator 
  1 = Bad
  0 = Good

yob Year of birth (If unknown the year will be 99)
nkid Number of children
dep Number of other dependents
phon    Is there a home phone (1=yes, 0 = no)
sinc Spouse's income

aes Applicant's employment status 
  V = Government
  W = housewife
  M = military 
  P = private sector
  B = public sector
  R = retired
  E = self employed
  T = student
  U = unemployed
  N = others
  Z  = no response
  
  
dainc Applicant's income 
res Residential status 
  O = Owner
  F = tenant furnished
  U = Tenant Unfurnished
  P = With parents
  N = Other
  Z = No response

dhval Value of Home  
  0 = no response or not owner
  000001 = zero value
  blank = no response

dmort Mortgage balance outstanding
  0 = no response or not owner
  000001 = zero balance
  blank = no response

doutm Outgoings on mortgage or rent 
doutl Outgoings on Loans 
douthp Outgoings on Hire Purchase 
doutcc Outgoings on credit cards  */

/*Import Data */
libname score "/home/u60819583/";
run;

proc import datafile="/home/u60819583/SAS Modeling Code/Loan_data.xlsx" out=loan_data
	dbms = xlsx replace;
	getnames = yes;
run;

proc sort data = loan_data out=loan_data0;
by bad;
run;


data loan_data00 (drop=i);
	set loan_data0;
	array dh(2) dhval dmort;
	do i = 1 to 2;
		if dh(i) = ' ' then dh(i) = 0;
		else if dh(i)=000001 then dh(i) =0;
	end;
run;

data loan_data000 (drop=i);
	set loan_data00;
	array dh(2) aes res;
	do i = 1 to 2;
		if dh(i) = 'Z' then dh(i) = 'N';
	end;
	yob = 1900 + yob;
	age = 2002 - yob;
run;

/* Not selet where yob == 99*/
proc sql;
	create table loan_data1 as
	select * from loan_data000
	where yob <> 1999;
quit;

/* Replace missing values of numeric variables by median of each group*/
proc stdize data=loan_data1
	out=score.loan_data1
	reponly method=median;
	by bad;
run;

proc print data=loan_data1;
title "Loan data";
run;

/* Descriptive statistics */
proc freq data=score.loan_data1;
table bad;
run;

/*73% of clients have a good credit history, while 27% have not.
Good credit are over-represented */

proc univariate data=score.loan_data1;
class bad;
run;

/*Analysis of variance*/

/*Testing the equal variance assumption of bad and good credit*/


/* Test the normality assumption 
Dependent variable : bad
H0 : u0 = u1 versus H1: u0 # u1 */
proc ttest data=score.loan_data1 plots (only)=qq alpha=.05 h0=0;
class bad;
title 'Independent samples t-test for mean differences';
run;

/* Interpretation :
Individuals with good credit records and those with bad credit records 
have not on average the same number of children. 
The mean number of others dependents is different for the two class.
The home phone mean is different for the two class.
The spouse income mean is different for the two class according to
the p-value of equality of variances.
the applicant income mean is equal for the two types of credit history.
the value of home mean is equal for the two types of credit history.
the mortgage balance outstanding mean is equal for the two types of credit history.
the outgoinging on mortgage or rent mean is equal for the two types of credit history.
The outgoing on loans means is different for the two types of credit history.
The outgoing on hire purchase means is different for the two types of credit history.
The outgoing on credit cards mean is different for the two types of credit history. 
Individuals with good credit records and those with bad credit records 
have not on average the same age.*/

/* Test of the normality assumption 
h0 : the distribution is normal versus
h1 : the distribution is not normal*/

proc univariate data=score.loan_data1 normal;
class bad;
title 'Kolmogorov-Smirnov Test of Normality Assumption';
run;
/* There is evidence that types of credit history is non-normal
for both groups for each variables in our dataset.
However, since the samples of both groups are relatively large, > 30, 
the central limit theorem applies. 
The previous t-test is therefore appropriate for testing the difference in means */


/* Means differences in GLM procedures */
proc format;
value $fres
 'O' = "Owner"
 'F' = "tenant furnished"
 'U' = "Tenant Unfurnished"
 'P' = "With parents"
 'N' = "Other";
run;
 
proc format;
value $faes
"V" = 'Government'
"W" = 'housewife'
"M" = 'military' 
"P" = 'private sector'
"B" = 'public sector'
"R" = 'retired'
"E" = 'self employed'
"T" = 'student'
"U" = 'unemployed'
"N" = 'others';
run;
 

proc means data=score.loan_data1 maxdec=3;
	format res $fres.;
	var doutl;
	class res;
	title 'Descriptive statistics for outgoings on loans by residential statuts';
run;

proc sgplot data=score.loan_data1;
	vbox doutl / category=res;
	format res $fres.;
	title 'Box and whisker plots for outgoings on loans by residential statuts';
run;

/*outlier doutl > 25000*/

proc glm data=score.loan_data1;
	format res $fres.;
	class res;
	model doutl = res;
	title 'One way ANOVA for testing differences in outgoings on loans across residential statuts';
run;

/*There are no differences between the 
differents types of residential status*/

/* if p-value is < 0.05, h0 is rejecting 

h0 :  u1 = u2 = .... = un
h1 : u1 # u2 # ...... # un */

proc means data=score.loan_data1 maxdec=3;
	format aes $faes.;
	var doutl;
	class aes;
	title 'Descriptive statistics for outgoings on loans by applicants employments statuts';
run;

proc sgplot data=score.loan_data1;
	vbox doutl / category=aes;
	format aes $faes.;
	title 'Box and whisker plots for outgoings on loans by applicants employments statuts';
run;

/*outlier doutl > 25000*/

proc glm data=score.loan_data1;
	format aes $faes.;
	class aes;
	model doutl = aes;
	title 'One way ANOVA for testing differences in outgoings on loans across applicants employments statuts';
run;

/* There is a difference between applicants employments statuts */

/* Remove outlier */
proc sql;
	create table loan_data2 as
	select * from score.loan_data1
	where doutl < 25000;
quit;

/* Praparation of inputs for modelling */

/* Categorical input : aes, res

Greenacre method :
Collapse categorical variable that have
the same proportions of levels in the target variable BAD*/

proc freq data=loan_data2;
tables bad*res/chisq;
/*pearson Chi-square statistics*/
output out=chi (keep=_pchi_) chisq;
run;

proc print data=chi;
title 'Chi-square for credit history by residential statuts';
run;

/*H0 : independance, absence de lien statistique
  H1 : Liaison entre les deux variables
  Si p_value <= 0.05, on rejette H0 */
 
/* Il existe un lien statistique entre le statut residentiel et
l'evenement de defaut sur un credit 
V de Cramer = 0.11, liaison faible*/

proc means data=loan_data2 noprint nway maxdec=3;
class res;
var bad;
format res $fres.;
output out=prop_resBad mean=prop1;
run;

proc print data=prop_resBad;
title 'Proportion of customer with credit default by residential statuts';
run;


/* By applicants employements statuts : */

proc freq data=loan_data2;
tables bad*aes/chisq;
/*pearson Chi-square statistics*/
output out=chi2 (keep=_pchi_) chisq;
run;

proc print data=chi2;
title 'Chi-square for credit history by applicants employements statuts';
run;

/* Il existe un lien statistique entre la categorie professionnelle et
l'evenement de defaut sur un credit 
V de Cramer = 0.18, liaison faible*/

proc means data=loan_data2 noprint nway maxdec=3;
class aes;
var bad;
format aes $faes.;
output out=prop_resBad2 mean=prop2;
run;

proc print data=prop_resBad2;
title 'Proportion of customer with credit default by applicants employments statuts';
run;

/*----------------------
		CLUSTER
-----------------------*/
proc cluster data=prop_resBad method=ward outtree=treeinfo1
plots=(dendrogram(vertical height=rsq));
freq _freq_;
var prop;
id res;
format res $fres.;
ods output clusterhistory=cluster1;
title 'Results of Cluster Analysis on all credit history residential statuts';
run;

/* Select the best number of cluster using the p-value of chi-square*/
data cutoff;
if _n_ = 1 then set chi;
set cluster1;
chisquare=_pchi_*rsquared;
degfree=numberofclusters-1;
logvalue=logsdf('CHISQ',chisquare,degfree);
run;

proc print data=cutoff;
var numberofclusters Semipartialrsq rsqaured chisquare degfree logpvalue;
title 'Log P-value information and the cluster history';
run;

proc sgplot data=cutoff;
scatter y=logpvalue x=numberofclusters / markerattrs=(color=blue symbol=circlefilled);
xaxis label="Number of Clusters";
yaxis label="Log of P-value" min=-15 max=-5;
title "Plot of Log P-value by number of Clusters";
run;

/*Select the minimum number of clusters wich results in the minimum
reduction of the original chi-square statistic*/

proc sql;
select numberofclusters into :ncl
from cutoff having lopvalue=min(logpvalue);
quit;
run;

/*Create a temporary dataset to indicate the min cluster number*/
proc tree data=treeinfo1 nclusters=&ncl out=clus_solution1;
id res;
title 'Output from proc tree';
run;

proc sort data=clus_solution1;
by clusname;
run;

proc print data=clus_solution1;
by clusname;
id clusname;
title 'List of residential statuts by cluster';
run;

/*Create a new var with res clusters.
An inspection of the target variable by the newly collapsed levels is warranted*/


