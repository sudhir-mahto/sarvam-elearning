-- =============================================================================
-- Sarvam E-Learning — DEMO / TEST DATA  (PostgreSQL)
-- =============================================================================
-- Loads sample admin, teacher, student, courses, enrollments, payments,
-- lectures, notes, quiz, contacts, and quiz results.
--
-- Password for ALL demo accounts: password123
--   admin@demo.sarvam   (ADMIN)
--   teacher@demo.sarvam (TEACHER)
--   student@demo.sarvam (STUDENT)
--
-- Requires: PostgreSQL with tables created by JPA (ddl-auto=update).
--
-- Idempotent: ON CONFLICT DO NOTHING on PK/unique columns so repeat runs do
-- not duplicate. Sequences are bumped past seeded IDs at the bottom.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Users (plain passwords — SecurityConfig treats stored plain as {noop})
-- -----------------------------------------------------------------------------
INSERT INTO users (user_id, name, email, password, role, active) VALUES
  (1, 'Admin Demo', 'admin@demo.sarvam', 'password123', 'ADMIN', true),
  (2, 'Priya Sharma', 'teacher@demo.sarvam', 'password123', 'TEACHER', true),
  (3, 'Rahul Verma', 'student@demo.sarvam', 'password123', 'STUDENT', true)
ON CONFLICT (user_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Courses (3 available; student enrolls in 2, leaves 1 for "Buy" testing)
-- -----------------------------------------------------------------------------
INSERT INTO courses (course_id, title, price, instructor, thumbnail) VALUES
  (1, 'Web Development Fundamentals', 499, 'Priya Sharma', NULL),
  (2, 'Database Systems with MySQL', 599, 'Priya Sharma', NULL),
  (3, 'Data Structures & Algorithms', 799, 'Priya Sharma', NULL)
ON CONFLICT (course_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Enrollments — student id 3 in courses 1 and 2
-- -----------------------------------------------------------------------------
INSERT INTO enrollments (enrollment_id, student_id, course_id, enrolled_at) VALUES
  (1, 3, 1, '2026-01-10 10:30:00'),
  (2, 3, 2, '2026-01-14 15:00:00')
ON CONFLICT (enrollment_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Payments — UPI refs + invoices (matches enrollments; course 3 unpaid)
-- -----------------------------------------------------------------------------
INSERT INTO payments (payment_id, invoice_no, student_id, course_id, upi_ref, amount, status, paid_at) VALUES
  (1, 'INV-DEMO0001', 3, 1, 'UPIREFWEB499001', 499.00, 'VERIFIED', '2026-01-10 10:31:00'),
  (2, 'INV-DEMO0002', 3, 2, 'UPIREFDB599002', 599.00, 'SUCCESS', '2026-01-14 15:02:00')
ON CONFLICT (payment_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Lectures — public YouTube videos (freeCodeCamp / Programming with Mosh)
-- One lecture per seeded course (ids 1, 2, 3) so the demo works end-to-end.
-- -----------------------------------------------------------------------------
INSERT INTO lectures (lecture_id, course_id, title, video_url, meeting_url) VALUES
  (1, 1, 'HTML Full Course - Build a Website Tutorial', 'https://www.youtube.com/watch?v=pQN-pnXPaVg', NULL),
  (2, 1, 'Live doubt session (week 1)', NULL, 'https://meet.google.com/demo-week1-sarvam'),
  (3, 2, 'MySQL Tutorial for Beginners', 'https://www.youtube.com/watch?v=7S_tz1z_5bA', NULL),
  (4, 3, 'Data Structures Easy to Advanced Course', 'https://www.youtube.com/watch?v=RBSGKlAvoiM', NULL)
ON CONFLICT (lecture_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Notes — downloadable file URLs (stable Mozilla-hosted PDFs)
-- -----------------------------------------------------------------------------
INSERT INTO notes (note_id, course_id, title, file_url) VALUES
  (1, 1, 'Week 1 — HTML cheat sheet', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf'),
  (2, 1, 'CSS layout checklist', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf'),
  (3, 2, 'SQL basics handout', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf'),
  (4, 3, 'Big-O cheat sheet', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf')
ON CONFLICT (note_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Quiz — one sample question
-- -----------------------------------------------------------------------------
INSERT INTO quiz (quiz_id, course_id, question, option_a, option_b, option_c, option_d, correct_option) VALUES
  (1, 1, 'What does HTML stand for?', 'Hyper Text Markup Language', 'High Tech Modern Language', 'Home Tool Markup Language', 'Hyperlinks Text Mark Language', 'A')
ON CONFLICT (quiz_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Contact / support — one pending, one answered
-- -----------------------------------------------------------------------------
INSERT INTO contact (contact_id, name, email, phone, message, admin_reply, created_at) VALUES
  (1, 'Rahul Verma', 'student@demo.sarvam', '9876500000', 'When is the next live session for Web Dev?', 'Tuesday 6 PM IST. Link is in Lecture 2.', '2026-01-12 09:00:00'),
  (2, 'Rahul Verma', 'student@demo.sarvam', '9876500000', 'Can I get an invoice copy for tax?', NULL, '2026-01-18 11:20:00')
ON CONFLICT (contact_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Quiz result — sample attempt for student on course 1
-- -----------------------------------------------------------------------------
INSERT INTO results (result_id, student_id, course_id, total_questions, correct_answers, percentage, submitted_at) VALUES
  (1, 3, 1, 1, 1, 100.00, '2026-01-16 18:45:00')
ON CONFLICT (result_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Bump JPA-managed identity sequences past the seeded IDs so app-side inserts
-- don't collide on PK. Hibernate names the sequence after the table's id col.
-- -----------------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('users',       'user_id'),       (SELECT COALESCE(MAX(user_id),       0) FROM users));
SELECT setval(pg_get_serial_sequence('courses',     'course_id'),     (SELECT COALESCE(MAX(course_id),     0) FROM courses));
SELECT setval(pg_get_serial_sequence('enrollments', 'enrollment_id'), (SELECT COALESCE(MAX(enrollment_id), 0) FROM enrollments));
SELECT setval(pg_get_serial_sequence('payments',    'payment_id'),    (SELECT COALESCE(MAX(payment_id),    0) FROM payments));
SELECT setval(pg_get_serial_sequence('lectures',    'lecture_id'),    (SELECT COALESCE(MAX(lecture_id),    0) FROM lectures));
SELECT setval(pg_get_serial_sequence('notes',       'note_id'),       (SELECT COALESCE(MAX(note_id),       0) FROM notes));
SELECT setval(pg_get_serial_sequence('quiz',        'quiz_id'),       (SELECT COALESCE(MAX(quiz_id),       0) FROM quiz));
SELECT setval(pg_get_serial_sequence('contact',     'contact_id'),    (SELECT COALESCE(MAX(contact_id),    0) FROM contact));
SELECT setval(pg_get_serial_sequence('results',     'result_id'),     (SELECT COALESCE(MAX(result_id),     0) FROM results));
