CREATE DATABASE assgn;
USE assgn;
select NULL into @id_logged;
select NULL into @pwd_logged;
select 1 into @count_global;
SET autocommit = 0;

/*
The tables below are decalred in accordance with the relational database diagram submitted
*/
Create Table Person(
name varchar(50) NOT NULL,
id BIGINT Primary Key CHECK(id>=1000000000 and id<10000000000),
password varchar(50) NOT NULL,
department enum('CS','EEE','ECE','Mech','Chemical','ENI','Civil') NOT NULL,
address varchar(50) NOT NULL,
age integer NOT NULL,
question varchar(50) NOT NULL,
answer_recovery varchar(50) NOT NULL);

Create table Phone(
id BIGINT references Person(id) ,
phone_no bigint CHECK(phone_no>=1000000000 AND phone_no<10000000000),
Primary key(id,phone_no));

create table Teacher(
id BIGINT references Person(id),
joinDate DATE NOT NULL);

Create table Student(
id bigint references Person(id),
admissionYear year NOT NULL,
yearOfStudy integer NOT NULL CHECK(yearOfStudy>0 and yearOfStudy<6));  

Create table Course(
courseId bigint Primary Key CHECK(courseId>=1000000000 AND courseId<10000000000),
courseName Varchar(20) NOT NULL,
credits integer NOT NULL check(credits>0 and credits<6),
department enum('CS','EEE','ECE','Mech','Chemical','ENI','Civil') NOT NULL);

Create table Enrolls(
studentId bigint references Student(id),
courseId bigint references Course(courseId),
primary key(studentid, courseid));

Create table Takes(
teacherId bigint references Teacher(id),
courseId bigint references Course(courseId),
primary key(teacherId, courseid));

Create table Assignment(
assignmentId bigint Primary Key CHECK(assignmentId>=1000000000 AND assignmentId<10000000000),
assignmentName Varchar(50) NOT NULL,
description varchar(100)  NOT NULL,
Deadline DATETIME NOT NULL);

Create table Submission(
assignmentId bigint NOT NULL references Assignment(assignmentId),
submissionId bigint primary key CHECK(submissionId>=1000000000 AND submissionId<10000000000),
dateOfSubmission datetime NOT NULL ,
answer Varchar(50) NOT NULL ,
grade enum('A','A-','B','B-','C','C-','D','E','NC'),
feedback varchar(50)
);


Create table HasAssignment(
assignmentId bigint references Assignement(assignmentId),
courseId bigint references Course(courseId),
Primary key(assignmentId, courseId));

Create table Assigns(
assignmentId bigint references Assignement(assignmentId),
teacherId bigint references Teacher(id),
Primary key(assignmentId, teacherId));

Create table Submits(
submissionId bigint references Submission(submissionId),
studentId bigint references Student(id),
assignmentId bigint NOT NULL,
Primary key(submissionId, assignmentId,studentId));

/*this procedure below is used to generate unique id for identification where it needs to be generated
like in identification of assignment, submission through its IDs. while teacher and student IDs are assumed to be 
not generated and given through institution.*/
DELIMITER $$
CREATE PROCEDURE get_id(OUT id BIGINT)
DETERMINISTIC
SQL SECURITY INVOKER
COMMENT 'ID number generator'
BEGIN
select @count_global + 1 into @count_global;
select @count_global+1000000000 into id;
END$$
DELIMITER ;


/*allows student to get registered through their details:-
name, id, password, department, adress, age, security question, recovery answer, admission year and year of study*/

/*Furthermore you can see I used transactions in this and some of the procedures below,
basically what it does is that it executes the multiple sql statements one by one, and if 
an error occurs in middle of executing it, then it rollbacks the entire transaction, not reflecting the intermediate sql operations,
otherwise if everything goes well it commits.*/
DELIMITER $$
CREATE PROCEDURE registerStudent(IN nam varchar(50), IN id_tmp BIGINT,IN pwd varchar(50),in dept Varchar(50), in adrs varchar(50),in ag integer,in qstn varchar(50), in answr varchar(50),in admn_yr year, in YOS int)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'registering for students with their id and password'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
/*checks if id is not registered already then proceeds to insert*/
IF (id_tmp) not in (select id from person) THEN

		start transaction;
		insert into person(id, name, password, department, address, age, question, answer_recovery) values(id_tmp, nam, pwd, dept, adrs, ag, qstn, answr);
		insert into student(id, admissionYear , yearOfStudy) values(id_tmp, admn_yr, YOS);
        select 'id registered successfully' as success;
        commit;
