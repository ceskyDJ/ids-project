--------------------------------------
--                                  --
--      IDS project - 2nd part      --
--                                  --
-- Author: Michal Šmahel (xsmahe01) --
-- Author: Martin Havlík (xhavli56) --
-- Date: March 2022                 --
--------------------------------------

------------------------------------------------------------------------------------------------------------------ RESET
-- PURGE is used for unnamed linked sequences deletion
DROP TABLE question_assessments;
DROP TABLE exam_elaborations PURGE;
DROP TABLE registered_exam_dates;
DROP TABLE exams_in_rooms;
DROP TABLE exam_dates;
DROP TABLE students_admitted_to_exams;
DROP TABLE exams PURGE;
DROP TABLE lecturers_teaching_courses;
DROP TABLE course_guarantors;
DROP TABLE lecturers;
DROP TABLE courses PURGE;
DROP TABLE rooms;
DROP TABLE enrolled_students;
DROP TABLE users PURGE;

----------------------------------------------------------------------------------------------------------------- TABLES
-- Users
CREATE TABLE users (
    user_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    login VARCHAR2(20) NOT NULL CHECK(REGEXP_LIKE(login, '^(x[a-z]{5}[0-9a-z]{2}|[a-wyz][a-z]+)$')),
    password VARCHAR2(255) NOT NULL,
    first_name VARCHAR2(30) NOT NULL,
    last_name VARCHAR2(30) NOT NULL,
    date_of_birth DATE NOT NULL
);

-- Enrolled students
CREATE TABLE enrolled_students (
    student_id REFERENCES users(user_id), -- FK & PK
    academic_year CHAR(9) NOT NULL CHECK(REGEXP_LIKE(academic_year, '^\d{4}/\d{4}$')), -- PK
    year_of_study NUMBER(2) NOT NULL CHECK(year_of_study > 0),
    study_program VARCHAR2(10) NOT NULL CHECK(study_program IN ('bachelor', 'master', 'doctoral')),
    CONSTRAINT pk_enrolled_students PRIMARY KEY (student_id, academic_year)
);

-- Rooms
CREATE TABLE rooms (
    room_label VARCHAR2(7) PRIMARY KEY,
    capacity NUMBER(3) NOT NULL CHECK(capacity > 0) -- up to 999
);

-- Lecturers
CREATE TABLE lecturers (
    lecturer_id REFERENCES users(user_id) PRIMARY KEY, -- FK & PK
    room_label REFERENCES rooms(room_label) NOT NULL, -- FK
    -- Source: https://www.jochentopf.com/email/chars.html (only chars with "OK"), https://www.ietf.org/rfc/rfc1035.txt, simplified
    email VARCHAR2(125) NOT NULL UNIQUE CHECK(REGEXP_LIKE(email, '^[0-9A-Za-z+\-_]([0-9A-Za-z+\-_.]?[0-9A-Za-z+\-_])*@([a-zA-Z][a-zA-Z0-9\-]*\.)+[a-zA-Z][a-zA-Z0-9\-]+$')),
    phone_number CHAR(13) CHECK(REGEXP_LIKE(phone_number, '^\+\d{12}$'))
);

-- Courses
CREATE TABLE courses (
    course_abbreviation VARCHAR2(5) PRIMARY KEY, -- PK
    semester VARCHAR2(6) NOT NULL CHECK(semester IN ('summer', 'winter')),
    name VARCHAR2(70) NOT NULL,
    awarded_credits NUMBER(2) NOT NULL CHECK(awarded_credits > 0),
    description VARCHAR2(1000)
);

-- Lecturers teaching courses (Lecturers <-> Courses)
CREATE TABLE lecturers_teaching_courses (
    lecturer_id REFERENCES lecturers(lecturer_id), -- FK & PK
    course_abbreviation REFERENCES courses(course_abbreviation), --FK & PK
    academic_year CHAR(9) NOT NULL CHECK(REGEXP_LIKE(academic_year, '^\d{4}/\d{4}$')), -- PK
    CONSTRAINT pk_lecturers_teaching_courses PRIMARY KEY (lecturer_id, course_abbreviation, academic_year)
);

-- Course guarantors
CREATE TABLE course_guarantors (
    course_abbreviation REFERENCES courses(course_abbreviation), -- FK & PK
    academic_year CHAR(9) NOT NULL CHECK(REGEXP_LIKE(academic_year, '^\d{4}/\d{4}$')), -- PK
    guarantor_id REFERENCES lecturers(lecturer_id) NOT NULL, -- FK
    CONSTRAINT pk_course_guarantors PRIMARY KEY (course_abbreviation, academic_year)
);

