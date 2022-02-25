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
var prop1;
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
logpvalue=logsdf('CHISQ',chisquare,degfree);
run;

proc print data=cutoff;
var numberofclusters Semipartialrsq rsquared chisquare degfree logpvalue;
title 'Log P-value information and the cluster history';
run;

proc sgplot data=cutoff;
scatter y=logpvalue x=numberofclusters / markerattrs=(color=blue symbol=circlefilled);
xaxis label="Number of Clusters";
yaxis label="Log of P-value" min=-10 max=-5;
title "Plot of Log P-value by number of Clusters";
run;

/*Select the minimum number of clusters wich results in the minimum
reduction of the original chi-square statistic*/

proc sql;
select numberofclusters into :ncl
from cutoff having logpvalue=min(logpvalue);
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
data loan_data3;
	set loan_data2;
	if res in ('O','F','U','P') then res_clus=1;
	else if res in ('N') then res_clus=0;
run;

proc freq data=loan_data3;
tables bad*res_clus/chisq;
output out=chi (keep=_pchi_) chisq;
run;
/*Cramer V = -0.1083 */

/* CLuster for applicants employments statuts */
proc cluster data=prop_resBad2 method=ward outtree=treeinfo2
plots=(dendrogram(vertical height=rsq));
freq _freq_;
var prop2;
id aes;
format aes $faes.;
ods output clusterhistory=cluster1;
title 'Results of Cluster Analysis on all credit history applicants employments statuts';
run;

data loan_data4;
	set loan_data3;
	if aes in ('B','M','E','T','P','V') then aes_clus = 1;
	else if aes in ('N','W','R','U') then aes_clus= 0;
run;

/*CHI test for aes_clus */
proc freq data=loan_data4;
tables bad*aes_clus/chisq;
output out=chi (keep=_pchi_) chisq;
run;
/* Il y a toujours une liaison entre les deux variables
Seulement, le V de Cramer devient negatif  -0.1827 */

/*------------------------------------------------- 
Detect associationi within variables by proc corr
-------------------------------------------------*/

%let features = age nkid dep phon sinc aes_clus res_clus 
dainc dhval dmort doutm douthp doutl doutcc;

ods output spearmancorr=spearman hoeffdingcorr=hoeffding;

proc corr data=loan_data4 spearman hoeffding rank;
var &features;
with bad;
title 'Coefficients de correlation de Spearman et Hoeffding';
run;

proc print data=spearman; title 'ODS output de Spearman'; run;
proc print data=hoeffding; title 'ODS output de hoeffding'; run;

/*Convert Spearman and Hoeffding data to one dataset*/
data spearmanrank (keep=variable scorr spvalue ranksp);
length variable $25;
set spearman;
array best(*) best1 -- best14;
array r(*) r1 -- r14; 
array p(*) p1 -- p14;

do i = 1 to 14;
variable=best(i); scorr=r(i); spvalue=p(i); ranksp=i;
output;
end;
run;

data hoeffdingrank (keep=variable hcorr hpvalue rankhoeff);
length variable $25;
set hoeffding;
array best(*) best1 -- best14;
array r(*) r1 -- r14; 
array p(*) p1 -- p14;

do i = 1 to 14;
variable=best(i); hcorr=r(i); hpvalue=p(i); rankhoeff=i;
output;
end;
run;

/* Sort and merge by variable */
proc sort data=spearmanrank; by variable; run;
proc sort data=hoeffdingrank; by variable; run;

data final;
merge spearmanrank hoeffdingrank;
by variable;
run;

proc sort data=final;
by ranksp;
run;

proc print data=final;
var variable ranksp rankhoeff scorr spvalue hcorr hpvalue;
title 'Spearman and Hoeffding D Correlation data sorted by Spearman rank';
run;

/* Si une variable a un coefficient de correlation (Spearman et Hoeffding)
eleve, donc cette variable est fortement relie a la variable cible et sera
retenu dans la modelisation, et vice-versa 

Critere de selection : p-value < 0.05 

Spearman : dainc aes_clus res_clus doutcc  doutm age  sinc*               
Hoeffdinf : dainc */

