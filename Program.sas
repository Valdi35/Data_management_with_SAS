/*create a librairie*/
libname datap "/home/u60819583/";
run;

/* Write txt file*/
data datap.patient_data;
	infile "/home/u60819583/Patient_HD_age.txt";
	input 
	@1 pid $ 1.
	@2 sdate mmddyy10.
	@12 edate mmddyy10.
	@22 age 2.;
	format sdate edate date9.;
run;

/*Import an Excel file*/
proc import datafile="/home/u60819583/score_data.xlsx" out=scoreData dbms=xlsx 
		replace;
	getnames=yes;
run;

/*Create a permanent dataset from scoredata*/
libname score "/home/u60819583/";
run;

data score.scoreData0;
	set scoreData;
run;

/*Import an Excel file*/
/*-- Import score_data_miss777 */
proc import datafile="/home/u60819583/score_data_miss777.xlsx" out=miss_data0 
		dbms=xlsx replace;
	getnames=yes;
run;

/* Create a new dataset using the precedent */
data scoredata1;
	set miss_data0;
run;

/* Convert 777 in score to missing */
data scoredata1;
	set scoredata1;

	if score1=777 then
		do;
			score1=' ';
		end;
	else if score2=777 then
		do;
			score2=' ';
		end;
	else if score3=777 then
		do;
			score3=' ';
		end;
run;

/* Compute average */
data scoredata1;
	set scoredata1;
	average_score=mean(score1, score2, score3);
run;

/* Compute a new variable : Grade */
data scoredata1;
	set scoredata1;

	IF average_score >=90 THEN
		DO;
			grade='A';
			pass='pass';
		end;
	Else If average_score >=80 then
		do;
			grade='B';
			pass='pass';
		END;
	Else If average_score >=70 then
		do;
			grade='C';
			pass='pass';
		END;
	Else If average_score >=60 then
		do;
			grade='D';
			pass='pass';
		END;
	Else If 0=< average_score < 60 then
		do;
			grade='F';
			pass='fail';
		END;
	else
		do;
			grade=' ';
			pass=' ';
		END;
run;

/* Print */
proc print data=scoredata1;
run;

/* New dataset */
proc import datafile="/home/u60819583/Sale.xlsx" out=sale0 dbms=xlsx replace;
	getnames=yes;
run;

/* Labelled */
data sale1;
	set sale0;
	label emid='Employee id' sale_m1='Jan' sale_m2='Feb' sale m3='Mar';
	average_sale=mean(sale_m1, sale_m2, sale_m3);
	format average_sale sale_m1 --sale_m3 dollar10.2;
run;

/* Print */
proc print data=sale1 label;
run;

/* SAS function */
proc import datafile="/home/u60819583/Chara_data2.xlsx" out=charaData2 dbms=xlsx replace;
	getnames=yes;
run;

data charaData2;
	set CharaData2;
	DOB_year = scan(DOB,3);
	DOB_day = scan(DOB,2);
	DOB_month = substr(DOB,1,1);
run;

data CharaData2;
	set CharaData2;
	raw_score = Tranwrd(raw_score,'missing','');
run;

/* Date functions */
proc import datafile="/home/u60819583/Patient_HD.xlsx" out=patientDate dbms=xlsx replace;
	getnames=yes;
run;

data patientDate2;
	set patientDate;
	yearAdmin = year(Start_date);
	diff1 = intck('DAY',Start_date, End_date);
	diff2 = DATDIF(Start_date, End_date, 'ACT/ACT');
	todayDate = today();
	format todayDate date10.;
run;

/* ------------ */
/* Do Loops 
/* ------------ */

data salaryincrease1 (drop= counter);
	interest = 0.03;
	salary = 60000;
	do counter = 1 to 5;
		salary + salary * interest;
		year + 1;
		output;
	end;
	format salary dollar10.2;
run;

data salaryincrease2 (drop=counter);
	interest = 0.03;
	salary = 60000;
	do until(salary gt 100000);
		salary + salary * interest;
		year + 1;
		output;
	end;
	format salary dollar10.2;
run;