-- Exams
CREATE TABLE exams (
    exam_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, -- PK
    course_abbreviation REFERENCES courses(course_abbreviation) NOT NULL, -- FK
    academic_year CHAR(9) NOT NULL CHECK(REGEXP_LIKE(academic_year, '^\d{4}/\d{4}$')),
    type VARCHAR2(10) NOT NULL CHECK(type IN ('midterm', 'term')),
    time_limit NUMBER(3) NOT NULL CHECK(time_limit > 0),
    max_points NUMBER(3) NOT NULL CHECK(max_points BETWEEN 0 and 100),
    min_points NUMBER(3) NOT NULL CHECK(min_points BETWEEN 0 and 100)
);

-- Students admitted to exams (Enrolled students <-> Exams)
CREATE TABLE students_admitted_to_exams (
    student_id, -- FK & PK
    academic_year, -- FK & PK
    exam_id REFERENCES exams(exam_id) NOT NULL, -- FK & PK
    points_so_far NUMBER(2) NOT NULL CHECK(points_so_far BETWEEN 0 and 99),
    FOREIGN KEY (academic_year, student_id) REFERENCES enrolled_students(academic_year, student_id),
    CONSTRAINT pk_students_admitted_to_exams PRIMARY KEY (academic_year, student_id, exam_id)
);

-- Exam dates
CREATE TABLE exam_dates (
    exam_id REFERENCES exams(exam_id), -- FK & PK
    exam_date_number NUMBER(3) CHECK(exam_date_number > 0), -- PK TODO: number generation
    format VARCHAR2(10) NOT NULL CHECK(format IN ('oral', 'written', 'combined')),
    no_questions NUMBER(2) NOT NULL CHECK(no_questions > 0),
    time_of_exam TIMESTAMP NOT NULL,
    registration_start TIMESTAMP NOT NULL,
    registration_end TIMESTAMP NOT NULL,
    student_capacity NUMBER(3) NOT NULL CHECK(student_capacity > 0),
    CONSTRAINT pk_exam_dates PRIMARY KEY (exam_id, exam_date_number)
);

-- Exams in rooms (Exam dates <-> Rooms)
CREATE TABLE exams_in_rooms (
    exam_id, -- FK & PK
    exam_date_number, -- FK & PK
    room_label REFERENCES rooms(room_label), -- FK & PK
    FOREIGN KEY (exam_id, exam_date_number) REFERENCES exam_dates(exam_id, exam_date_number),
    CONSTRAINT pk_exams_in_rooms PRIMARY KEY (exam_id, exam_date_number, room_label)
);

-- Registered exam dates (Enrolled students <-> Exam dates)
CREATE TABLE registered_exam_dates (
    exam_id, -- FK & PK
    exam_date_number, -- FK & PK
    student_id, -- FK & PK
    academic_year, -- FK & PK
    FOREIGN KEY (student_id, academic_year) REFERENCES enrolled_students(student_id, academic_year),
    FOREIGN KEY (exam_id, exam_date_number) REFERENCES exam_dates(exam_id, exam_date_number),
    CONSTRAINT pk_registered_exam_dates PRIMARY KEY (student_id, academic_year, exam_id, exam_date_number)
);

-- Exam elaborations
CREATE TABLE exam_elaborations (
    exam_elaboration_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, -- PK
    student_id NOT NULL, -- FK
    academic_year NOT NULL, -- FK
    exam_id NOT NULL, -- FK
    exam_date_number NOT NULL, -- FK
    state_of_completion VARCHAR2(15) NOT NULL CHECK(state_of_completion IN ('completed', 'expelled', 'not_finished')),
    FOREIGN KEY (student_id, academic_year) REFERENCES enrolled_students(student_id, academic_year),
    FOREIGN KEY (exam_id, exam_date_number) REFERENCES exam_dates(exam_id, exam_date_number)
);

-- Question assessments
CREATE TABLE question_assessments (
    exam_elaboration_id REFERENCES exam_elaborations(exam_elaboration_id), -- FK & PK
    question_number NUMBER(2) CHECK(question_number > 0), -- PK TODO: number generation
    lecturer_id REFERENCES lecturers(lecturer_id) NOT NULL, -- FK
    time_of_assessments TIMESTAMP NOT NULL,
    awarded_points NUMBER(3) NOT NULL CHECK(awarded_points BETWEEN 0 and 100),
    "comment" VARCHAR2(500),
    CONSTRAINT pk_question_assessments PRIMARY KEY (exam_elaboration_id, question_number)
);