else
	select 'id already registered' as success;
end if;
END$$
DELIMITER ;

/*allows student to get registered through their details:-
name, id, password, department, adress, age, security question, recovery answer, join date*/
DELIMITER $$
CREATE PROCEDURE registerTeacher(IN nam varchar(50), IN id_tmp BIGINT,IN pwd varchar(50),in dept Varchar(50), in adrs varchar(50),in ag integer, in qstn varchar(50), in answr varchar(50),in jn_date date)
NOT DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'registering for teacher with their id and password'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*checks if id is not registered already then proceeds to insert*/
IF (id_tmp) not in (select id from person) THEN
		insert into person(id, name, password, department, address, age, question, answer_recovery) values(id_tmp, nam, pwd, dept, adrs, ag, qstn, answr);
		insert into teacher(id, joinDate) values(id_tmp, jn_date);
        select 'id registered successfully' as success;
else
	select 'id already registered' as success;
end if;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE setpassword(in uname bigint,in newpass varchar(50), in oldpass varchar(50))
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'changing password using old and new password'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*checks if usernam and old password matches then it changes the password to newpass*/
IF exists (select * from person where id=uname and password=oldpass) then
update person set password = newpass where id=uname;
select 'password changed successfully' as success;

else
select 'password not changed' as success;
end if;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE forgotpassword(in uname bigint,in newpass varchar(50), in answr varchar(50))
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'changes password with recovery question\'s answer and changes if it matches with username'
BEGIN
IF exists (select * from person where id=uname and answer_recovery=answr) then
update person set password = newpass where id=uname;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE login(IN tmp_id bigint, In pwd varchar(50))
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'logging students and teachers'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*checks for loginid and matching password. then if true, populates @id_logged and @password_logged variables with the 
logged in id and password for future authentication.*/
select count(*) into @count from person where id = tmp_id and password=pwd;
IF @count = 1 THEN
	select tmp_id into @id_logged;
    select pwd into @pwd_logged;
    select 'logged in successfully' as success;
else
	select 'password or username is wrong' as success;
end if;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE logout()
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'logging out'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*when called, makes the @id_logged and @pwd_logged as NULL*/
select NULL into @id_logged;
select NULL into @pwd_logged;
select 'logged out successfully' as success;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE add_phone(in p_no bigint)
DETERMINISTIC
READS SQL DATA
modifies sql data
SQL SECURITY INVOKER
comment 'adds phone number data'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*checks if the user has already provided the phone number and then inserts it if they haven't*/
select count(*) into @tmp_count from phone where phone_no=p_no and @id_logged = id;
if @tmp_count = 0 and exists (select id from person where id=@id_logged and password=@pwd_logged) then
	insert into phone(id, phone_no) values (@id_logged, p_no);
end if ;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE delete_phone(in p_no bigint)
DETERMINISTIC
READS SQL DATA
modifies sql data
SQL SECURITY INVOKER
comment 'delete phone number data'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*deletes the phone number if it is present under their id*/
select count(*) into @tmp_count from phone where phone_no=p_no and @id_logged = id;
if @tmp_count = 1 and @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) then
	delete from phone where id=@id_logged and phone_no=p_no;
end if ;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE update_name(in tmp_name varchar(50))
DETERMINISTIC
READS SQL DATA
modifies sql data
SQL SECURITY INVOKER
comment 'updates name in records'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
start transaction;
/*check if username and password matches from the logged in variables anf then changes name accordingly*/
if @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) then
	update person set name=tmp_name where id=@id_logged;