/* Plot des rangs de Spearman et Hoeffding pour determiner les variables a
conserver. Si une variable se trouve sur la region en haut a droite ou a ses bordures
elle doit etre elimine a cause de sa non relation a la variable cible.

Si une variable a un rang de Hoeffding faible et un rang de Spearman eleve,
cette variable a une relation non lineaire avec la variable cible.  */

proc sgplot data=final;
refline 8 / axis=y;
refline 2 / axis=x;
scatter y=ranksp x=rankhoeff / datalabel=variable;
yaxis label = "Rank of Spearman Correlation";
xaxis label = "Rank of Hoeffding Correlation";
title 'Ranks of Spearman Correlations by Ranks of Hoeffding Correlations';
run;

/*Variables a conserver : dainc age
Relations non lineaires : doutm aes_clus res_clus doutl doutcc*/

data score.loan_data_model;
set loan_data4;
drop yob sinc nkid douthp dhval dmort phon dep;
run;

/* Detect non-linear association */
%macro non_linear(score_var= );
	proc rank data=score.loan_data_model groups=100 out=outrank; /*Groups=100 pour avoir des percentile*/
	var &score_var;
	ranks bin;
	run;
	
	proc print data=outrank (obs=10);
	var &score_var bin;
	run;
	
	proc means data=outrank noprint nway n;
	class bin;
	var bad &score_var;
	output out=bins sum(bad)=bad mean(&score_var)= &score_var;
	run;
	
	proc sort data=bins;
	by bin;
	run;
	
	proc print data=bins;
	run;
	
	data bins;
	set bins;
	elogit= log((bad+sqrt(_freq_)/2))/(_freq_ - bad + (sqrt(_freq_)/2));
	run;
	
	/*Plot le elogit en fonction de doutm*/
	proc sgplot data=bins;
	reg y=elogit x=&score_var/degree=2;
	series y=elogit x=&score_var;
	title 'Empirical logit by variable';
	run;
%mend non_linear;

%non_linear(score_var = doutm)
%non_linear(score_var = doutl)
%non_linear(score_var = doutcc);

/* Exemple d'interpretation :
	
	Bin 43 : Parmi les 14 individus qui ont un montant d'hypotheque ou loyer
	en moyenne de 90 dollar, 3 seulement ont fait defaut sur un credit bancaire */
	
	
/*----------------------------------
  MODELING : Logistic regression
-----------------------------------*/

/* Stratified random sampling : Training and validation data sets */
data loan_model;
set score.loan_data_model;
run;

proc freq data=loan_model;
tables bad;
run;

/* 0: 74% ; 1:26% */

proc sort data=loan_model;
by bad;
run;

proc surveyselect data=loan_model
method=srs samprate=0.70 out=stratified_loan_data seed=12345 outall;
strata bad;
run;

/*Method equal srs forequal probability of being selected without replacement*/

/* TRAINING DATA*/
data score.training_data;
set stratified_loan_data;
if selected=1;
drop selected SamplingWeight SelectionProb;
run;

/*VALIDATION DATA*/
data score.validation_data;
set stratified_loan_data;
if selected=0;
drop selected SamplingWeight SelectionProb;
run;

/*Check if the srs is verified*/
proc freq data=score.training_data;
tables bad;
title '70 percent sample of loan training data';
run;

proc freq data=score.validation_data;
tables bad;
title '30 percent sample of loan validation data';
run;

/*Distribution of target variable is the same as in 
entire dataset*/

/* Logistic regression with backward selection */
proc logistic data=score.training_data;
class res_clus (param=ref ref=first);
class aes_clus (param=ref ref=first);
model bad (Event= '1')= dainc doutm doutl doutcc age aes_clus res_clus
/selection=backward slstay=0.1 details;
store score.model1;
run;
/*Pr > Chisq = 0.93, on ne peut pas rejetter H0, le modèle
est pertinent pour prédire la variable cible

AIC = 984.249
Predictors : dainc, age, doutcc and res_clus*/


