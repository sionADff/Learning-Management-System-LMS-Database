
DROP TABLE IF EXISTS users_courses;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS student_groups;
DROP TABLE IF EXISTS grading_scale;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS major;
DROP TABLE IF EXISTS academic_year;
DROP TABLE IF EXISTS roles;

-- ------------------------------------------------------------
-- Reference (lookup) tables
-- ------------------------------------------------------------
CREATE TABLE roles (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(20) NOT NULL UNIQUE          -- 'teacher', 'student'
);

CREATE TABLE major (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    major_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE academic_year (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    year_name VARCHAR(20) NOT NULL UNIQUE          -- 'First course', ...
);

CREATE TABLE grading_scale (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    letter       VARCHAR(2) NOT NULL UNIQUE,       -- A, B, C, D, F
    grade_points DECIMAL(3,2) NOT NULL
);

CREATE TABLE course (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    course_name VARCHAR(60) NOT NULL,
    credits     INT DEFAULT 3,
    CHECK (credits > 0)
);

-- ------------------------------------------------------------
-- Groups: a study group belongs to a major and an academic year
-- ------------------------------------------------------------
CREATE TABLE student_groups (
    id             INT PRIMARY KEY AUTO_INCREMENT,
    group_name     VARCHAR(10) NOT NULL UNIQUE,
    major_id       INT NOT NULL,
    academic_year_id INT NOT NULL,
    FOREIGN KEY (major_id)         REFERENCES major(id)         ON DELETE RESTRICT,
    FOREIGN KEY (academic_year_id) REFERENCES academic_year(id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- Users: teachers and students
-- ------------------------------------------------------------
CREATE TABLE users (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(60)  NOT NULL,
    surname       VARCHAR(60)  NOT NULL,
    email         VARCHAR(60)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    birthdate     DATE         NOT NULL,
    address       VARCHAR(100) NOT NULL,
    gpa           DECIMAL(3,2) DEFAULT 0.0,
    roles_id      INT NOT NULL,
    group_id      INT,
    FOREIGN KEY (roles_id) REFERENCES roles(id)              ON DELETE RESTRICT,
    FOREIGN KEY (group_id) REFERENCES student_groups(id)     ON DELETE SET NULL,
    CHECK (gpa BETWEEN 0.0 AND 4.0)
);

-- ------------------------------------------------------------
-- Enrollments: student <-> course, with a letter grade
-- ------------------------------------------------------------
CREATE TABLE users_courses (
    users_id   INT NOT NULL,
    courses_id INT NOT NULL,
    grade_id   INT,
    PRIMARY KEY (users_id, courses_id),
    FOREIGN KEY (users_id)   REFERENCES users(id)         ON DELETE CASCADE,
    FOREIGN KEY (courses_id) REFERENCES course(id)        ON DELETE CASCADE,
    FOREIGN KEY (grade_id)   REFERENCES grading_scale(id) ON DELETE SET NULL
);

-- ============================================================
-- Seed data
-- ============================================================
INSERT INTO roles (role_name) VALUES ('teacher'), ('student');

INSERT INTO major (major_name) VALUES
    ('Computer Science'),
    ('Web Programming'),
    ('Data Science'),
    ('Machine Learning Engineering');

INSERT INTO academic_year (year_name) VALUES
    ('First course'), ('Second course'), ('Third course'), ('Fourth course');

INSERT INTO grading_scale (letter, grade_points) VALUES
    ('A', 4.0), ('B', 3.0), ('C', 2.0), ('D', 1.0), ('F', 0.0);

INSERT INTO course (course_name, credits) VALUES
    ('Web Programming', 4),
    ('User-Centred Experimental Design', 3),
    ('Mathematics for Computer Science', 4),
    ('Introduction to Data Structures and Algorithms', 4);

INSERT INTO student_groups (group_name, major_id, academic_year_id) VALUES
    ('CS-101', 1, 1), ('CS-102', 1, 1),
    ('CS-201', 1, 2), ('CS-202', 1, 2),
    ('CS-301', 1, 3), ('CS-302', 1, 3),
    ('CS-401', 1, 4), ('CS-402', 1, 4),
    ('WP-101', 2, 1), ('WP-201', 2, 2), ('WP-301', 2, 3), ('WP-401', 2, 4),
    ('DS-101', 3, 1), ('DS-201', 3, 2), ('DS-301', 3, 3), ('DS-401', 3, 4),
    ('MLE-101', 4, 1), ('MLE-201', 4, 2), ('MLE-301', 4, 3), ('MLE-401', 4, 4);

-- Demo users (password hashes are placeholders, not real credentials)
INSERT INTO users (name, surname, email, password_hash, birthdate, address, roles_id, group_id) VALUES
    ('Nurlan', 'I.',   'nurlan.teacher@example.com', 'hash_demo_1', '1985-03-12', 'Almaty, Abay Ave 12',   1, NULL),   -- teacher
    ('Aigerim','T.',   'aigerim.teacher@example.com','hash_demo_2', '1990-07-25', 'Almaty, Dostyk Ave 5',  1, NULL),   -- teacher
    ('Daniyar','S.',   'daniyar@example.com',        'hash_demo_3', '2006-01-14', 'Almaty, Microdistrict 3', 2, 1),  -- CS-101
    ('Alua',   'K.',   'alua@example.com',           'hash_demo_4', '2006-05-02', 'Almaty, Tole Bi 88',      2, 1),
    ('Arman',  'B.',   'arman@example.com',          'hash_demo_5', '2005-11-30', 'Almaty, Rozybakiev 45',   2, 1),
    ('Sofia',  'P.',   'sofia@example.com',          'hash_demo_6', '2006-09-19', 'Astana, Turan Ave 4',     2, 2),  -- CS-102
    ('Temirlan','O.',  'temirlan@example.com',       'hash_demo_7', '2004-02-08', 'Almaty, Al-Farabi 71',    2, 4),  -- CS-201
    ('Dana',   'M.',   'dana@example.com',           'hash_demo_8', '2004-06-21', 'Astana, Mangilik El 1',   2, 13); -- DS-101

-- Enrollments with letter grades
INSERT INTO users_courses (users_id, courses_id, grade_id) VALUES
    (3, 1, 1), (3, 3, 2), (3, 4, 1),          -- Daniyar:  A, B, A
    (4, 1, 2), (4, 2, 1), (4, 3, 1),          -- Alua:     B, A, A
    (5, 1, 4), (5, 3, 3),                     -- Arman:    D, C
    (6, 2, 1), (6, 3, 2),                     -- Sofia:    A, B
    (7, 1, 1), (7, 4, 2),                     -- Temirlan: A, B
    (8, 3, 2), (8, 4, 1);                     -- Dana:     B, A

-- ============================================================
-- Example analytical queries
-- ============================================================

-- 1. Transcript of a student: courses, letter grades and grade points
SELECT c.course_name, c.credits, gs.letter, gs.grade_points
FROM users_courses uc
JOIN course c        ON c.id = uc.courses_id
JOIN grading_scale gs ON gs.id = uc.grade_id
WHERE uc.users_id = 3;

-- 2. GPA per student, weighted by course credits
--    (stored users.gpa can be refreshed from this query)
SELECT u.id, u.name, u.surname,
       ROUND(SUM(gs.grade_points * c.credits) / SUM(c.credits), 2) AS gpa_weighted
FROM users u
JOIN users_courses uc ON uc.users_id = u.id
JOIN course c         ON c.id = uc.courses_id
JOIN grading_scale gs ON gs.id = uc.grade_id
WHERE u.roles_id = 2                    -- students only
GROUP BY u.id, u.name, u.surname
ORDER BY gpa_weighted DESC;

-- 3. Group roster with major and academic year
SELECT g.group_name, m.major_name, y.year_name, u.name, u.surname
FROM student_groups g
JOIN major m        ON m.id = g.major_id
JOIN academic_year y ON y.id = g.academic_year_id
JOIN users u        ON u.group_id = g.id
WHERE g.group_name = 'CS-101'
ORDER BY u.surname;

-- 4. Enrollment and average grade points per course
SELECT c.course_name,
       COUNT(uc.users_id) AS enrolled,
       ROUND(AVG(gs.grade_points), 2) AS avg_points
FROM course c
LEFT JOIN users_courses uc ON uc.courses_id = c.id
LEFT JOIN grading_scale gs ON gs.id = uc.grade_id
GROUP BY c.id, c.course_name
ORDER BY enrolled DESC;