end if ;
commit;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE AddAssigns(IN aid BIGINT, IN tid bigint)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher add other teachers assign their assignment making them also the co-teacher for that assignment'
BEGIN
/*lets the teacher assign any other teacher to view and grade the assignments,
it first checks if the user logged in is a teacher and then checks if the assignment has been assigned by the current teacher,
if it satisfies it adds in the new teacher for the assignment.*/
IF ((@id_logged)  in (select id from Teacher) and ((aid) in (select distinct assignmentId from assigns where teacherid=@id_logged)) ) THEN
		insert into Assigns values(aid , tid);
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE ViewAssignment()
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher view the assignment that they assigned'
begin
/*checks for the id and passwotd matching from the logged in variables, then
views the assignments assigned by the teacher from the table assignment natural join assigns which has each row with teacher id and assignment id*/
IF @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) THEN
	select assignmentId, assignmentName, description, Deadline from assignment natural join assigns where @id_logged=teacherId order by deadline desc;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE AddAssignment(IN assignmentName varchar(50), IN description varchar(100), IN Deadline DATETIME, IN cid BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher add an assignment'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
/*checks for the logged in variables in teacher table and checks if it matches and checks wether the teacher takes in the course,
if yes, then generates the unique identifier id via get_id and creates the new assignment table by populating assignment, assigns and hasassignment tables */
IF @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (select id from teacher) and cid in (select courseid from takes where teacherid = @id_logged) THEN

		start transaction;
        call get_id(@uid);
		insert into Assignment values(@uid ,assignmentName, description, Deadline);
		insert into Assigns values(@uid ,@id_logged);
        insert into HasAssignment values(@uid, cid);
		commit;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE deleteAssignment(IN assgn_id bigint)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher delete an assignment and all its submission'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
/*checks for the logged in variables from teacher table and check if they are matching and checks whether the teaacher has assigned the assignment,
then goes on to delete the assignment through asssignment id form assignment, assigns and hasassgnment tables*/
IF @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and exists(select assignmentId from assigns where teacherid=@id_logged and assignmentId=assgn_id) THEN
		start transaction;
		delete from assignment where assignmentId in (select assignmentId from assigns where teacherid=@id_logged and assignmentId=assgn_id);
        delete from assigns where assignmentId=assgn_id;
		delete from submits where assignmentId=assgn_id;
        delete from submission where assignmentId=assgn_id;
        delete from hasassignment where assignmentId=assgn_id;
		commit;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE Enroll(IN c_id BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the student enroll in a specific course'
BEGIN
/*populates the enrolls tables with student id and course id after validating it*/
IF ((@id_logged)  in (select id from Student) and (c_id) in (select courseId from Course)) and  @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) THEN
		insert into Enrolls values(@id_logged ,c_id);
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE TeacherTakes(IN courseId BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher take a particular course’'
BEGIN
/*Checks if the logged variables are matching and are in teacher table, and the courseid is in course table
and then inserts the values into takes table matching the teacher and the course they take.*/ 
IF (((@id_logged)  in (select id from Teacher)) and ((courseId) in (select courseId from Course))) and @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) THEN

		insert into Takes values(@id_logged ,courseId);
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE addcollab(IN sub_id BIGINT, IN sid BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the student add in other student collaborators on the assignment'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
/*validates the logged in variables from student table and then checks if the assignment belongs to the student and then checks if the other student has not
submitted any assignment, then adds in the other student in the assigns table with same assignment id making him the co-owner*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student) and sid in (select id from student) and
 (exists (select * from assignment where assignmentid in (select assignmentid from (submission natural join submits) where submissionid=sub_id and studentid = @id_logged) and deadline>=now()))
 and not exists(select * from assignment where assignmentid in (select assignmentid from (submission natural join submits) where studentid = sid))) THEN

		start transaction;
        select assignmentid into @tmp_aid from (submission natural join submits) where submissionid=sub_id and studentid = @id_logged;
        Insert into Submits values(sub_id, sid, @tmp_aid);
		commit;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE MakeSubmission(IN asgn_id BIGINT, IN answer varchar(50))
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the student make a submission'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
/*validates the student logged in id from student table and then inserts the assignment into assignment tables with unique id generated from get_tmp.*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student) and 
asgn_id in (select assignmentId from (hasassignment) where courseId in (select courseid from enrolls where studentid=@id_logged)) and (exists (select * from assignment where assignmentid=asgn_id and deadline>=now())))THEN
		start transaction;
        call get_id(@tmp);
        select @tmp into @tmp_delete_sid;
        select asgn_id into @tmp_delete_aid;
        Insert into Submits values(@tmp, @id_logged, asgn_id);
        insert into Submission values(asgn_id,@tmp ,now(), answer, NULL,NULL);
		commit;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE viewongoing()
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the student view ongoing assignments or assignment with future deadline'
BEGIN
/*returns the particular assignments where deadline is greater than now() after validating student or teacher. Also it returns only the assignment
where the student or teacher has been referenced in submits or assigns table respectively*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join enrolls where studentId = @id_logged and deadline>=now();
end if;

IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join assigns where teacherId = @id_logged and deadline>=now();
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE viewfinished()
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the student or teacher view finished assignments or assignments past deadline'
BEGIN
/*returns the particular assignments where deadline is lesser than now() after validating student or teacher. Also it returns only the assignment
where the student or teacher has been referenced in submits or assigns table respectively*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join enrolls where studentId = @id_logged and deadline<=now();
end if;

IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join assigns where teacherId = @id_logged and deadline<=now();
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE assgn_searchbyid(in tmp_id bigint)
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the student or search assignment by id'
BEGIN
/*returns the assignment wehere the id matches with tmp_id after validating the logged in varaibles as student or teacher. It returns
the assignments which are assigned to or by a student or teacher respectively. otherwise it doesnt return*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join enrolls where studentId = @id_logged and assignmentid=tmp_id;
end if;

IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join assigns where teacherId = @id_logged and assignmentid=tmp_id;
end if;

END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE assgn_searchbyname(in tmp_name varchar(50))
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the student or search assignment by name'
BEGIN
/*returns the assignment details of the assignment where the tmp_name matches with assignmentname and has been assigned to the student or assigneed by the teacher*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join enrolls where studentId = @id_logged and assignmentname=tmp_name;
end if;

IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join assigns where teacherId = @id_logged and assignmentname=tmp_name;
end if;

END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE assgn_searchbydeadline(in tmp_date datetime)
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the student or search assignment by deadline'
BEGIN
/*returns the assignment details of the assignment where the tmp_date matches with deadline and has been assigned to the student or assigneed by the teacher*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join enrolls where studentId = @id_logged and deadline=tmp_date;
end if;

IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher))THEN
		select assignmentName, description, deadline,courseid,coursename,department from assignment natural join hasassignment natural join course natural join assigns where teacherId = @id_logged and deadline=tmp_date;
end if;

END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE viewsubmission()
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the student or teacher view their submission or submissions of their assignment respectively'
BEGIN
/*validates the logged in variables and then returns the assignments relevant to them by matching the studentid or teacherid*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student))THEN
		select * from submission natural join submits where studentId = @id_logged;
end if;

IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher))THEN
		select * from submission natural join assigns where teacherId = @id_logged;
end if;

END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE assgn_searchby_submitted_percent(in start_perc float, in end_perc float)
NOT DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher search their assignments by the percentage of submitted students'
BEGIN
/*this procedure first validates the teacher logged in variables and checks if the end and start percentages are between 0 and 100.
then it queries for a table returning the number of submitted students divided by the total number assigned to, multiplied by 100 to give the submitted percentage
then returns the values between the start and end percentages only with their assignmentid and assignmentname.
Also this searches in only the assignments asssigned by the teacher.*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher) and (start_perc>=0 and start_perc<=100) and (end_perc>=0 and end_perc<=100 and start_perc<=end_perc))THEN
	select b_count/a_count*100 as percent, a_id, assignmentname, description,deadline from (select a_count, a_id, ifnull(b_count,0) as b_count , ifnull(b_id,0) as b_id,assignmentname, description, deadline from (select count(*) as a_count, assignmentid as a_id,assignmentname, description, deadline from assignment natural join hasassignment natural join enrolls group by assignmentid) a left join (select count(*) as b_count, assignmentid as b_id from submission group by assignmentid) b on a.a_id=b.b_id)c having percent<=end_perc and percent>=start_perc and a_id in (select assignmentid from assigns where teacherid=@id_logged);
end if;

END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE GetAssignmentCompletionRate(IN aid BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'returns the assignment completion rate for a particular assignment for a teacher'
BEGIN
/*this procedure first validates the teacher logged in variables and checks if the end and start percentages are between 0 and 100.
then it queries for a table returning the number of submitted students divided by the total number assigned to, multiplied by 100 to give the submitted percentage,
it returns even if the assignment is not assigned by a particular teacher*/
IF (@id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher) and (aid) in (select assignmentId from Assignment)) THEN
		select ifnull((select (count(*)/(select count(*) from enrolls natural join hasassignment natural join assignment where assignmentId=aid)*100) as completion_percentage from submission natural join submits where assignmentid=aid),0.0000) as completition_rate;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE GetAssignmentGradeStat(IN aid BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'returns the Grade statistics for a particular assignment for a teacher'
BEGIN
/*First validates the logged in credentials as teaacher,
gives null if no grade is given to anybody, otherwise returns the table with count grouped by grade.
it returns even if the assignment is not assigned by a particular teacher*/
IF (@id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher) and (aid) in (select assignmentId from Assignment)) THEN
		select grade, count(*) as count from submission natural join submits where assignmentid=aid group by grade;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE GiveFeedbackGrade(IN sId BIGINT,IN fb varchar(100), IN tmp_grade varchar(2))
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher give feedback and grade on a submission'
BEGIN
/*validates the logged in credentials and then inserts into the submission table in the grade and feedback attributes for their assignments only, which is also checked*/
IF (@id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher) and (sId) in (select submissionId from Submission where assignmentid in (select assignmentid from assigns where teacherid=@id_logged))) THEN
	update submission set grade=tmp_grade,feedback=fb where submissionid=sId;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE updatedeadline(IN tmp_deadline datetime,IN aId BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the teacher update deadline on an assignment'
BEGIN
IF (@id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from teacher) and (aid in (select assignmentid from assignment natural join assigns where teacherid=@id_logged))) THEN
		update assignment Set deadline = tmp_deadline where (assignmentId = aid);
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE deletesubmission(IN sub_id BIGINT)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the student delete a submission'
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	ROLLBACK;
END; 
/*validates the student logged in credentials and check if the matching submission id and student id record exists, then deltes the submission from submits and submission if 
deadline is greater than now()*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student) and 
 (exists (select * from assignment NATURAL join submission natural join submits where submissionid=sub_id and studentid=@id_logged  and deadline>=now())))THEN

		start transaction;
        delete from submits where submissionid=sub_id;
		delete from Submission where submissionid=sub_id;
		commit;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE updateanswer(IN answer_tmp varchar(50), in sub_id bigint)
DETERMINISTIC
READS SQL DATA
MODIFIES SQL DATA
SQL SECURITY INVOKER
comment 'lets the student update answer on their submission'
BEGIN
/*validates the student logged in credentials and check if the matching submission id and student id record exists, then update the answer 
atribute from submission if 
deadline is greater than now()*/
IF ( @id_logged in (select id from person where id=@id_logged and password=@pwd_logged) and @id_logged in (Select id from student) and 
 (exists (select * from assignment NATURAL join submission natural join submits where submissionid=sub_id and studentid=@id_logged  and deadline>=now())))THEN
		update submission set answer=answer_tmp where submissionid=sub_id;