/* ---------
/* Array
/* --------- */
proc import datafile="/home/u60819583/allscore_miss_text.xlsx" out=score_miss
dbms=xlsx replace;
	getnames=yes;
run;

data score_miss1 (drop=i);
	set score_miss;
	array var{*} read math science write;
	array newvar{*} readN mathN scienceN writeN;
	do i = 1 to dim(var);
		if var{i} = 'missing' then var{i}=.;
		newvar{i} = input(var{i}, 8.);
	end;
run;

/* Combine SAS Data sets */
proc import datafile="/home/u60819583/score_data_id_class.xlsx" out=scoreStud
dbms=xlsx replace;
	getnames=yes;
run;

proc import datafile="/home/u60819583/class_info.xlsx" out=classInfo
dbms=xlsx replace;
	getnames=yes;
run;

data MMA;
merge scoreStud(in=A) classInfo(in=B);
by class;
if A;
run;

/* Correction */
proc sort data = scoreStud;
by class;
run;
proc sort data = classInfo;
by class;
run;
 
data m0;
merge scoreStud (in = inC) classInfo (in = inS);
by class;
if inC;
run;

/* Restructuring data sets */
proc import datafile="/home/u60819583/Weight_loss.xlsx" out=weightLoss
dbms=xlsx replace;
	getnames=yes;
run;

/* Change value 9999 to missing */
data weightLoss0 (drop=i);
	set weightLoss;
	array var{*} weight0 weight1 weight2;
	do i = 1 to dim(var);
		if var{i} = 9999 then var{i}=.;
	end;
run;

/*Transform data from one record per PID to multiple
record per PID using transpose */
proc sort data=weightLoss0 out=weightLoss0;
by pid;
run;

proc transpose data=weightLoss0
	out=weightLoss1 (rename = (col1 = all_weight _name_=weight_type)
								drop = _label_
								where = (all_weight ne .));
	by pid gender walk_steps;
	var weight0 - weight2;
run;

proc print data = weightLoss1;
title 'Weight loss: multiple records per patient id';
run;

/*SAS STATS procedures */
proc import datafile = "/home/u60819583/score_data_miss777" 
DBMS = xlsx out = scoredata0 replace ;
run;
data scoredata1 (drop=i);
set scoredata0;
   ARRAY sc (3) score1 score2 score3;    
   ARRAY new (3) ns1 ns2 ns3; 
   DO i = 1 TO 3;                       
      IF sc(i) = 777 THEN new(i) =.;   
      Else if sc(i) NE 777 then new(i) = sc(i);
   END;  
averagescore = mean (ns1, ns2, ns3);
run; 

proc sort data = scoredata1 out = scoredata1;
by gender averagescore;
run;

proc print data = scoredata1;
title "Sorted data";
run;

/* Generate frequency tables for all character variables excluding Name */
proc freq data = scoredata1;
table gender;
run;

proc means data = scoredata1;
by gender;
var ns1 ns2 ns3 averagescore;
run;

proc univariate data=scoredata1;
class gender;
var ns1 ns2 ns3 averagescore;
run;

/* Generate report using ODS Statements */
proc import datafile = "/home/u60819583/sale_by_state" 
DBMS = xlsx out = salebystate replace ;
run;

ods excel file="/home/u60819583/first_ods_report.xlsx"
	options(sheet_interval="bygroup"
			sheet_label="state ="
			embedded_titles="yes" );
TITLE 'Summary of sales by State';
ods noproctitle;

proc means data = salebystate MAXDEC = 1 n mean max min;
	by state;
	var sale1 - sale3;
	where state ne ' ';
run;

ods excel close;

/* Error Handling */

DATA sdm1 (drop=i);
   set scoredata0; 
   
   /* Correct the error */
   ARRAY sc (3) score1 score2 score3;    
   ARRAY new (3) ns1 ns2 ns3; 
   DO i = 1 TO 3;                       
      IF sc(i) = 777 THEN new(i) =.;   
      Else if sc(i) NE 777 then new(i) = sc(i);
   END;  
   
   AverageScore = mean (ns1, ns2, ns3);
   PUTLOG 'Error: ' Name = ns1 = ns2 = ns3 = AverageScore= 5.2;
   If averagescore <60; 