------------------------------------------------------------------------------------------------------------------- DATA
-- Users
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (230974, 'xhavli56', '893hfww0hs', 'Martin', 'Havlik', '19-8-2000');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (231754, 'xholes12', '80hsfd89&57', 'Aleš', 'Holeš', '27-2-1999');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (230365, 'xrados22', 'h6GT0gx3', 'Milan', 'Radostný', '1-10-2000');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (220300, 'ikonrad', '773939hfhd0s0', 'Michal', 'Konrád', '3-5-1979');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (230786, 'xivano02', 'g0AL8LG', 'Andrei', 'Ivanov', '7-5-2001');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (229797, 'xsokol17', 'hgkldfakl89358', 'Richard', 'Sokol', '14-11-1998');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (221456, 'imesner', 'jg_hgd^$)hs0&3', 'Lubomír', 'Mesner', '5-3-1971');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (230999, 'xkubik36', '838vh1ghs0hf', 'Radovan', 'Kubík', '11-4-1997');
INSERT INTO users (user_id, login, password, first_name, last_name, date_of_birth)
    VALUES (220546, 'ilojza', '^)#&hslgh07503', 'Květoslav', 'Lojza', '20-12-1971');

-- Enrolled students
INSERT INTO enrolled_students (student_id, academic_year, year_of_study, study_program)
    VALUES (230974, '2021/2022', '2', 'bachelor');
INSERT INTO enrolled_students (student_id, academic_year, year_of_study, study_program)
    VALUES (231754, '2021/2022', '3', 'bachelor');
INSERT INTO enrolled_students (student_id, academic_year, year_of_study, study_program)
    VALUES (230365, '2021/2022', '2', 'bachelor');
INSERT INTO enrolled_students (student_id, academic_year, year_of_study, study_program)
    VALUES (229797, '2021/2022', '2', 'master');

-- Rooms
INSERT INTO rooms (room_label, capacity)
    VALUES ('L206', 20);
INSERT INTO rooms (room_label, capacity)
    VALUES ('L108', 20);
INSERT INTO rooms (room_label, capacity)
    VALUES ('D105', 350);
INSERT INTO rooms (room_label, capacity)
    VALUES ('E105', 150);

-- Lecturers
INSERT INTO lecturers (lecturer_id, room_label, email, phone_number)
    VALUES (220300, 'L206', 'ikonrad@fit.cz', '+420732657800');
INSERT INTO lecturers (lecturer_id, room_label, email)
    VALUES (221456, 'L108', 'imesner@fit.cz');
INSERT INTO lecturers (lecturer_id, room_label, email, phone_number)
    VALUES (220546, 'L206', 'klojza@gmail.com', '+420721504657');

-- Courses
INSERT INTO courses  (course_abbreviation, semester, name, awarded_credits, description)
    VALUES ('IDS', 'summer', 'Database Systems', 5, 'IDS desc');
INSERT INTO courses  (course_abbreviation, semester, name, awarded_credits, description)
    VALUES ('IAN', 'summer', 'Binary Code Analysis', 4, 'IAN desc');
INSERT INTO courses  (course_abbreviation, semester, name, awarded_credits, description)
    VALUES ('IMA2', 'winter', 'Calculus 2', 4, 'IMA2 desc');

-- Course guarantors (Lecturers <-> Courses)
INSERT INTO course_guarantors (course_abbreviation, academic_year, guarantor_id)
    VALUES ('IDS', '2021/2022', 221456);
INSERT INTO course_guarantors (course_abbreviation, academic_year, guarantor_id)
    VALUES ('IAN', '2021/2022', 220300);
INSERT INTO course_guarantors (course_abbreviation, academic_year, guarantor_id)
    VALUES ('IMA2', '2021/2022', 220300);

-- Lecturers teaching courses (Lecturers <-> Courses)
INSERT INTO lecturers_teaching_courses (lecturer_id, course_abbreviation, academic_year)
    VALUES (220546, 'IDS', '2021/2022');
INSERT INTO lecturers_teaching_courses (lecturer_id, course_abbreviation, academic_year)
    VALUES (220546, 'IAN', '2021/2022');
INSERT INTO lecturers_teaching_courses (lecturer_id, course_abbreviation, academic_year)
    VALUES (220300, 'IMA2', '2021/2022');