end if;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE forgotpass_view(in tmp_id bigint)
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
comment 'lets to view seccurity question when password is forgotten'
BEGIN
/*cheks if the id exists and returns the respective security question attribute from the person tables*/
IF ( exists (select id from person where id=tmp_id))THEN
		select question from person where id=tmp_id;
end if;
END$$
DELIMITER ;

/*this trigger doesn't allow to submits if student is making multiple submissions for an assignment.
This trigger makes the insertion into submits table failed which can make the proced makesubmission to fail which has 
a transaction that does not commit if error occurs*/
DELIMITER $$
CREATE TRIGGER  Check_previous_submits after INSERT ON submits
FOR EACH ROW
BEGIN
select 0 into @tmp_del_count;
select count(*) into @tmp_del_count from (select assignmentid, count(*) from submits where studentid=@id_logged and assignmentid=@tmp_delete_aid group by assignmentid having count(*)>1)a;
if(@tmp_del_count>0) then
delete from submits where submissionid=@tmp_delete_sid;
end if;
END$$ 
DELIMITER ;


/*end of procedures, given below are examples to use the procedures*/


/*example with all the procedures*/
call registerteacher('Charizard',1234567890,'password','CS','BITS PILANI-5TH STREET',43,'WHAT IS YOUR FAVOURITE SHOW\'S NAME','POKEMON','2021-01-01');
call registerteacher('Blastoise',1234567891,'password','ECE','BITS PILANI-5TH STREET',43,'WHAT IS YOUR PET\'S NAME','PET','2021-01-01');
call registerteacher('Kangaskhan',1234567892,'password','CS','BITS PILANI-5TH STREET',43,'WHAT IS YOUR PET\'S NAME','PET','2021-01-01');
call registerteacher('Wartortle',1234567893,'password','Chemical','BITS PILANI-5TH STREET',43,'WHAT IS YOUR FAVOURITE MOVIE\'S NAME','TENET','2021-01-01');
call registerteacher('Pikachu',1234567894,'password','Mech','BITS PILANI-5TH STREET',43,'WHAT IS YOUR PET\'S FAVOURITE DESTINATION','PILANI','2021-01-01');

