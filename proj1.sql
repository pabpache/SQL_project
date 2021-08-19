-- comp9311 19T3 Project 1
--
-- MyMyUNSW Solutions
-- Student name: Pablo Pacheco


-- Q1:
create or replace view Q1(unswid, longname)
as
SELECT DISTINCT rooms.unswid, rooms.longname
FROM rooms, facilities, room_facilities
WHERE facilities.description = 'Air-conditioned' AND facilities.id = room_facilities.facility AND room_facilities.room = rooms.id
;

-- Q2:
create or replace view Q2(unswid,name)
as
SELECT DISTINCT people.unswid, people.name		
FROM people, course_staff
WHERE course_staff.staff = people.id AND course_staff.course IN (
SELECT course_enrolments.course
FROM course_enrolments, people
WHERE course_enrolments.student = people.id AND people.name = 'Hemma Margareta')
;

-- Q3:
create or replace view Q3(unswid, name)
as 
SELECT DISTINCT people.unswid, people.name
FROM people, students
WHERE people.id = students.id AND students.stype = 'intl' AND students.id IN (
    SELECT students.id
    FROM students, course_enrolments C1, course_enrolments C2, courses D1, courses D2, subjects S1, subjects S2
    WHERE C1.student = students.id AND C2.student = students.id AND C1.grade = 'HD' AND C2.grade = 'HD'
            AND C1.course = D1.id AND C2.course = D2.id AND D1.semester = D2.semester AND D1.subject = S1.id
            AND D2.subject = S2.id AND S1.code = 'COMP9311' AND S2.code = 'COMP9024'
) 
;

-- Q4:
 -- not null mark:
create or replace view Q4nnmark(nmark)
as
SELECT COUNT(DISTINCT course_enrolments.student)
FROM course_enrolments
WHERE course_enrolments.mark IS NOT NULL;
 -- count of HD
create or replace view Q4HDcount(nHD)
as
SELECT COUNT(*)
FROM course_enrolments
WHERE course_enrolments.grade= 'HD';
 -- students with HD
create or replace view Q4aux(stu, numb)
as
SELECT course_enrolments.student, COUNT(*)
FROM course_enrolments
WHERE course_enrolments.grade = 'HD'
GROUP BY course_enrolments.student;

create or replace view Q4(num_student)
as
SELECT count(distinct Q4aux.stu)
FROM Q4aux, Q4nnmark, Q4HDcount
WHERE Q4aux.numb > (
    SELECT Q4HDcount.nHD * 1.0 / Q4nnmark.nmark
    FROM Q4nnmark, Q4HDcount
)
;

--Q5:
 --number of marks per course
create or replace view Q5nmark(course,nmark)
as
 SELECT course_enrolments.course, COUNT(*)
 FROM course_enrolments
 WHERE course_enrolments.mark IS NOT NULL GROUP BY course_enrolments.course
 ;
 -- valid courses
create or replace view Q5validcourses(vcourse)
as
 SELECT Q5nmark.course
 FROM Q5nmark
 WHERE Q5nmark.nmark >=20
 ;
 -- maximum marks per courses
 
create or replace view Q5maxmark(course, maximum)
as
 SELECT course_enrolments.course, max(course_enrolments.mark)
 FROM course_enrolments, Q5validcourses
 WHERE course_enrolments.course = Q5validcourses.vcourse
 GROUP BY course_enrolments.course
 ;

-- lowest per semester
create or replace view Q5lowpsem(sem, lowest)
as
 SELECT courses.semester, min(Q5maxmark.maximum)
 FROM courses, Q5maxmark
 WHERE courses.id = Q5maxmark.course
 GROUP BY courses.semester
 ;

create or replace view Q5defcourses(subj, semes)
as
 SELECT courses.subject, courses.semester
 FROM Q5maxmark, Q5lowpsem, courses
 WHERE Q5maxmark.maximum = Q5lowpsem.lowest AND courses.id = Q5maxmark.course AND courses.semester = Q5lowpsem.sem
 ;