-- Exams
INSERT INTO exams (exam_id, course_abbreviation, academic_year, type, time_limit, max_points, min_points)
    VALUES (12, 'IDS', '2021/2022', 'midterm', 60, 15, 0);
INSERT INTO exams (exam_id, course_abbreviation, academic_year, type, time_limit, max_points, min_points)
    VALUES (33, 'IDS', '2021/2022', 'term', 100, 51, 20);
INSERT INTO exams (exam_id, course_abbreviation, academic_year, type, time_limit, max_points, min_points)
    VALUES (50, 'IAN', '2021/2022', 'term', 50, 40, 0);
INSERT INTO exams (exam_id, course_abbreviation, academic_year, type, time_limit, max_points, min_points)
    VALUES (62, 'IMA2', '2021/2022', 'term', 120, 80, 40);

-- Students admitted to exams (Enrolled students <-> Exams)
INSERT INTO students_admitted_to_exams (academic_year, student_id, exam_id, points_so_far)
    VALUES ('2021/2022', 230974, 33, 30);
INSERT INTO students_admitted_to_exams (academic_year, student_id, exam_id, points_so_far)
    VALUES ('2021/2022', 231754, 50, 50);

-- Exam dates
INSERT INTO exam_dates (exam_id, exam_date_number, format, no_questions, time_of_exam, registration_start, registration_end, student_capacity)
    VALUES (12, 1, 'written', 6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 150);
INSERT INTO exam_dates (exam_id, exam_date_number, format, no_questions, time_of_exam, registration_start, registration_end, student_capacity)
    VALUES (12, 2, 'written', 6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 150);
INSERT INTO exam_dates (exam_id, exam_date_number, format, no_questions, time_of_exam, registration_start, registration_end, student_capacity)
    VALUES (62, 1, 'written', 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 800);
INSERT INTO exam_dates (exam_id, exam_date_number, format, no_questions, time_of_exam, registration_start, registration_end, student_capacity)
    VALUES (62, 2, 'written', 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 400);
INSERT INTO exam_dates (exam_id, exam_date_number, format, no_questions, time_of_exam, registration_start, registration_end, student_capacity)
    VALUES (33, 1, 'written', 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 300);

-- Exams in rooms (Exam dates <-> Rooms)
INSERT INTO exams_in_rooms (exam_id, exam_date_number, room_label)
    VALUES (12, 1, 'D105');
INSERT INTO exams_in_rooms (exam_id, exam_date_number, room_label)
    VALUES (12, 2, 'D105');
INSERT INTO exams_in_rooms (exam_id, exam_date_number, room_label)
    VALUES (62, 2, 'E105');
INSERT INTO exams_in_rooms (exam_id, exam_date_number, room_label)
    VALUES (33, 1, 'E105');

-- Registered exam dates (Enrolled students <-> Exam dates)
INSERT INTO registered_exam_dates (student_id, academic_year, exam_id, exam_date_number)
    VALUES (231754, '2021/2022', 62, 1);
INSERT INTO registered_exam_dates (student_id, academic_year, exam_id, exam_date_number)
    VALUES (231754, '2021/2022', 62, 2);

-- Exam elaborations (Enrolled students <-> Exam dates)
INSERT INTO exam_elaborations (exam_elaboration_id, student_id, academic_year, exam_id, exam_date_number, state_of_completion)
    VALUES (100, 231754, '2021/2022', 62, 1, 'expelled');
INSERT INTO exam_elaborations (exam_elaboration_id, student_id, academic_year, exam_id, exam_date_number, state_of_completion)
    VALUES (101, 231754, '2021/2022', 62, 2, 'completed');

-- Question assessments
INSERT INTO question_assessments (exam_elaboration_id, question_number, lecturer_id, awarded_points, time_of_assessments, "comment")
    VALUES (100, 1, 220546, 8, CURRENT_TIMESTAMP, 'minor mistake in notation');
INSERT INTO question_assessments (exam_elaboration_id, question_number, lecturer_id, awarded_points, time_of_assessments, "comment")
    VALUES (100, 2, 220546, 10, CURRENT_TIMESTAMP, 'ok');
INSERT INTO question_assessments (exam_elaboration_id, question_number, lecturer_id, awarded_points, time_of_assessments, "comment")
    VALUES (100, 3, 220546, 4, CURRENT_TIMESTAMP, 'wrong usage of ternary operator');
INSERT INTO question_assessments (exam_elaboration_id, question_number, lecturer_id, awarded_points, time_of_assessments, "comment")
    VALUES (101, 1, 220546, 15, CURRENT_TIMESTAMP, 'flawless definition, good job');