/*Logistic regression with forward selection*/
proc logistic data=score.training_data;
class res_clus (param=ref ref=first);
class aes_clus (param=ref ref=first);
model bad (Event= '1')= dainc doutm doutl doutcc age aes_clus res_clus
/selection=forward slentry=0.1 details;
store score.model2;
run; 
/*Pr > Chisq = 0.93, on ne peut pas rejetter H0, le modèle
est pertinent pour prédire la variable cible

AIC = 984.249	
Predictors : doutm, doutl, aes_clus*/

/*Logistic regression with stepwise selection*/
proc logistic data=score.training_data;
class res_clus (param=ref ref=first);
class aes_clus (param=ref ref=first);
model bad (Event= '1')= dainc doutm doutl doutcc age aes_clus res_clus
/selection=stepwise slentry=0.1 slstay=0.1 details;
store score.model3;
run; 
/*Same result as the model 1 */


/*Predict on validation data*/
proc plm restore=score.model3;
score data=score.validation_data out=loan_predicted;
run;

data pred1;
	set loan_predicted;
	P_1 = exp(Predicted)/(1+exp(Predicted));
	P_0 = 1 - P_1;
run;

/*Measure the model performance: Classification table */

/* Hit rate : number of correctly classified

error rate = 1 - hit rate

sensitivity : proportion of positive cases correctly
predicted to be positive (actual positive event)

PV+ : proportion of predicted positive values 
that will be positive

Specificity : proportion of true negatives out of the
 total number of actual negative values

PV- : proportion of predicted negative values 
that will be negative
*/

proc format;
	value $target '0'='NO' '1'='YES';
run;

/*Cut-off value = 0.27*/
proc logistic data=score.training_data;
	class res_clus (param=ref ref=first);
	class aes_clus (param=ref ref=first);
	model bad (Event = '1') = dainc age doutcc res_clus
	/ctable pprob=.27;
	score data=score.validation_data out=pred_validation
	outroc=rocvalidation;
run;
/* AUC = 0.6074 */

/*Classification table*/
proc freq data=pred_validation;
	tables f_bad * i_bad/norow nocol;
	format f_bad i_bad $target.;
	title 'Classification table for loan validation data';
run;


/*Try different cut-off values to improve
specificity and sensitivity*/

/* ROC Curve */
proc logistic data=score.training_data;
	class res_clus (param=ref ref=first);
	class aes_clus (param=ref ref=first);
	model bad (Event = '1') = dainc age doutcc res_clus
	/ctable pprob= 0.0 to 1.0 by 0.10;
	score data= score.training_data outroc=roctrain;
	score data= score.validation_data outroc=rocvalidation;
run;

/* AUC training = 0.6749
AUC validation = 0.6074 */

/*Gains and Lift charts */

/* Gains : ability of the classifier to captures
the true responders. Plot of PV+ by depth across
all cutoff values. 

depth = proportion of
predicted positive observations out of the entire data set.
Depth = (TP+FP)/n */

data gains;
	set rocvalidation;
	cutoff=_prob_; pi1=0.26;
	tp_prop = pi1*_sensit_; fp_prop = (1-pi1)*_1mspec_;
	depth = tp_prop + fp_prop;
	pv_plus = tp_prop / depth;
	lift = pv_plus /pi1;
run;

proc print data=gains;
	var cutoff pi1 _sensit_ _1mspec_ tp_prop fp_prop depth pv_plus lift;
	title "Informations du gain pour les données de validation";
run;

proc sgplot data=gains;
series y = pv_plus x = depth;
refline pi1 /axis=y;
refline 0.15/axis=x; /*Target the top 15 percent*/
xaxis values=(0 to 1.0 by 0.10);
yaxis values=(0.5 to 1.0 by 0.10);
title "Gains pour les données de validation";
run;

/* Lift : ratio of the performance of the classifier
to the performance obtained by chance 
Lift = PV+ / pi1               */
proc sgplot data=gains;
series y = lift x = depth;
refline pi1 /axis=y;
refline 0.15/axis=x; /*Target the top 15 percent*/
/*xaxis values=(0 to 1.0 by 0.10);
yaxis values=(0.5 to 1.0 by 0.10)*/;
title "Lift pour les données de validation";
run;