create or replace view Q5(code, name, semester)
as
 SELECT subjects.code, subjects.name, semesters.name
 FROM subjects, semesters, Q5defcourses
 WHERE Q5defcourses.semes = semesters.id AND Q5defcourses.subj = subjects.id
;

-- Q6:
 --intersection
 create or replace view Q6inter(stuid)
 as
(SELECT DISTINCT people.unswid
FROM people, streams, stream_enrolments, program_enrolments, semesters, students
WHERE streams.name LIKE 'Management' AND streams.id = stream_enrolments.stream AND stream_enrolments.partof = program_enrolments.id
        AND program_enrolments.student = students.id AND students.stype LIKE 'local' AND students.id = people.id 
        AND program_enrolments.semester = semesters.id AND semesters.year = 2010 AND semesters.term LIKE 'S1')
    EXCEPT 
(SELECT DISTINCT people.unswid
FROM people, students, orgunits, courses, subjects, course_enrolments
WHERE subjects.offeredby = orgunits.id AND orgunits.name LIKE 'Faculty of Engineering' AND subjects.id = courses.subject AND
        courses.id = course_enrolments.course AND course_enrolments.student = students.id AND people.id = students.id );

create or replace view Q6(num)
as
SELECT COUNT(distinct stuid)
FROM Q6inter
;


-- Q7:

 --Marks
create or replace view Q7marks(semester, mark)
as
SELECT semesters.id, course_enrolments.mark
FROM semesters, subjects, courses, course_enrolments
WHERE subjects.name LIKE 'Database Systems' AND subjects.id = courses.subject AND courses.semester = semesters.id AND
        courses.id = course_enrolments.course AND course_enrolments.mark IS NOT NULL
;

 -- Average
create or replace view Q7average(semester, average)
as
SELECT Q7marks.semester, CAST(AVG(Q7marks.mark) as numeric(4,2))
FROM Q7marks
GROUP BY Q7marks.semester
;

 -- Format
create or replace view Q7(year, term, average_mark)
as
SELECT semesters.year, semesters.term, Q7average.average
FROM semesters, Q7average
WHERE Q7average.semester = semesters.id
;


-- Q8: 
 -- subjects and semesters
create or replace view Q8subjects(sub, semyear, semterm )
as
SELECT subjects.id, semesters.year, semesters.term
FROM subjects, courses, semesters
WHERE subjects.id = courses.subject AND courses.semester = semesters.id AND subjects.code LIKE 'COMP93%'
;

 --valid subjects
create or replace view Q8validsubject(subjectid)
as
SELECT DISTINCT a.sub
FROM Q8subjects a
WHERE NOT EXISTS 
( ( SELECT semesters.year, semesters.term
    FROM semesters
    WHERE semesters.year IN (2004,2005,2006,2007,2008,2009,2010,2011,2012,2013) AND semesters.term IN ('S1','S2') )
    EXCEPT
  ( SELECT b.semyear, b.semterm
    FROM Q8subjects b
    WHERE b.sub = a.sub ))
;

-- students and faliled subjects
create or replace view Q8failedsubjects(studentid, subjectid)
as
SELECT course_enrolments.student, subjects.id
FROM course_enrolments, courses, subjects
WHERE course_enrolments.mark IS NOT NULL AND course_enrolments.mark < 50 AND course_enrolments.course = courses.id
        AND courses.subject = subjects.id
;

 -- students who failed every valid subject
create or replace view Q8failedstudents(studentid)
as
SELECT DISTINCT a.studentid
FROM Q8failedsubjects a
WHERE NOT EXISTS
( ( SELECT *
    FROM Q8validsubject)
    EXCEPT
  ( SELECT b.subjectid
    FROM Q8failedsubjects b
    WHERE b.studentid = a.studentid))