run;

/*SAS Macro Review */
proc import datafile = "/home/u60819583/allscore" 
DBMS = xlsx out = allscore0 replace ;
run;

/*Generate proc univariate outputs for all 4 score variables */

/* Replace score vars names using macro */
%let score1 = read;
%let score2 = math;
%let score3 = science;
%let score4 = write;

proc print data = allscore0;
var &score1;
run;

/*macro for univariate */
%macro score_univariate(score_var= );
	proc univariate data = allscore0;
	var &score_var;
	run;
%mend score_univariate;

%score_univariate(score_var= &score1)
%score_univariate(score_var= &score2)
%score_univariate(score_var= &score3)
%score_univariate(score_var= &score4);

/* PROC SQL */
proc import datafile = "/home/u60819583/score_data_id" 
DBMS = xlsx out = score_data0 replace ;
run;

proc sql;
	create table allscore1 as
	select stuid,
			math
	from allscore0;
quit;

proc sql;
	create table score_data1 as
	select stu_id,
			score2
	from score_data0;
quit;

/*Inner join*/
proc sql;
	create table matching_student as
	select stu_id, stuid, math, score2
	from score_data1 as g 
	inner join allscore1 as ng on stu_id = stuid;
quit;

/* RIGHT JOIN */
proc sql;
	create table matching_student as
	select stu_id, stuid, math, score2
	from score_data1 as g 
	right join allscore1 as ng on stu_id = stuid;
quit;

/* FULL JOIN */
proc sql;
	create table matching_student as
	select stu_id, stuid, math, score2
	from score_data1 as g 
	full join allscore1 as ng on stu_id = stuid;
quit;

/*----------------------------------------------------------------------
 Hands-on projects : Weight-loss data 

 Objective : Generating simple cross-tab in proc freq to exam possible
trend of weight loss(in lb) in response to daily walking steps 

-----------------------------------------------------------------------*/

/* Import data */
proc import datafile = "/home/u60819583/Weight_loss" 
DBMS = xlsx out = WL0 replace ;
run;

/* Proc means */
proc sort data = WL0;
by gender;
run;

proc means data = WL0 MAXDEC=1;
by gender;
var weight0 - weight2 walk_steps;
run;

/* Proc freq */
proc freq data = WL0;
table gender;
run;

/* Clean data : chang value '9999' to missing */
/* create weight difference variables */
data WL1 (drop=i);
set WL0;
   ARRAY sc (3) weight0 - weight2;     
   DO i = 1 TO 3;                       
      IF sc(i) = 9999 THEN sc(i) =.;   
   END;  
wd1 = weight0 - weight1;
wd2 = weight0 - weight2;
wd3 = weight1 - weight2;

run; 

/* Check weight difference variables */
proc sort data = WL1;
by gender;
run;

proc means data = WL1 MAXDEC=1;
by gender;
var wd2 walk_steps;
run;

proc freq data = WL1;
table gender;
run;

proc print data = WL1;
run;

/* Create group for walk_steps and wd2 in a new dataset*/
data WL2;
	set WL1;

	IF walk_steps >= 10000 THEN
		DO;
			ws_group='greater than 100000';
		end;
	Else If walk_steps >=5000 and walk_steps <=10000 then
		do;
			ws_group='5000-100000';
		END;
	else
		do;
			ws_group='less than 5000';
		END;
		
		IF wd2 >= 5 THEN
		DO;
			wd2_group='losing > 5 lb';
		end;
	Else If wd2 <= 5 then
		do;
			wd2_group='losing <= 5 lb';
		END;
	else
		do;
			wd2_group='not losing weight';
		END;
		
run;

/* Create permanent data set WL2 */
libname projectd "/home/u60819583/";
run;

data projectd.weight_loss;
	set WL2;
run;

/* Cross-tab for walk steps groups and weight loss groups*/
proc sort data = WL2;
by wd2_group;
run;

proc freq data = WL2;
table ws_group;
by wd2_group;
run;