select * from teacher;

call registerstudent('Charmander',1234567880,'password','CS','BITS PILANI-5TH STREET',3,'WHAT IS YOUR PET\'S NAME','PET','2021',4);
call registerstudent('squirtle',1234567881,'password','ECE','BITS PILANI-5TH STREET',13,'WHAT IS YOUR PET\'S NAME','PET','2020',1);
call registerstudent('Abra',1234567872,'password','CS','BITS PILANI-5TH STREET',23,'WHAT IS YOUR PET\'S NAME','PET','2022',3);
call registerstudent('bulbasaur',1234537893,'password','Chemical','BITS PILANI-5TH STREET',7,'WHAT IS YOUR PET\'S NAME','PET','2020',2);
call registerstudent('Pichu',1234567811,'password','Mech','BITS PILANI-5TH STREET',2,'WHAT IS YOUR PET\'S NAME','PET','2021',5);

/* this function below resets the password using old and new password*/

/*insertion of some courses manually*/
select * from course;
insert into course values (1234567890,'DBMS',4,'CS');
insert into course values (1234167890,'DSA',4,'CS');
insert into course values (1234567891,'PMFM',3,'Mech');
insert into course values (1234567892,'Adv Chem process',5,'Chemical');
insert into course values (1234567812,'Bit Binary course',3,'ECE');