;

 -- format
create or replace view Q8(zid, name)
as
SELECT CONCAT('z', people.unswid), people.name
FROM people, Q8failedstudents
WHERE Q8failedstudents.studentid = people.id
;

-- Q9:
 -- Valid students and programs
create or replace view Q9validprom(studentid, programid)
as
SELECT DISTINCT ON (program_enrolments.student, program_enrolments.program ) program_enrolments.student, program_enrolments.program 
FROM program_enrolments, programs, program_degrees, semesters, courses, course_enrolments
WHERE program_enrolments.program = programs.id AND programs.id = program_degrees.program AND program_degrees.abbrev = 'BSc'
        AND program_enrolments.semester = semesters.id AND semesters.year = 2010 AND semesters.term = 'S2' AND semesters.id = courses.semester
        AND courses.id = course_enrolments.course AND course_enrolments.student = program_enrolments.student AND courses.id = ANY (
            SELECT b.course
            FROM course_enrolments b
            WHERE b.mark >= 50 AND b.student = program_enrolments.student
        )
;

create or replace view Q9table(studentid, programid, courseid, uoccourse, mark)
as
SELECT Q9validprom.studentid, Q9validprom.programid, courses.id, subjects.uoc, course_enrolments.mark
FROM Q9validprom, program_enrolments, semesters, courses, course_enrolments, subjects
WHERE program_enrolments.student = Q9validprom.studentid AND program_enrolments.program = Q9validprom.programid AND 
        program_enrolments.semester = semesters.id AND semesters.id = courses.semester AND courses.id = course_enrolments.course AND course_enrolments.student = program_enrolments.student
        AND courses.subject = subjects.id AND course_enrolments.mark >= 50 AND semesters.year < 2011
;

create or replace view Q9def(studentid, programid)
as
(SELECT Q9table.studentid, Q9table.programid
FROM Q9table
GROUP BY Q9table.studentid, Q9table.programid
HAVING AVG(Q9table.mark) >= 80 )
INTERSECT 
(SELECT Q9table.studentid, Q9table.programid
FROM Q9table, programs
WHERE programs.id = Q9table.programid
GROUP BY Q9table.studentid, Q9table.programid, programs.uoc
HAVING sum(Q9table.uoccourse) >= programs.uoc )
;

create or replace view Q9(unswid, name)
as
SELECT DISTINCT people.unswid, people.name
FROM Q9def, people
WHERE Q9def.studentid = people.id 
;


-- Q10:
 -- Classes per room id
create or replace view Q10classes(roomid,classes)
as
SELECT rooms.id, classes.id
FROM rooms, room_types, classes, courses, semesters
WHERE room_types.id = rooms.rtype AND room_types.description = 'Lecture Theatre' AND classes.room = rooms.id AND
        classes.course = courses.id AND courses.semester = semesters.id AND semesters.year = 2011 AND semesters.term = 'S1'
;

 -- Lecture Theatre rooms
create or replace view Q10LT(roomid, roomunswid, roomname)
as
SELECT rooms.id, rooms.unswid, rooms.longname
FROM rooms, room_types
WHERE rooms.rtype = room_types.id AND room_types.description = 'Lecture Theatre'
;

 -- Adding up
create or replace view Q10def(roomunswid, roomname, classes)
as
SELECT Q10LT.roomunswid, Q10LT.roomname, COUNT(Q10classes.classes)
FROM Q10LT
LEFT JOIN Q10classes ON Q10LT.roomid = Q10classes.roomid
GROUP BY Q10LT.roomunswid, Q10LT.roomname
ORDER BY COUNT(Q10classes.classes) DESC
;

create or replace view Q10(unswid, longname, num, rank)
as
SELECT Q10def.roomunswid, Q10def.roomname, Q10def.classes, RANK() OVER (ORDER BY Q10def.classes DESC)
FROM Q10def
;


