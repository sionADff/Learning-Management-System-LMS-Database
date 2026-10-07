# Learning-Management-System-LMS-Database
Relational database for a university learning management system: users (teachers and students), study groups by major and academic year, courses with credits, enrollments and letter grades with a GPA-friendly grading scale. Designed and built as a coursework project (2025).

## Tech

- **DBMS:** MySQL 8.0+
- **Language:** SQL

## Schema (8 tables)

| Table | Purpose |
| --- | --- |
| `roles` | Lookup: teacher / student |
| `major` | Lookup: study programmes |
| `academic_year` | Lookup: course of study (1st–4th) |
| `grading_scale` | Letter grades A–F with grade points |
| `course` | Courses with credit values |
| `student_groups` | Study groups linked to a major and academic year |
| `users` | Teachers and students; students reference their group |
| `users_courses` | Enrollments (student + course) with a letter grade |

Design notes:

- Normalized to 3NF: majors, years, roles and grading scale live in separate lookup tables instead of repeating strings.
- Referential integrity with deliberate `ON DELETE` behaviour: `RESTRICT` for roles/major/year/groups (reference data must not disappear while in use), `SET NULL` when a student's group is removed (the student stays in the system), `CASCADE` for enrollments (remove grades with the student or course).
- `email` is unique; `gpa` is constrained to 0.00–4.00; only password **hashes** are stored.
- GPA can be computed from letter grades weighted by course credits (see example query 2).

## How to run

```bash
mysql -u root -p < lms.sql
```

Or paste into MySQL Workbench / phpMyAdmin and execute. The script drops and re-creates tables and loads seed data: 4 majors, 4 academic years, 32-capable group scheme (24 seeded), 4 courses, 5-letter grading scale, 2 teachers and 6 students with enrollments and grades.

## Example queries

**1. Transcript of a student (courses, letter grades, grade points):**

```sql
SELECT c.course_name, c.credits, gs.letter, gs.grade_points
FROM users_courses uc
JOIN course c         ON c.id = uc.courses_id
JOIN grading_scale gs ON gs.id = uc.grade_id
WHERE uc.users_id = 3;
```

**2. GPA per student, weighted by course credits:**

```sql
SELECT u.id, u.name, u.surname,
       ROUND(SUM(gs.grade_points * c.credits) / SUM(c.credits), 2) AS gpa_weighted
FROM users u
JOIN users_courses uc ON uc.users_id = u.id
JOIN course c         ON c.id = uc.courses_id
JOIN grading_scale gs ON gs.id = uc.grade_id
WHERE u.roles_id = 2
GROUP BY u.id, u.name, u.surname
ORDER BY gpa_weighted DESC;
```

**3. Group roster with major and academic year:**

```sql
SELECT g.group_name, m.major_name, y.year_name, u.name, u.surname
FROM student_groups g
JOIN major m         ON m.id = g.major_id
JOIN academic_year y ON y.id = g.academic_year_id
JOIN users u         ON u.group_id = g.id
WHERE g.group_name = 'CS-101'
ORDER BY u.surname;
```

**4. Enrollment count and average grade per course:**

```sql
SELECT c.course_name,
       COUNT(uc.users_id) AS enrolled,
       ROUND(AVG(gs.grade_points), 2) AS avg_points
FROM course c
LEFT JOIN users_courses uc ON uc.courses_id = c.id
LEFT JOIN grading_scale gs ON gs.id = uc.grade_id
GROUP BY c.id, c.course_name
ORDER BY enrolled DESC;
```

## Project status

Schema and seed data are complete and tested; application layer (backend/frontend) is out of scope for this repository.