call setpassword(1234567880,'123#','password');

call forgotpass_view(1234567880);

call forgotpassword(1234567880,'newpass','PET');

select * from person where id=1234567880;

call login(1234567890,'password');
call TeacherTakes(1234567890);
call logout();
call login(1234567892,'password');
call TeacherTakes(1234567890);
call TeacherTakes(1234167890);
call logout();

select * from person;
call logout();

call login(1234567880,'newpass');


call TeacherTakes(1234567890);
/*the below statement is not a procedure but used to illustrate a concept for the example sake:
after logging into student, if we try to use teachertakes, the result will not reflect. use the function down and find out.*/
select * from takes;

call add_phone(8883140222);
call add_phone(9360374936);
/*this statement below does not get the phone number added as the check constraint for the phon numbers to be 10 digit number is violated and will not be reflected*/
call add_phone(883140222);
select * from phone;

call delete_phone(8883140222);
select * from phone;


call update_name('Charmeleon');
select * from person where id=@id_logged;

call logout();
call login(1234567893,'password');
call add_phone(8734561230);
call add_phone(8734561211);
call add_phone(6734521211);

call logout();
call login(1234567891,'password');
call add_phone(8734561230);
call add_phone(7360345678);
call add_phone(8734561239);
call add_phone(7360324678);
call add_phone(6634561230);
call add_phone(9960345678);
select * from phone where id=@id_logged and phone_no=9960345678;
call delete_phone(9960345678);
select * from phone where id=@id_logged and phone_no=9960345678;

call logout();
call login(1234567880,'newpass');
call enroll(1234567890);
call logout();

call login(1234567872,'password');
call enroll(1234567890);
call enroll(1234167890);
call logout();

call login(1234537893,'password');
call enroll(1234567890);
call enroll(1234567812);
call logout();

/*the below sql statements does not enroll because the id used is of a teacher*/
call login(1234567891,'password');
call enroll(1234567890);
select * from enrolls;

call login(1234567811,'password');
call Enroll(1234567890);
call enroll(1234567892);
call logout();

call login(1234567881,'password');
call Enroll(1234567890);
call enroll(1234567812);
call enroll(1234167890);
select * from enrolls where studentid=@id_logged;

call logout();

select * from person;

call login(1234567893,'password');
call TeacherTakes(1234567812);
call TeacherTakes(1234567890);
call TeacherTakes(1234567892);
call logout();

call login(1234567894,'password');
call TeacherTakes(1234567891);
call TeacherTakes(1234567892);
call TeacherTakes(1234167890);
call TeacherTakes(1234567812);
select * from takes where teacherid=1234567894;

