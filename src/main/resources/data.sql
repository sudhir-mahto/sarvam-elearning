-- =============================================================================
-- Sarvam E-Learning — DEMO / TEST DATA
-- =============================================================================
-- Loads sample admin, teacher, student, courses, enrollments, payments,
-- lectures, notes, quiz, contacts, and quiz results.
--
-- Password for ALL demo accounts: password123
--   admin@demo.sarvam   (ADMIN)
--   teacher@demo.sarvam (TEACHER)
--   student@demo.sarvam (STUDENT)
--
-- Requires: MySQL, database sarvam_db, tables created (run app once with
--           spring.jpa.hibernate.ddl-auto=update).
--
-- Idempotent: uses INSERT IGNORE + fixed IDs so repeat runs do not duplicate.
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- Users (plain passwords — SecurityConfig treats stored plain as {noop})
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO users (id, name, email, password, role, active) VALUES
  (1, 'Admin Demo', 'admin@demo.sarvam', 'password123', 'ADMIN', 1),
  (2, 'Priya Sharma', 'teacher@demo.sarvam', 'password123', 'TEACHER', 1),
  (3, 'Rahul Verma', 'student@demo.sarvam', 'password123', 'STUDENT', 1);

-- -----------------------------------------------------------------------------
-- Courses (3 available; student enrolls in 2, leaves 1 for "Buy" testing)
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO courses (id, title, price, instructor, thumbnail) VALUES
  (1, 'Web Development Fundamentals', 499, 'Priya Sharma', NULL),
  (2, 'Database Systems with MySQL', 599, 'Priya Sharma', NULL),
  (3, 'Data Structures & Algorithms', 799, 'Priya Sharma', NULL);

-- -----------------------------------------------------------------------------
-- Enrollments — student id 3 in courses 1 and 2
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO enrollments (id, student_id, course_id, enrolled_at) VALUES
  (1, 3, 1, '2026-01-10 10:30:00'),
  (2, 3, 2, '2026-01-14 15:00:00');

-- -----------------------------------------------------------------------------
-- Payments — UPI refs + invoices (matches enrollments; course 3 unpaid)
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO payments (id, invoice_no, student_id, course_id, upi_ref, amount, status, paid_at) VALUES
  (1, 'INV-DEMO0001', 3, 1, 'UPIREFWEB499001', 499.00, 'VERIFIED', '2026-01-10 10:31:00'),
  (2, 'INV-DEMO0002', 3, 2, 'UPIREFDB599002', 599.00, 'SUCCESS', '2026-01-14 15:02:00');

-- -----------------------------------------------------------------------------
-- Lectures — YouTube + optional Meet (course 1 & 2)
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO lectures (id, course_id, title, video_url, meeting_url) VALUES
  (1, 1, 'Introduction to HTML & CSS', 'https://www.youtube.com/watch?v=UB1O30fR-EE', NULL),
  (2, 1, 'Live doubt session (week 1)', NULL, 'https://meet.google.com/demo-week1-sarvam'),
  (3, 2, 'Relational model & ER diagrams', 'https://www.youtube.com/watch?v=ztBpPe0F_Cg', NULL);

-- -----------------------------------------------------------------------------
-- Notes — downloadable file URLs
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO notes (id, course_id, title, file_url) VALUES
  (1, 1, 'Week 1 — HTML cheat sheet', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
  (2, 1, 'CSS layout checklist', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
  (3, 2, 'SQL basics handout', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf');

-- -----------------------------------------------------------------------------
-- Quiz — one sample question (columns match Quiz @Column snake_case names)
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `quiz` (`id`, `course_id`, `question`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`) VALUES
  (1, 1, 'What does HTML stand for?', 'Hyper Text Markup Language', 'High Tech Modern Language', 'Home Tool Markup Language', 'Hyperlinks Text Mark Language', 'A');

-- -----------------------------------------------------------------------------
-- Contact / support — one pending, one answered
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO contact (id, name, email, phone, message, admin_reply, created_at) VALUES
  (1, 'Rahul Verma', 'student@demo.sarvam', '9876500000', 'When is the next live session for Web Dev?', 'Tuesday 6 PM IST. Link is in Lecture 2.', '2026-01-12 09:00:00'),
  (2, 'Rahul Verma', 'student@demo.sarvam', '9876500000', 'Can I get an invoice copy for tax?', NULL, '2026-01-18 11:20:00');

-- -----------------------------------------------------------------------------
-- Quiz result — sample attempt for student on course 1
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO results (id, student_id, course_id, total_questions, correct_answers, percentage, submitted_at) VALUES
  (1, 3, 1, 1, 1, 100.00, '2026-01-16 18:45:00');