call logout();

select * from takes natural join course;

call login(1234567890,'password');
call AddAssignment('Sql app','Do an sql app','2023-09-05 09:00',1234567890);
call AddAssignment('Sql app-2','Do an sql app','2023-09-05 09:00',1234567890);
call AddAssignment('Sql app-3','Do an sql app','2023-09-05 09:00',1234567890);
call AddAssignment('Sql app-4','Do an sql app','2023-09-05 09:00',1234567890);
call AddAssignment('Backend app','Do an backend app','2023-09-05 19:00',1234567890);
call AddAssignment('Backend app-2','Do an backend app-2','2023-09-05 19:00',1234567890);
/* this below will not be addded as the teacher doesn't take the course*/
call AddAssignment('Circuitry','Do an circuits','2023-09-05 19:00',1234567812);
call ViewAssignment();

call viewfinished();
call viewongoing();

call AddAssigns(1000000002,1234567892);
call AddAssigns(1000000002,1234567894);
select * from assigns where assignmentid=1000000002;
call logout();

call login(1234567893,'password');
call AddAssignment('Create the ultimate app','It is a challenge','2023-09-01 19:00',1234567890);
call AddAssignment('Create the ultimate app-2','It is a challenge','2023-09-01 19:00',1234567890);
call AddAssignment('Create the ultimate app-3','It is a challenge','2023-09-01 19:00',1234567890);
call AddAssignment('Create the ultimate app-4','It is a challenge','2023-09-01 19:00',1234567890);
call AddAssignment('Some assignment','some desc','2023-09-01 23:59',1234567892);
call ViewAssignment();

call deleteassignment(1000000011);
call ViewAssignment();


call AddAssigns(1234567894,1000000002);
call GetAssignmentCompletionRate(1000000012);
call logout();

select * from assignment;
call login(1234567811,'password');
call MakeSubmission(1000000002,'answer.pdf');
call MakeSubmission(1000000002,'ans.pdf');
call MakeSubmission(1000000008,'ans.pdf');
/*doesnt refelect multiple submission for same assignment, ignores the latest submission by default*/
call viewsubmission();
call deletesubmission(1000000024);
call viewsubmission();
call deletesubmission(1000000013);
call viewsubmission();
call MakeSubmission(1000000002,'ans.pdf');
call viewsubmission();

select * from course natural join student;
select * from submits;
call logout();

call login(1234567890,'password');
call GetAssignmentCompletionRate(1000000002);
call viewsubmission();
call GiveFeedbackGrade(1000000015,NULL,'A');
select * from submission where submissionid=1000000015;
call assgn_searchby_submitted_percent(10,60);
call viewsubmission();
call viewongoing();
/* adding manually into assignment table*/
insert into assignment values(9000000012, 'Past assignment', 'No one can submit', '2022-12-12 09:00:00');
insert into assigns values(9000000012,1234567890);
insert into hasassignment values (9000000012,1234567890); 

call viewfinished();
call logout();

call login(1234567872, 'password');
call viewfinished();
call viewongoing();
select * from assignment;
call MakeSubmission(1000000002,'answer.pdf');
call MakeSubmission(1000000003,'answer.pdf');
call MakeSubmission(1000000004,'answer.pdf');
call MakeSubmission(1000000005,'answer.pdf');
call MakeSubmission(1000000006,'this_deserves_b.pdf');
call MakeSubmission(1000000007,'answer.pdf');
call MakeSubmission(1000000008,'answer.pdf');
call MakeSubmission(1000000009,'answer.pdf');
call addcollab(1000000016,1234567880);
select * from submits where submissionid=1000000016;

call assgn_searchbyid(1000000002);
call assgn_searchbyname('Backend app');
call assgn_searchbydeadline('2023-09-05 19:00:00');
call updateanswer('App.sql',1000000016);
call deletesubmission(1000000018);
call viewsubmission();

call logout();

call login(1234567894,'password');
call viewsubmission();
call givefeedbackgrade(1000000016,'Subpar','B');
call viewsubmission();
call GetAssignmentGradeStat(1000000002);
call GetAssignmentCompletionRate(1000000002);
call updatedeadline('2023-09-11 00:00:00',1000000002);
select * from assignment where deadline='2023-09-11 00:00:00';
call logout();