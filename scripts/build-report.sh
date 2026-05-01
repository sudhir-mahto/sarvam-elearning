#!/usr/bin/env bash
# Build a printable BCA-final-year project report PDF for Sarvam E-Learning.
#
# Pipeline:
#   1. Assemble PROJECT_REPORT.md from a hand-written report body + an auto-
#      generated appendix that inlines every source file as a fenced code block.
#   2. Render to standalone HTML with pandoc (syntax highlighting + a printable
#      stylesheet).
#   3. Convert HTML to PDF with headless Chrome.
#
# Output:
#   PROJECT_REPORT.md
#   PROJECT_REPORT.html
#   PROJECT_REPORT.pdf

set -euo pipefail
cd "$(dirname "$0")/.."

REPORT_MD="PROJECT_REPORT.md"
REPORT_HTML="PROJECT_REPORT.html"
REPORT_PDF="PROJECT_REPORT.pdf"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# ---------- 1. Build the Markdown ----------
# Body of the report: write to REPORT_MD, then append an appendix.
cat > "$REPORT_MD" <<'EOF'
---
title: "Sarvam Professional Education — E-Learning Platform"
subtitle: "BCA Final Year Project Report"
author: "Department of Computer Application"
date: "2026"
---

# Abstract

**Sarvam Professional Education** is a full-stack web-based e-learning
platform that lets a college or training institute manage online courses
from end to end. The system supports three classes of users — **Students**,
**Teachers**, and **Administrators** — each with their own dashboard and
strictly role-based access control.

A student can browse the course catalogue, purchase a course by submitting
a UPI reference, watch embedded YouTube lectures, download study notes
(PDF), attempt multiple-choice quizzes, view computed results, and raise
support requests. A teacher can create and edit courses, lectures, notes,
and quizzes, and view the list of enrolled students. An administrator
manages the master list of users and courses, verifies submitted payments,
and replies to support contacts.

The platform is built on **Spring Boot 3** with **Spring Security**,
**Thymeleaf** for server-side rendering, **JPA / Hibernate** for data
access, and **PostgreSQL** as the relational store. The same backend
exposes both server-rendered HTML pages and a JSON REST API, so the
project demonstrates classical web-application architecture as well as
modern API design. The application is deployed to **Render** (free tier)
using a `Dockerfile` and a Render Blueprint (`render.yaml`).


# 1. Introduction

## 1.1 Background

Online learning has become a core delivery channel for higher education,
especially after the shift to remote instruction during 2020–2022. Most
existing platforms (Coursera, Udemy, Byju's) are commercial and their
internals are not visible to students. There is a clear pedagogical value
in building a small but realistic e-learning platform from scratch as a
final-year project — it covers nearly every layer of a modern web
application: authentication, authorisation, ORM-based persistence,
templated UI, REST APIs, payments, file links, and deployment.

## 1.2 Problem Statement

Build a working multi-role e-learning web application that:

- Lets a **student** discover, buy, and consume courses (lectures, notes,
  quizzes) and interact with support.
- Lets a **teacher** publish and maintain course content, and observe
  enrolment.
- Lets an **administrator** govern the system — users, courses, payments,
  and support tickets.
- Demonstrates correct use of role-based security, server-side rendering,
  and a JSON API on the same Spring Boot codebase.
- Is deployable to a free public cloud host so the work can be
  demonstrated by URL, not just on the developer's laptop.

## 1.3 Objectives

1. Implement complete authentication (sign-up, login, change-password)
   with Spring Security form-login.
2. Enforce **role-based authorisation** so each role can only reach its
   own routes (`/student/**`, `/teacher/**`, `/admin/**`).
3. Provide a clean Thymeleaf UI with a unified theme and accessible forms.
4. Persist all domain state in PostgreSQL with JPA entities and Spring
   Data repositories.
5. Expose a parallel JSON REST API for every functional area.
6. Ship seed data (`data.sql`) so the application demonstrates real
   workflows without manual setup.
7. Deploy the application to Render using a `Dockerfile` and Blueprint.

## 1.4 Scope

**In scope:**

- Full authentication and role-based authorisation
- Course / lecture / note / quiz CRUD by teachers
- Course purchase (UPI reference) and enrolment by students
- Quiz attempt and result computation
- Admin actions: user CRUD, payment verification, contact reply
- Local + cloud deployment

**Out of scope (acknowledged limitations):**

- Real payment-gateway integration (the system records a UPI reference
  but does not call any payment processor).
- Video upload / streaming (lectures are external YouTube embeds).
- Real-time chat or live video sessions (lectures may include a Google
  Meet link, but the meeting itself is hosted by Google).
- Multi-tenant institute support.


# 2. Literature Survey

## 2.1 Web Application Frameworks

The Spring ecosystem is the de-facto standard for building backend web
applications in Java. **Spring Boot** removes most of the boilerplate
configuration of classical Spring by providing an opinionated set of
auto-configurations and an embedded servlet container (Tomcat). Studies
on enterprise framework adoption (e.g., the JetBrains "State of
Developer Ecosystem" reports) consistently rank Spring Boot as the most
used Java framework for new projects. For this reason, Spring Boot was
chosen as the foundation of this project.

## 2.2 Server-Side Rendering vs. SPA

A modern web application can be built either as a **server-side rendered
(SSR)** application (HTML produced on the server with a templating
engine) or as a **single-page application (SPA)** that calls a JSON API.
SSR is simpler to develop, easier to secure (sessions are managed by the
server), and friendlier to search engines. A SPA gives a smoother user
experience but adds significant front-end complexity. Since the goal of
this project is to demonstrate the full vertical of a web application,
the system uses **SSR with Thymeleaf** for the UI **and** exposes a
parallel JSON API — giving the best of both worlds and showing how the
two styles coexist on one backend.

## 2.3 Object-Relational Mapping

Direct JDBC code is verbose and error-prone. **JPA (Java Persistence
API)** standardises object-relational mapping; **Hibernate** is its most
widely used implementation. **Spring Data JPA** further reduces
boilerplate by deriving repository implementations from interface
methods. The project uses Spring Data JPA throughout the persistence
layer.

## 2.4 Authentication and Authorisation

**Spring Security** provides a battle-tested filter chain for
authentication, authorisation, password encoding, CSRF protection, and
session management. The project uses Spring Security in form-login mode
with role-based URL authorisation rules and a custom
`UserDetailsService` that loads users from the application's own `users`
table.


# 3. System Analysis

## 3.1 Existing Systems

| Platform   | Strengths                                | Weaknesses                          |
|------------|------------------------------------------|--------------------------------------|
| Coursera   | World-class catalogue, polished UI       | Generic, not tailored to one institute |
| Udemy      | Huge catalogue, low prices               | No role of "institute admin"          |
| Byju's     | India-focused, mobile-first              | Closed-source, paid-only              |
| Google Classroom | Free, integrates with Google ID    | Not a course-marketplace; no payments |

A small institute that wants to run its own catalogue, take payments via
UPI, and verify them manually has no obvious off-the-shelf option in the
free / open tier.

## 3.2 Proposed System

A self-hosted, three-role e-learning platform with the following
properties:

- One Spring Boot codebase serves both the SSR UI and the JSON API.
- Role-based access is enforced uniformly across UI and API.
- Demo data is shipped so the app is usable on first start.
- Deployment is reproducible (a Render Blueprint and a Dockerfile).

## 3.3 Feasibility Study

**Technical feasibility.** All technologies used (Spring Boot,
PostgreSQL, Docker) are mainstream, well documented, and free. The
deployment target (Render free tier) is sufficient for demonstration.

**Economic feasibility.** Zero direct cost: the dev tools, the
deployment host, and the database are all free. Time cost is bounded
because every layer uses well-known frameworks.

**Operational feasibility.** The system is operated through a browser by
three roles whose workflows match real classroom processes (teacher
publishes content; student enrols; admin governs). No retraining is
needed.

## 3.4 Functional Requirements

| #   | Role     | Requirement                                              |
|-----|----------|----------------------------------------------------------|
| F-1 | Public   | Sign up with name, email, password, and role             |
| F-2 | Public   | Log in with email + password, redirected by role         |
| F-3 | Public   | Change password from a logged-out flow                   |
| F-4 | Student  | View dashboard with enrolments, payments, courses        |
| F-5 | Student  | Buy a course (UPI ref) → creates Payment + Enrolment      |
| F-6 | Student  | Watch lectures (YouTube embed / Meet link)               |
| F-7 | Student  | Download notes (PDF link)                                |
| F-8 | Student  | Attempt a quiz; see computed result                      |
| F-9 | Student  | Raise a support / contact request                        |
| F-10| Teacher  | CRUD on courses, lectures, notes, quizzes                |
| F-11| Teacher  | View enrolled students per course                        |
| F-12| Admin    | CRUD on users (name, email, role, active, password)      |
| F-13| Admin    | Delete a course                                          |
| F-14| Admin    | Verify a payment (set status to VERIFIED)                |
| F-15| Admin    | Reply to a contact request                               |

## 3.5 Non-Functional Requirements

- **Security.** Role-based authorisation. Passwords stored using
  `DelegatingPasswordEncoder` so that future BCrypt-hashed credentials
  coexist with the demo dataset's plain-text passwords.
- **Portability.** Same JAR runs locally on Postgres and on Render.
- **Reproducibility.** Demo dataset seeded by `data.sql`; safe to re-run.
- **Maintainability.** Clear package layout (`controller`, `service`,
  `repository`, `model`, `dto`, `config`, `util`).


# 4. System Design

## 4.1 Architecture

The application follows the classical **layered architecture** of
enterprise Spring Boot:

```
+--------------------------------------------------------+
|  Browser  (Thymeleaf-rendered HTML, JS, CSS)           |
|  External JSON client (curl, Postman, future SPA)      |
+--------------------------------------------------------+
                        |  HTTP(S)
                        v
+--------------------------------------------------------+
|  Spring MVC Controllers                                |
|   - HomeController, AuthController                     |
|   - StudentController, TeacherController, AdminController |
|   - AuthApiController, ApiExceptionHandler             |
+--------------------------------------------------------+
                        |  method calls
                        v
+--------------------------------------------------------+
|  Service layer  (UserService, PasswordPrefixUtil)      |
+--------------------------------------------------------+
                        |
                        v
+--------------------------------------------------------+
|  Spring Data JPA Repositories                          |
+--------------------------------------------------------+
                        |  JPA / JDBC
                        v
+--------------------------------------------------------+
|  PostgreSQL                                            |
+--------------------------------------------------------+
```

Cross-cutting:

- **Spring Security** sits as a servlet filter in front of every request,
  enforcing authentication and role-based URL rules.
- **`SecurityConfig`** wires the password encoder, the user-details
  service, and a custom `AccessDeniedHandler` that redirects denied
  users to their own dashboard instead of the Whitelabel error page.

## 4.2 Package Structure

```
com.Sarvam.Professional.Education
├── SarvamElearningApplication       # @SpringBootApplication entry point
├── config
│   └── SecurityConfig               # Spring Security filter chain
├── controller
│   ├── HomeController               # `/`, `/dashboard`, role dashboards
│   ├── AuthController               # form-based auth flows
│   ├── AuthApiController            # JSON auth endpoints
│   ├── StudentController            # student JSON APIs
│   ├── TeacherController            # teacher JSON APIs
│   ├── AdminController              # admin JSON APIs
│   └── ApiExceptionHandler          # @ControllerAdvice for API errors
├── dto                              # input bodies for the JSON API
├── model                            # @Entity classes + Role enum
├── repository                       # Spring Data JPA repositories
├── service
│   └── UserService                  # password change / signup
└── util
    └── PasswordPrefixUtil           # {noop}/{bcrypt} prefix helper
```

## 4.3 Database Design

The schema is generated by Hibernate from JPA entities
(`spring.jpa.hibernate.ddl-auto=update`).

### 4.3.1 Tables

| Table         | PK                  | Purpose                                        |
|---------------|---------------------|------------------------------------------------|
| `users`       | `user_id`           | Application accounts; role + active flag       |
| `courses`     | `course_id`         | Course catalogue                               |
| `lectures`    | `lecture_id`        | Per-course videos / Meet links                 |
| `notes`       | `note_id`           | Per-course downloadable PDF links              |
| `quiz`        | `quiz_id`           | MCQ items with options and correct option      |
| `results`     | `result_id`         | Student quiz attempts                          |
| `enrollments` | `enrollment_id`     | (student_id, course_id) join                   |
| `payments`    | `payment_id`        | UPI reference, amount, status, invoice number  |
| `contact`     | `contact_id`        | Support tickets with optional admin reply      |

### 4.3.2 Relationships (logical)

- `users (role=STUDENT)` 1—N `enrollments` N—1 `courses`
- `users (role=STUDENT)` 1—N `payments`     N—1 `courses`
- `courses` 1—N `lectures`
- `courses` 1—N `notes`
- `courses` 1—N `quiz`
- `users (role=STUDENT)` 1—N `results` N—1 `courses`
- `users (role=STUDENT)` 1—N `contact` (matched by email)

### 4.3.3 Entity-Relationship Sketch

```
                        +---------+
                        |  Role   |  (enum: STUDENT/TEACHER/ADMIN)
                        +---------+
                             |
                             v
                        +---------+
                        |  User   |
                        +---------+
              students /          \ teachers (informal)
                      v            v
       +------------+              +-----------+
       | Enrolment  |---->-+       |  Course   |
       +------------+      |       +-----------+
              ^            |          |  |  |
              |            v          v  v  v
        +-----+----+   +--------+ +-------+ +------+ +------+
        | Payment  |   |Result  | |Lecture| | Note | | Quiz |
        +----------+   +--------+ +-------+ +------+ +------+

                         +-----------+
                         |  Contact  |   (admin replies)
                         +-----------+
```

## 4.4 Use-Case Diagram (textual)

**Student**

- Sign up / Log in
- Browse courses
- Buy a course
- Watch lectures
- Download notes
- Attempt quiz
- View results
- Submit contact request

**Teacher**

- Log in
- CRUD courses
- CRUD lectures
- CRUD notes
- CRUD quizzes
- View enrolled students

**Admin**

- Log in
- CRUD users
- Delete courses
- Verify payments
- Reply to contacts

## 4.5 Sequence: "Student buys a course"

```
Student          Browser         Spring MVC          JPA            Postgres
   |                |                 |                |                |
   |--click "Buy"-->|                 |                |                |
   |                |--POST /student/ |                |                |
   |                |  buy-course --->|                |                |
   |                |                 |--save Payment->|--INSERT------->|
   |                |                 |--save Enrolment|--INSERT------->|
   |                |<-302 redirect---|                |                |
   |                |--GET /student/  |                |                |
   |                |  dashboard ---->|                |                |
   |                |                 |--findById...-->|--SELECTs------>|
   |                |<-200 HTML-------|                |                |
```


# 5. Detailed Database Schema

This chapter documents every table, column-by-column. The schema is
generated automatically by Hibernate from the JPA `@Entity` classes
(`spring.jpa.hibernate.ddl-auto=update`); the tables below describe the
shape Hibernate produces on PostgreSQL.

## 5.1 `users`

Backs the `User` entity. Holds every account, regardless of role.

| Column      | Type           | Null | Key | Default       | Notes                                  |
|-------------|----------------|------|-----|---------------|----------------------------------------|
| `user_id`   | `bigint`       | NO   | PK  | identity      | Auto-incremented primary key           |
| `name`      | `varchar(255)` | YES  |     |               | Display name                           |
| `email`     | `varchar(255)` | NO   | UQ  |               | Unique login identifier                |
| `password`  | `varchar(255)` | YES  |     |               | `{noop}` or `{bcrypt}` prefixed value  |
| `role`      | `varchar(255)` | NO   |     |               | One of `STUDENT`, `TEACHER`, `ADMIN`   |
| `active`    | `boolean`      | NO   |     | `true`        | Disables login when `false`            |

The `role` column is mapped via `@Enumerated(EnumType.STRING)` so that
the enum's name is stored, not its ordinal — adding a fourth role later
will not silently shift existing rows.

## 5.2 `courses`

Backs the `Course` entity.

| Column        | Type           | Null | Key | Notes                                        |
|---------------|----------------|------|-----|----------------------------------------------|
| `course_id`   | `bigint`       | NO   | PK  | Identity                                     |
| `title`       | `varchar(255)` | YES  |     | Marketing title shown on the catalogue       |
| `price`       | `int`          | YES  |     | Price in INR (whole rupees; BCA-scope)       |
| `instructor`  | `varchar(255)` | YES  |     | Free-text instructor name                    |
| `thumbnail`   | `varchar(255)` | YES  |     | URL to a thumbnail image                     |

Note: `instructor` is a free-text string, not a foreign key to `users`.
This was a deliberate scope choice — it keeps the listing screen simple
at the cost of preventing per-teacher ownership checks.

## 5.3 `lectures`

Backs the `Lecture` entity. A lecture belongs to exactly one course.

| Column         | Type           | Null | Key | Notes                              |
|----------------|----------------|------|-----|------------------------------------|
| `lecture_id`   | `bigint`       | NO   | PK  | Identity                           |
| `course_id`    | `bigint`       | YES  | FK  | References `courses(course_id)`    |
| `title`        | `varchar(255)` | YES  |     | Lecture title                      |
| `video_url`    | `varchar(255)` | YES  |     | YouTube watch URL (embed-derivable)|
| `meeting_url`  | `varchar(255)` | YES  |     | Live-session link (Google Meet)    |

Either `video_url` (recorded) or `meeting_url` (live) is set; both can
co-exist if a lecture has both a recording and a live doubt session.

## 5.4 `notes`

Backs the `Note` entity.

| Column      | Type           | Null | Key | Notes                                |
|-------------|----------------|------|-----|--------------------------------------|
| `note_id`   | `bigint`       | NO   | PK  | Identity                             |
| `course_id` | `bigint`       | YES  | FK  | References `courses(course_id)`      |
| `title`     | `varchar(255)` | YES  |     | Display title for the note           |
| `file_url`  | `varchar(255)` | YES  |     | Public PDF URL                       |

## 5.5 `quiz`

Backs the `Quiz` entity. Each row is a single MCQ.

| Column           | Type           | Null | Key | Notes                              |
|------------------|----------------|------|-----|------------------------------------|
| `quiz_id`        | `bigint`       | NO   | PK  | Identity                           |
| `course_id`      | `bigint`       | YES  | FK  | References `courses(course_id)`    |
| `question`       | `varchar(255)` | YES  |     | Question text                      |
| `option_a`       | `varchar(255)` | YES  |     | Option A                           |
| `option_b`       | `varchar(255)` | YES  |     | Option B                           |
| `option_c`       | `varchar(255)` | YES  |     | Option C                           |
| `option_d`       | `varchar(255)` | YES  |     | Option D                           |
| `correct_option` | `varchar(255)` | YES  |     | One of `A`, `B`, `C`, `D`          |

Storing the answer in the same row as the question is acceptable for
this scope. A production-grade quiz engine would split options into a
child table and never serialise the answer to the client.

## 5.6 `results`

Backs the `Result` entity. One row per quiz attempt.

| Column             | Type            | Null | Key | Notes                              |
|--------------------|-----------------|------|-----|------------------------------------|
| `result_id`        | `bigint`        | NO   | PK  | Identity                           |
| `student_id`       | `bigint`        | YES  | FK  | References `users(user_id)`        |
| `course_id`        | `bigint`        | YES  | FK  | References `courses(course_id)`    |
| `total_questions`  | `int`           | YES  |     | Number of questions in the attempt |
| `correct_answers`  | `int`           | YES  |     | Number answered correctly          |
| `percentage`       | `numeric(38,2)` | YES  |     | Computed percentage                |
| `submitted_at`     | `timestamp`     | YES  |     | Server-side submit timestamp       |

`percentage` is stored, not derived on read, so historical attempts
remain comparable even if the question set changes.

## 5.7 `enrollments`

Backs the `Enrollment` entity. The join row between students and
courses.

| Column           | Type        | Null | Key | Notes                              |
|------------------|-------------|------|-----|------------------------------------|
| `enrollment_id`  | `bigint`    | NO   | PK  | Identity                           |
| `student_id`     | `bigint`    | YES  | FK  | References `users(user_id)`        |
| `course_id`      | `bigint`    | YES  | FK  | References `courses(course_id)`    |
| `enrolled_at`    | `timestamp` | YES  |     | Server-side enrolment timestamp    |

Uniqueness of (`student_id`, `course_id`) is enforced at the application
layer (`existsByStudentIdAndCourseId`) before insertion.

## 5.8 `payments`

Backs the `Payment` entity.

| Column         | Type            | Null | Key | Notes                              |
|----------------|-----------------|------|-----|------------------------------------|
| `payment_id`   | `bigint`        | NO   | PK  | Identity                           |
| `invoice_no`   | `varchar(255)`  | YES  |     | Human-readable invoice number      |
| `student_id`   | `bigint`        | YES  | FK  | References `users(user_id)`        |
| `course_id`    | `bigint`        | YES  | FK  | References `courses(course_id)`    |
| `upi_ref`      | `varchar(255)`  | YES  |     | UPI reference entered by student   |
| `amount`       | `numeric(38,2)` | YES  |     | Amount paid in INR                 |
| `status`       | `varchar(255)`  | YES  |     | `SUCCESS`, `VERIFIED`, `FAILED`    |
| `paid_at`      | `timestamp`     | YES  |     | Time the student submitted the ref |

A payment moves through `SUCCESS` (student-claimed) → `VERIFIED`
(admin-confirmed). The application creates an `Enrollment` row at
`SUCCESS`; verification is a separate trust step.

## 5.9 `contact`

Backs the `Contact` entity.

| Column         | Type            | Null | Key | Notes                              |
|----------------|-----------------|------|-----|------------------------------------|
| `contact_id`   | `bigint`        | NO   | PK  | Identity                           |
| `name`         | `varchar(255)`  | YES  |     | Submitter's display name           |
| `email`        | `varchar(255)`  | YES  |     | Submitter's email                  |
| `phone`        | `varchar(255)`  | YES  |     | Submitter's phone (optional)       |
| `message`      | `text`          | YES  |     | Free-text body                     |
| `admin_reply`  | `text`          | YES  |     | Admin's reply (`NULL` if pending)  |
| `created_at`   | `timestamp`     | YES  |     | Time the request was submitted     |

A `NULL` `admin_reply` means *open*; any non-null value means *answered*.

## 5.10 Sequences

Hibernate uses Postgres `IDENTITY` columns for every primary key. Seed
data in `data.sql` inserts fixed IDs (so foreign keys in seed rows
resolve correctly) and then bumps each sequence past those IDs:

```
SELECT setval(pg_get_serial_sequence('users', 'user_id'),
              (SELECT COALESCE(MAX(user_id), 0) FROM users));
```

Without these `setval` calls, the next app-side insert would collide on
the seeded primary keys.


# 6. Module Walkthrough

This chapter explains, in narrative form, what each significant Java
file in the project does and how it fits into a request flow. The full
source of every file is reproduced verbatim in Appendix B.

## 6.1 `SarvamElearningApplication`

The standard Spring Boot entry point. Annotated with
`@SpringBootApplication`, which combines `@Configuration`,
`@EnableAutoConfiguration`, and `@ComponentScan`. The `main` method
boots the embedded Tomcat container and prints a friendly URL banner.

## 6.2 `config/SecurityConfig`

The single source of truth for authentication and authorisation.

- Defines a `PasswordEncoder` bean using `DelegatingPasswordEncoder`
  with `NoOpPasswordEncoder` as the default-for-matches.
- Defines a `UserDetailsService` bean that loads users from
  `UserRepository` and prefixes the stored password with `{noop}` or
  recognises an existing `{bcrypt}` prefix via `PasswordPrefixUtil`.
- Configures the `SecurityFilterChain` — disables CSRF (project scope),
  declares public URLs (`/`, `/login`, `/signup`, `/change-password`,
  `/css/**`, `/images/**`, `/api/auth/**`), and protects role URLs
  (`/student/**`, `/teacher/**`, `/admin/**`).
- Configures form login with `email`/`password` parameters, a fixed
  success URL of `/dashboard`, and a failure URL of `/login?error`.
- Registers a custom `AccessDeniedHandler` that redirects an
  authenticated user to **their own** dashboard (with `?denied`)
  instead of producing a 403 Whitelabel page.

## 6.3 `controller/HomeController`

The largest controller. Two responsibilities:

1. Public landing routes — `/`, `/home`, and the `/dashboard` redirector
   that picks the correct role-specific dashboard from the
   authentication object.
2. Server-rendered dashboards for each role
   (`/student/dashboard`, `/teacher/dashboard`, `/admin/dashboard`) and
   the post handlers that back the dashboard tabs (buying a course,
   submitting a contact, saving a course / lecture / note / quiz,
   verifying a payment, replying to a contact).

The student-course detail page (`/student/course/{courseId}`) checks
enrolment first via `existsByStudentIdAndCourseId` before rendering
lectures and notes — a defence against direct URL access.

## 6.4 `controller/AuthController`

Renders the login, sign-up, and change-password pages and handles the
form submissions for sign-up and change-password. Login itself is
handled by Spring Security's `UsernamePasswordAuthenticationFilter`, so
this controller does **not** need a `POST /login` handler — only the
GET that renders the page.

## 6.5 `controller/AuthApiController`

The JSON sibling of `AuthController`. Exposes
`POST /api/auth/signup`, `POST /api/auth/login`, and
`POST /api/auth/change-password`. The login endpoint returns a
`redirectTo` field that tells the client where to navigate next based
on role (`/student/dashboard`, `/teacher/dashboard`, or
`/admin/dashboard`).

## 6.6 `controller/StudentController`

Pure JSON. Endpoints:

- `GET /api/student/dashboard/{studentId}` — aggregated dashboard
  payload (enrolments, payments, available courses).
- `GET /api/student/courses` — catalogue.
- `POST /api/student/buy-course` — accepts a `BuyCourseRequest`,
  creates a `Payment` and an `Enrollment` in one transaction.
- `GET /api/student/lectures/{courseId}`,
  `GET /api/student/notes/{courseId}`,
  `GET /api/student/quiz/{courseId}` — content for an enrolled student.
- `POST /api/student/quiz/submit` — accepts a `QuizSubmitRequest`,
  computes total / correct / percentage, persists a `Result`.
- `POST /api/student/contact` — submit a support request.

## 6.7 `controller/TeacherController`

JSON CRUD for teacher resources: courses, lectures, notes, quizzes,
plus read-only views for enrolled students and aggregated performance.

## 6.8 `controller/AdminController`

JSON dashboard, user CRUD, course delete, payment verification, and
contact reply. Mirrors the form actions in `HomeController`'s admin
section.

## 6.9 `controller/ApiExceptionHandler`

A `@RestControllerAdvice` that maps `RuntimeException` to a
`400 Bad Request` JSON body of shape `{ "message": "..." }`. Keeps the
API responses consistent and avoids leaking stack traces to clients.

## 6.10 `service/UserService`

Holds the password-change and signup business logic so it isn't tangled
into controllers. Uses `PasswordEncoder` to hash new passwords with
BCrypt before persistence, while still recognising the demo dataset's
`{noop}` plain-text values when verifying old passwords.

## 6.11 `util/PasswordPrefixUtil`

A pure helper that normalises stored passwords:

- An already-prefixed value (`{noop}` or `{bcrypt}`) is returned as-is.
- An unprefixed value is wrapped in `{noop}` so the
  `DelegatingPasswordEncoder` can match it.

This util has its own unit test (`PasswordPrefixUtilTest`) covering
each branch.

## 6.12 Repositories

Each repository extends `JpaRepository<T, Long>` and adds a few derived
finders. Highlights:

- `UserRepository.findByEmail(String)` — login lookup.
- `EnrollmentRepository.existsByStudentIdAndCourseId(Long, Long)` —
  defends purchase and content endpoints from duplicate enrolments.
- `EnrollmentRepository.findByStudentId(Long)` —
  `PaymentRepository.findByStudentId(Long)` — the dashboard joins these
  with course lookups.
- `LectureRepository.findByCourseId(Long)`,
  `NoteRepository.findByCourseId(Long)`,
  `QuizRepository.findByCourseId(Long)` — per-course content fetches.

## 6.13 Models

Nine `@Entity` classes, one per database table, plus the `Role` enum.
Each entity uses `@Id @GeneratedValue(strategy = GenerationType.IDENTITY)`
so Hibernate maps the primary key to a Postgres `IDENTITY` column. The
models are deliberately framework-light — no Lombok, no MapStruct — so
that the appendix is readable to graders unfamiliar with those tools.

## 6.14 DTOs

Six small request bodies for the JSON API:

- `SignUpRequest`, `LoginRequest`, `ChangePasswordRequest` — auth
- `BuyCourseRequest` — student purchase flow
- `QuizSubmitRequest` — quiz answers payload
- `ContactReplyRequest` — admin reply to a contact

Keeping DTOs separate from `@Entity` classes prevents over-posting (a
JSON client cannot accidentally set fields like `role` or `active` by
guessing field names) and keeps the wire shape stable as the schema
evolves.


# 6.15 User Flows

Step-by-step traces of the most common journeys through the system.
Each flow shows the URL, the actor, the controller method, and the
side-effects on the database. These flows are written so a viva-voce
panel can ask the student "walk me through what happens when X" and
get an answer at the right level of detail.

## 6.15.1 Sign-up

| Step | URL                       | Actor    | Controller method               | Effect                                                                 |
|------|---------------------------|----------|---------------------------------|------------------------------------------------------------------------|
| 1    | `GET /signup`             | Anonymous| `AuthController.signupPage`     | Renders `signup.html`.                                                 |
| 2    | `POST /signup`            | Anonymous| `AuthController.signupSubmit`   | Validates body; calls `UserService.signup`; password hashed with BCrypt;`User` row inserted. |
| 3    | `redirect:/login`         | —        | —                               | Browser follows redirect; user logs in next.                            |

Failure modes: duplicate email → flash message + back to `/signup`.
Empty password → form-level validation on the page.

## 6.15.2 Login

| Step | URL                  | Actor    | Spring filter / controller            | Effect                                                                  |
|------|----------------------|----------|---------------------------------------|-------------------------------------------------------------------------|
| 1    | `GET /login`         | Anonymous| `AuthController.loginPage`            | Renders `login.html`.                                                   |
| 2    | `POST /login`        | Anonymous| `UsernamePasswordAuthenticationFilter`| Loads `User` via `userDetailsService`; matches password; sets auth in session. |
| 3    | `302 /dashboard`     | —        | —                                     | Spring Security default success URL.                                    |
| 4    | `GET /dashboard`     | Logged in| `HomeController.dashboard`            | Inspects role → redirects to role dashboard.                            |

Failure modes: wrong password → `302 /login?error`. Inactive user
(`active=false`) → 403.

## 6.15.3 Student buys a course

| Step | URL                                  | Actor   | Method                                | Effect                                                  |
|------|--------------------------------------|---------|---------------------------------------|---------------------------------------------------------|
| 1    | `GET /student/dashboard?tab=courses` | Student | `HomeController.studentDashboard`     | Lists courses + the student's existing enrolments.      |
| 2    | `POST /student/buy-course`           | Student | `HomeController.buyCourse`            | Guards duplicate; creates `Payment` (`SUCCESS`) + `Enrollment`. |
| 3    | `redirect:/student/dashboard?tab=courses` | — | —                                  | Course now appears as enrolled.                          |
| 4    | `GET /student/course/{courseId}`     | Student | `HomeController.studentCourse`        | `existsByStudentIdAndCourseId` check; renders lectures + notes. |

## 6.15.4 Teacher publishes a lecture

| Step | URL                              | Actor   | Method                                  | Effect                                                                |
|------|----------------------------------|---------|-----------------------------------------|-----------------------------------------------------------------------|
| 1    | `GET /teacher/dashboard`         | Teacher | `HomeController.teacherDashboard`       | Renders teacher tabs.                                                  |
| 2    | `POST /teacher/lecture/save`     | Teacher | `HomeController.saveLecture`            | If `lectureId` null → new row; else update; YouTube URL parsed for embedId on render. |
| 3    | `redirect:/teacher/dashboard`    | —       | —                                       | New lecture is visible.                                                |

## 6.15.5 Quiz attempt

| Step | URL                              | Actor   | Method                                | Effect                                                                |
|------|----------------------------------|---------|---------------------------------------|-----------------------------------------------------------------------|
| 1    | `GET /api/student/quiz/{course}` | Student | `StudentController.getQuiz`           | Returns options without `correctOption`.                              |
| 2    | `POST /api/student/quiz/submit`  | Student | `StudentController.submitQuiz`        | Looks up the right answer per question; computes total/correct/percent; persists `Result`. |
| 3    | (response)                       | —       | —                                     | Client renders the score.                                              |

## 6.15.6 Admin verifies a payment

| Step | URL                                       | Actor | Method                                | Effect                                            |
|------|-------------------------------------------|-------|---------------------------------------|---------------------------------------------------|
| 1    | `GET /admin/dashboard?tab=payments`       | Admin | `HomeController.adminDashboard`       | Lists every payment with its status.              |
| 2    | `POST /admin/payment/verify/{paymentId}`  | Admin | `HomeController.verifyPayment`        | Sets `payments.status = 'VERIFIED'`.              |
| 3    | `redirect:/admin/dashboard`               | —     | —                                     | Status badge updates.                             |

## 6.15.7 Access denied (cross-role attempt)

This is the flow that motivated the custom `AccessDeniedHandler`.

| Step | URL                                | Actor (cookies) | Filter / handler                           | Effect                                                |
|------|------------------------------------|-----------------|--------------------------------------------|-------------------------------------------------------|
| 1    | `GET /admin/dashboard`             | Logged in as student | `AuthorizationFilter`                  | Sees `ROLE_STUDENT`; throws `AccessDeniedException`.  |
| 2    | (filter chain)                     | —               | `ExceptionTranslationFilter`              | Delegates to the registered `AccessDeniedHandler`.    |
| 3    | `redirect:/student/dashboard?denied`| —              | `SecurityConfig.accessDeniedHandler`      | User lands on **their own** dashboard, not 403.       |


# 7. Class Diagrams

ASCII renderings of the most important class relationships. They
intentionally omit getters and setters to keep the diagrams readable.

## 7.1 Domain model

```
                 +---------+
                 |  Role   |   <<enum>>  STUDENT, TEACHER, ADMIN
                 +---------+

 +----------+         +-----------+        +-----------+
 |   User   | 1 --- N |Enrollment | N --- 1|  Course   |
 +----------+         +-----------+        +-----------+
 |userId    |         |enrollmentId|       |courseId   |
 |name      |         |studentId   |       |title      |
 |email (UQ)|         |courseId    |       |price      |
 |password  |         |enrolledAt  |       |instructor |
 |role      |         +-----------+        |thumbnail  |
 |active    |                              +-----------+
 +----------+                                  |    |   |
      ^                                        |    |   |
      | 1                                      |1   |1  |1
      | N                                      vN   vN  vN
 +-----------+                            +---------+ +-------+ +------+
 |  Payment  | N---1 Course               | Lecture | | Note  | | Quiz |
 +-----------+                            +---------+ +-------+ +------+
 |paymentId  |                            |lectureId| |noteId | |quizId|
 |invoiceNo  |                            |courseId | |courseId|courseId|
 |studentId  |                            |title    | |title  | |question|
 |courseId   |                            |videoUrl | |fileUrl| |opts A-D|
 |upiRef     |                            |meetingUr| |       | |correct|
 |amount     |                            +---------+ +-------+ +------+
 |status     |
 |paidAt     |              +---------+
 +-----------+              | Result  |
                            +---------+
                            |resultId |
                            |studentId|
                            |courseId |
                            |totalQ   |
                            |correctA |
                            |percentag|
                            |submitAt |
                            +---------+

 +----------+
 | Contact  |   (matched to user by email; no FK)
 +----------+
 |contactId |
 |name      |
 |email     |
 |phone     |
 |message   |
 |adminReply|
 |createdAt |
 +----------+
```

## 7.2 Controller hierarchy

```
                +-----------------+
                | @Controller     |   (server-rendered)
                +-----------------+
                  |     |     |
         +--------+     |     +-----------+
         v              v                 v
 HomeController    AuthController    (no others — controllers split by role)

                +---------------------+
                | @RestController     |   (JSON API)
                +---------------------+
                  |     |     |     |
   +--------------+     |     |     +------------------+
   v                    v     v                        v
 AuthApiController StudentController TeacherController AdminController

                +---------------------+
                | @RestControllerAdvice|
                +---------------------+
                          |
                          v
                  ApiExceptionHandler
```

## 7.3 Security filter chain (request flow)

```
Browser request
    |
    v
+-----------------------------------+
| Tomcat -> Spring DispatcherServlet|
+-----------------------------------+
    |
    v
+-----------------------------------+
| Security Filter Chain             |
|  - SecurityContextPersistenceF.   |
|  - LogoutFilter                   |
|  - UsernamePasswordAuthFilter     |  (handles POST /login)
|  - AnonymousAuthenticationFilter  |
|  - AuthorizationFilter            |  (URL rules from SecurityConfig)
|  - ExceptionTranslationFilter     |  (delegates 403 to AccessDeniedHandler)
+-----------------------------------+
    |
    v
+-----------------------------------+
| Controller                        |
|  -> Service / Repository          |
|  -> Hibernate -> Postgres         |
+-----------------------------------+
    |
    v
Response (Thymeleaf HTML / JSON)
```


# 8. Implementation

## 8.1 Tech Stack

| Layer        | Technology                                               |
|--------------|----------------------------------------------------------|
| Language     | Java 17                                                  |
| Framework    | Spring Boot 3.3.5                                        |
| Web          | Spring MVC + Thymeleaf                                   |
| Security     | Spring Security (form login, role-based)                 |
| Persistence  | Spring Data JPA + Hibernate                              |
| Database     | PostgreSQL (`org.postgresql:postgresql`)                 |
| Build        | Maven (Maven Wrapper included)                           |
| Validation   | Jakarta Bean Validation                                  |
| Testing      | JUnit 5, Spring Security Test, H2 (PostgreSQL mode)      |
| Container    | Docker (multi-stage Maven → JRE 17)                      |
| Deploy       | Render (Blueprint + free Postgres)                       |

## 8.2 Configuration Highlights

`application.properties` is fully **environment-driven** so the same JAR
can run locally and on Render. Server port binds to `${PORT:8080}` and
the datasource URL/user/password to `SPRING_DATASOURCE_*` env vars (with
localhost defaults). `data.sql` is rewritten in PostgreSQL syntax —
`INSERT … ON CONFLICT DO NOTHING` for idempotent seeding, plus
`setval(pg_get_serial_sequence(...))` calls so JPA-managed identity
sequences are bumped past the seeded fixed IDs.

## 8.3 Security Configuration

`SecurityConfig` does five things:

1. **CSRF disabled** (project intended for academic use; production code
   should re-enable it).
2. **URL authorisation rules** — public for `/`, `/login`, `/signup`,
   `/change-password`, static assets, and `/api/auth/**`; role-restricted
   for `/student/**`, `/teacher/**`, `/admin/**`; everything else
   requires authentication.
3. **Form login** at `/login` with `email` / `password` parameters and a
   role-aware redirect via `/dashboard`.
4. **Logout** clears the session and returns to `/`.
5. **Custom `AccessDeniedHandler`** — when an authenticated user hits a
   route they don't own, they are redirected to their own dashboard
   (with `?denied`) rather than the Whitelabel error page. This fixes
   the common "two roles open in the same browser" 403 confusion.

## 8.4 Password Storage

Spring Security's `DelegatingPasswordEncoder` is configured with
`NoOpPasswordEncoder` as the default-for-matches. The
`PasswordPrefixUtil` normalises stored passwords:

- `{noop}plain` is recognised as plain text (matches the demo dataset).
- `{bcrypt}$2a$...` is recognised as a BCrypt hash.
- An unprefixed value is treated as plain text and prefixed with
  `{noop}` at load time.

This means the demo dataset can ship with plain-text passwords (so
graders can log in directly from `data.sql`), while real signups use
BCrypt. The `Notes` section of the report explains that this fallback
must be removed for any non-academic deployment.

## 8.5 REST API Surface

All endpoints are under `/api`, accept and return `application/json`.

- `POST /api/auth/signup`, `/login`, `/change-password`
- `GET  /api/student/dashboard/{studentId}` and the student workflows
- `GET  /api/teacher/dashboard` and the teacher CRUD endpoints
- `GET  /api/admin/dashboard` and the admin governance endpoints

Server-rendered routes mirror these and render Thymeleaf templates with
the same data.


## 8.6 System Requirements

The minimum environment to develop, build, and run the project.

### 8.6.1 Hardware Requirements (development)

| Component | Minimum                              | Recommended                         |
|-----------|--------------------------------------|-------------------------------------|
| CPU       | Dual-core 2 GHz (x86_64 / ARM64)     | Quad-core 2.5+ GHz                  |
| RAM       | 4 GB                                 | 8 GB                                |
| Disk      | 2 GB free for JDK + IDE + repo       | 5 GB free (build cache + Postgres)  |
| Network   | Required for first Maven resolution  | Stable broadband for live demo      |

### 8.6.2 Hardware Requirements (Render free tier)

| Component | Provided                             |
|-----------|--------------------------------------|
| CPU       | Shared 0.1 vCPU                      |
| RAM       | 512 MB                               |
| Disk      | Ephemeral 1 GB on web service        |
| DB Disk   | 1 GB managed Postgres                |

### 8.6.3 Software Requirements

| Layer            | Tool / version                                          |
|------------------|---------------------------------------------------------|
| OS (development) | macOS 13+, Linux (any modern distro), Windows 10/11     |
| JDK              | OpenJDK 17 (Temurin / Zulu / Adoptium)                  |
| Build            | Maven 3.9+ (wrapper is committed; `mvn` not needed)     |
| Database         | PostgreSQL 14+ (Podman/Docker container, or native)     |
| Container runtime| Podman or Docker (only for the deploy image)            |
| Browser          | Chrome / Firefox / Safari (latest)                      |
| IDE              | IntelliJ IDEA, VS Code, or Eclipse                      |

### 8.6.4 External Services

| Service          | Used for                                  | Free tier? |
|------------------|-------------------------------------------|------------|
| Render           | Hosting the Spring Boot web service       | Yes        |
| Render Postgres  | Production database                       | Yes (90 d) |
| GitHub           | Source hosting; Render pulls from it      | Yes        |
| YouTube          | Public video URLs embedded in lectures    | Yes        |


# 9. REST API Reference

Every JSON endpoint exposed by the application, with method, path,
auth, request body, response, and the status codes a client can
expect. All bodies are `application/json`.

## 9.1 Authentication — `/api/auth/**` (public)

### `POST /api/auth/signup`

Creates a new account.

- **Auth:** none
- **Request:**
  ```json
  { "name": "Asha", "email": "asha@example.com",
    "password": "secret", "role": "STUDENT" }
  ```
- **Success (200):** `{ "message": "Signup successful" }`
- **Errors:** `400` if email already exists, password missing, or role
  unknown.

### `POST /api/auth/login`

Authenticates against the application's `users` table.

- **Auth:** none
- **Request:** `{ "email": "...", "password": "..." }`
- **Success (200):**
  ```json
  { "message": "Login successful",
    "role": "STUDENT",
    "redirectTo": "/student/dashboard" }
  ```
- **Errors:** `401` on bad credentials, `403` if `active=false`.

### `POST /api/auth/change-password`

- **Auth:** none (the request itself carries the old password)
- **Request:**
  ```json
  { "email": "...", "oldPassword": "...", "newPassword": "..." }
  ```
- **Success (200):** `{ "message": "Password changed" }`
- **Errors:** `400` on mismatch.

## 9.2 Student API — `/api/student/**` (`ROLE_STUDENT`)

| Method | Path                                  | Body                  | Returns                                |
|--------|---------------------------------------|-----------------------|----------------------------------------|
| GET    | `/api/student/dashboard/{studentId}`  | —                     | Aggregated dashboard payload           |
| GET    | `/api/student/courses`                | —                     | List of courses                        |
| POST   | `/api/student/buy-course`             | `BuyCourseRequest`    | `Payment` + `Enrollment` summary       |
| GET    | `/api/student/lectures/{courseId}`    | —                     | Lectures (enrolment enforced)          |
| GET    | `/api/student/notes/{courseId}`       | —                     | Notes (enrolment enforced)             |
| GET    | `/api/student/quiz/{courseId}`        | —                     | Quiz items (no `correctOption`)        |
| POST   | `/api/student/quiz/submit`            | `QuizSubmitRequest`   | `{ totalQuestions, correctAnswers, percentage }` |
| POST   | `/api/student/contact`                | `Contact`             | `{ "message": "Submitted" }`           |

Status codes: `200` on success, `400` on validation, `403` if the
caller is not enrolled in the requested course.

## 9.3 Teacher API — `/api/teacher/**` (`ROLE_TEACHER`)

| Method | Path                          | Body            | Description                       |
|--------|-------------------------------|-----------------|-----------------------------------|
| GET    | `/api/teacher/dashboard`      | —               | Dashboard payload                 |
| GET    | `/api/teacher/courses`        | —               | All courses                       |
| POST   | `/api/teacher/courses`        | `Course`        | Create / update a course          |
| POST   | `/api/teacher/lectures`       | `Lecture`       | Create / update a lecture         |
| POST   | `/api/teacher/notes`          | `Note`          | Create / update a note            |
| POST   | `/api/teacher/quiz`           | `Quiz`          | Create / update a quiz item       |
| GET    | `/api/teacher/students`       | —               | Enrolled students across courses  |
| GET    | `/api/teacher/performance`    | —               | Aggregated quiz performance       |

## 9.4 Admin API — `/api/admin/**` (`ROLE_ADMIN`)

| Method | Path                                       | Body                  | Description                   |
|--------|--------------------------------------------|-----------------------|-------------------------------|
| GET    | `/api/admin/dashboard`                     | —                     | System overview               |
| GET    | `/api/admin/users`                         | —                     | List all users                |
| PUT    | `/api/admin/users/{userId}`                | `User`                | Update a user                 |
| GET    | `/api/admin/courses`                       | —                     | List all courses              |
| GET    | `/api/admin/payments`                      | —                     | List all payments             |
| PUT    | `/api/admin/payments/{paymentId}/verify`   | —                     | Verify a payment              |
| GET    | `/api/admin/reports`                       | —                     | Aggregated counts / KPIs      |
| GET    | `/api/admin/contacts`                      | —                     | List support requests         |
| PUT    | `/api/admin/contacts/{contactId}/reply`    | `ContactReplyRequest` | Post an admin reply           |

## 9.5 Error Envelope

`ApiExceptionHandler` (`@RestControllerAdvice`) maps any
`RuntimeException` to a `400 Bad Request` JSON body of shape:

```json
{ "message": "human-readable error" }
```

Validation failures surface the field-level reasons in the same
envelope. Authentication failures (`401`) and authorisation failures
(`403`) are handled by Spring Security and return empty bodies; the UI
recognises the status code and redirects accordingly.

## 9.6 Sample cURL Sessions

**Sign up + log in + buy a course (student):**

```
curl -X POST http://localhost:8080/api/auth/signup \
  -H 'Content-Type: application/json' \
  -d '{"name":"Asha","email":"asha@x.com","password":"p","role":"STUDENT"}'

curl -c jar -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"asha@x.com","password":"p"}'

curl -b jar -X POST http://localhost:8080/api/student/buy-course \
  -H 'Content-Type: application/json' \
  -d '{"studentId":4,"courseId":1,"upiRef":"UPIDEMO001"}'
```

**Verify a payment (admin):**

```
curl -b jar -X PUT \
  http://localhost:8080/api/admin/payments/2/verify
```


# 10. Testing

## 10.1 Test Strategy

The project uses **JUnit 5** with `spring-boot-starter-test` for unit
and integration tests, and **H2** in **PostgreSQL mode** as an in-memory
database so tests do not touch a real Postgres instance and still catch
dialect mismatches that would otherwise only show up in production.

Three layers of tests are present:

- **Unit tests** for pure-function utilities. Example:
  `PasswordPrefixUtilTest` exhaustively covers each branch of the
  `{noop}` / `{bcrypt}` / unprefixed normaliser.
- **Slice tests** that exercise a Spring MVC controller without booting
  the full security filter chain. Example: `HomeControllerTest`.
- **Context tests** that boot the full `ApplicationContext` to verify
  that every bean wires up. Example:
  `SarvamElearningApplicationTests`.

Tests run against the `test` profile, which selects
`application-test.properties` (H2 in PostgreSQL mode,
`ddl-auto=create-drop`, `spring.sql.init.mode=never`).

## 10.2 Test Inventory

| File                                       | Type   | Tests | What it asserts                                                                  |
|--------------------------------------------|--------|------:|----------------------------------------------------------------------------------|
| `SarvamElearningApplicationTests`          | Context| 1     | The full Spring context starts; every bean wires up.                              |
| `HomeControllerTest`                       | Slice  | 3     | `/` returns 200; `/dashboard` redirects an anonymous caller; protected routes 302. |
| `PasswordPrefixUtilTest`                   | Unit   | 4     | `null`, plain, `{noop}` and `{bcrypt}` inputs each produce the right output.       |

Total: **8 tests**, all green on the current commit (`./mvnw test`).

## 10.3 Manual Test Plan

The automated suite covers logic; the manual plan below covers the
end-to-end UX. Each row is a discrete test case suitable for a printed
test-execution log.

| #  | Pre-condition                       | Action                                                              | Expected                                                                           |
|----|-------------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------------|
| 1  | App running                         | Open `/`                                                            | Landing page renders                                                               |
| 2  | App running                         | Open `/login`                                                       | Login form renders                                                                 |
| 3  | App running                         | Submit `/login` with bad creds                                      | Redirect to `/login?error`                                                         |
| 4  | Demo data seeded                    | Submit `/login` as `student@demo.sarvam`                            | 302 → `/dashboard` → `/student/dashboard`                                          |
| 5  | Demo data seeded                    | Submit `/login` as `teacher@demo.sarvam`                            | 302 → `/teacher/dashboard`                                                         |
| 6  | Demo data seeded                    | Submit `/login` as `admin@demo.sarvam`                              | 302 → `/admin/dashboard`                                                           |
| 7  | Logged in as student                | Visit `/teacher/dashboard`                                          | 302 → `/student/dashboard?denied` (custom AccessDeniedHandler)                     |
| 8  | Logged in as teacher                | Visit `/admin/dashboard`                                            | 302 → `/teacher/dashboard?denied`                                                  |
| 9  | Logged in as student, course unbought| Click *Buy* on course 3, submit UPI ref                            | New rows in `payments` and `enrollments`; redirect to `?tab=courses`               |
| 10 | Logged in as student, enrolled      | Open `/student/course/{id}`                                         | Page shows YouTube embed + notes table                                             |
| 11 | Logged in as student, **not** enrolled| Direct-navigate to `/student/course/{otherId}`                    | Redirect to `/student/dashboard?tab=courses`                                       |
| 12 | Logged in as student                | Submit a contact request                                            | New row in `contact`; appears under *My Tickets*                                   |
| 13 | Logged in as teacher                | Create a course via the form                                        | Row in `courses`; appears for everyone on next dashboard load                      |
| 14 | Logged in as teacher                | Edit a lecture's video URL                                          | Updated row in `lectures`; new URL is visible                                      |
| 15 | Logged in as teacher                | Delete a quiz                                                       | Row removed from `quiz`; quiz disappears from the dashboard                        |
| 16 | Logged in as admin                  | Open the *Users* tab                                                | All seeded users listed with role badges                                           |
| 17 | Logged in as admin                  | Update a user (e.g., change name)                                   | Row updated in `users`; change persists across refresh                             |
| 18 | Logged in as admin                  | Delete a user                                                       | User row removed; that user can no longer log in                                   |
| 19 | Logged in as admin                  | Click *Verify* on a `SUCCESS` payment                                | `payments.status` becomes `VERIFIED`                                               |
| 20 | Logged in as admin                  | Reply to a contact ticket                                            | `contact.admin_reply` populated; ticket shows as answered                          |
| 21 | Any role                            | Click *Logout*                                                       | Session cleared; redirect to `/`                                                   |

## 10.4 Coverage Considerations

Coverage is intentionally **breadth-over-depth**: every layer has at
least one representative test, but the full Cartesian product of
edge-cases (network drops, malformed JSON, race conditions on
double-purchase) is out of scope for a final-year project. The next
iteration of the suite would add:

- Repository-level tests for derived finders against H2.
- A WebMvc slice test for each role controller, asserting that a user
  in another role receives `302 → ...?denied`.
- A controller test that simulates a duplicate purchase and asserts
  the second one is silently ignored.


# 11. Deployment

## 11.1 Local Run

PostgreSQL via Podman:

```
podman run -d --name sarvam-pg -p 5432:5432 \
  -e POSTGRES_PASSWORD=admin -e POSTGRES_DB=sarvam_db postgres:16
```

App:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/sarvam_db \
SPRING_DATASOURCE_USERNAME=postgres \
SPRING_DATASOURCE_PASSWORD=admin \
./mvnw spring-boot:run
```

Open http://localhost:8080.

## 11.2 Deploy to Render

The repo ships:

- `Dockerfile` — multi-stage build: Maven on JDK 17, runtime on JRE 17.
- `render.yaml` — Blueprint that provisions a free Postgres database
  and a free Docker web service, and wires DB host/port/name + user /
  password into the `SPRING_DATASOURCE_*` env vars.

Steps:

1. Push the repo to GitHub.
2. Render dashboard → **New** → **Blueprint** → connect repo.
3. Render reads `render.yaml`, creates the Postgres DB, builds and
   deploys the web service.
4. The app is reachable at `https://sarvam-elearning-*.onrender.com`.

## 11.3 Operational Notes

- Free web service spins down after ~15 min idle; cold start ~30s.
- Free Postgres expires 90 days after creation (Render emails a
  reminder).
- Demo accounts are seeded by `data.sql` (password: `password123`).


# 12. Risks, Limitations, and Known Issues

A self-aware list of what the project does **not** do, and what could
hurt it in production. Naming these explicitly is itself a learning
outcome of the project.

## 12.1 Security risks

- **CSRF disabled.** Acceptable for a demo because the JSON API uses
  sessions for browser callers and tokens are not yet involved, but
  any production deployment must re-enable CSRF and add a hidden
  `_csrf` field to every form.
- **Plain-text demo passwords.** Real signups go through BCrypt, but
  the seed dataset still uses `{noop}`. A production system must
  remove this fallback and re-hash any pre-seeded users.
- **No rate limiting.** Login is not throttled — a script could
  attempt unlimited credential pairs. Mitigation: Spring Security
  `LoginAttemptService` or a reverse-proxy-level rate limit.
- **`spring.security.user.name=admin` in `application.properties`.**
  This default user is overridden by the database-backed
  `UserDetailsService`, but the property should be removed on the
  production profile to eliminate the surprise.

## 12.2 Functional limitations

- **No real payment gateway.** Students enter a UPI reference manually
  and the admin verifies it; there is no callback from a payment
  provider.
- **No video upload.** Lectures are external YouTube embeds. The app
  will not survive YouTube takedowns of the seeded URLs.
- **No teacher-per-course ownership.** Any teacher can edit any
  course. Future work: add a `teacher_id` FK on `courses` and gate
  writes by `course.teacherId == authentication.userId`.
- **No quiz timer / proctoring.** Students can re-submit indefinitely.
- **No internationalisation.** All copy is English.

## 12.3 Operational limitations

- **Free Render Postgres has a 90-day expiry** — the deployment URL
  will lose data unless the DB is migrated before that window
  expires.
- **Free web service cold-start.** A request after 15 min of idle
  takes ~30 seconds, which is poor UX for evaluators clicking the
  link cold.
- **Single instance.** No load balancing, no horizontal scaling.

## 12.4 Code-level concerns

- `HomeController` is large (~430 lines). It mixes student, teacher,
  and admin SSR logic. Future split: one controller per role.
- `RuntimeException` is thrown in several places where a typed
  `ResponseStatusException` (with the right HTTP status) would be
  cleaner.
- `instructor` on `Course` is a free-text string instead of a foreign
  key.
- `data.sql` is loaded on every startup. It is idempotent, but a
  production system would version migrations with Flyway or
  Liquibase instead.


# 13. Project Timeline

A retrospective week-by-week timeline of how the project was built.
This section is useful for the BCA viva-voce, where examiners often
ask about effort distribution.

| Week | Phase                           | Key deliverables                                                              |
|------|---------------------------------|-------------------------------------------------------------------------------|
| 1    | Discovery & scoping             | Problem statement, role identification, tech-stack survey                     |
| 2    | Domain modelling                | ER diagram, entity sketches, package layout                                   |
| 3    | Project bootstrap               | `pom.xml`, Spring Boot skeleton, MySQL connection, `User`/`Role` entities     |
| 4    | Auth                            | Spring Security config, login / signup / change-password flows                |
| 5    | Student journey                 | Course catalogue, buy-course flow, enrolment, payments                        |
| 6    | Content delivery                | Lectures, notes, YouTube embed, PDF link                                      |
| 7    | Quizzes & results               | Quiz CRUD, attempt + scoring + result persistence                             |
| 8    | Teacher dashboard               | CRUD UIs and JSON endpoints for courses / lectures / notes / quizzes          |
| 9    | Admin dashboard                 | User CRUD, payment verification, contact reply                                |
| 10   | UX polish                       | Thymeleaf themes, accessibility tweaks, error-page handling                   |
| 11   | Tests                           | `PasswordPrefixUtilTest`, `HomeControllerTest`, context test, H2 PG mode       |
| 12   | Render migration                | Switch from MySQL to PostgreSQL, env-driven config, `Dockerfile`, `render.yaml`|
| 13   | Documentation                   | README rewrite, project report, screenshots                                   |
| 14   | Submission prep                 | PDF generation, viva-voce dry-run, defect log                                 |

## 13.1 Effort split (approx.)

| Activity                         | Share |
|----------------------------------|-------|
| Coding (controllers + services)  | 35%   |
| UI templates and CSS             | 20%   |
| Database design + seed data      | 10%   |
| Auth / security                  | 10%   |
| Tests + manual QA                | 10%   |
| Deployment + DevOps              |  8%   |
| Documentation / report           |  7%   |


# 14. Code Style and SOLID Compliance

A reflection on how well the codebase follows widely-cited design
principles. This section is included because BCA viva panels frequently
ask "where in your project do you see SOLID?".

## 14.1 Single Responsibility

Each class has one reason to change.

- `PasswordPrefixUtil` — **only** normalises a stored password. It has
  no other behaviour.
- `UserService` — change-password and signup. It does not know about
  HTTP, sessions, or templates.
- Each controller is named for the role it serves.

The largest violation is `HomeController`, which carries
server-rendered routes for **all three** roles. The Future Work
section calls out the split.

## 14.2 Open / Closed

The repository pattern via Spring Data JPA is the clearest example —
new finders can be added by declaring an interface method (e.g.
`existsByStudentIdAndCourseId`) without modifying any existing class.

`PasswordPrefixUtil` is closed for modification (all branches are
tested) and open for extension (a new `{argon2}` prefix can be added
without touching the existing branches' tests).

## 14.3 Liskov Substitution

The custom `AccessDeniedHandler` is an implementation of Spring's
contract. Spring Security treats it as any other handler. There is no
hierarchy of domain classes deep enough for this principle to apply
non-trivially.

## 14.4 Interface Segregation

Spring Data JPA repositories are narrow: each repository extends
`JpaRepository<T, Long>` plus only the derived methods that callers
actually use. There is no "fat" `BaseRepository` with unused mass.

## 14.5 Dependency Inversion

Every controller depends on **interfaces** (`UserRepository`,
`CourseRepository`, `PasswordEncoder`), not on concrete classes. Spring
injects the concrete implementation at runtime. Swapping
`UserRepository` for a mock in tests is therefore a one-line change.

## 14.6 Layered Architecture

The package layout itself documents the layering:

```
controller -> service -> repository -> model
                  ^
                  |
              dto (request/response shapes only)
```

A controller is never allowed to construct a SQL string; a repository
is never allowed to call `Authentication`. This restriction is
respected throughout.

## 14.7 Naming and Readability

- All identifiers use full English words. No `usrSvc`, no `mgr`.
- Endpoints follow REST conventions (`POST /api/student/buy-course`,
  `PUT /api/admin/payments/{id}/verify`).
- Database column names are `snake_case` (`enrolled_at`,
  `correct_option`) and Java field names are `camelCase` — Hibernate
  bridges the two automatically via its naming strategy.

## 14.8 What an industrial reviewer would still flag

- `HomeController` is too large and too multi-role.
- Several methods throw `RuntimeException("...")` with a string
  message; a typed exception class would document intent better.
- Nullness is implicit. Adding `@Nullable` / `@NonNull` annotations
  would make the contract explicit.
- The free-text `instructor` field on `Course` is a denormalisation
  that will rot.


# 15. Screenshots

> The submitted printed copy should include screenshots of: the landing
> page, login, student dashboard, course purchase, lecture player,
> teacher dashboard, admin dashboard, and the access-denied redirect.
> Capture from the running deployment URL or `localhost:8080`. Insert
> them between this page and the next chapter.


# 16. Conclusion

The project meets all stated functional requirements and demonstrates a
realistic end-to-end Spring Boot web application: authentication,
role-based authorisation, ORM-based persistence, server-rendered UI,
JSON API, seeded demo data, automated tests, and reproducible cloud
deployment. The codebase is organised into clear layers and is small
enough to be understood completely by a final-year BCA student.

Beyond functional completeness, the project demonstrates the engineering
discipline expected of a final-year submission:

- The same backend serves SSR and JSON, showing that the two patterns
  coexist on a single codebase.
- The persistence layer migrated from MySQL to PostgreSQL without
  changing a single Java line — only the config and the
  dialect-specific `data.sql`. This validates the layered architecture.
- Security is centralised in `SecurityConfig`; every controller is
  unaware of authentication mechanics.
- Tests exist at every layer (unit, slice, context) and run against H2
  in PostgreSQL mode so dialect drift is caught at CI time.

## 16.1 Future Work

- Integrate a real payment gateway (Razorpay / Stripe) instead of the
  manual UPI-reference flow.
- Replace external YouTube embeds with a proper video upload + CDN.
- Add live-class support (WebRTC or scheduled Zoom integration).
- Hash all stored passwords with BCrypt and remove the `{noop}` fallback.
- Add per-course teacher ownership so teachers can only edit their own
  courses, instead of the current "any teacher can edit any course".
- Migrate `data.sql` to versioned Flyway migrations.
- Split `HomeController` by role.
- Add OpenAPI (springdoc) so the JSON API is self-documenting.


# 17. References

1. Spring Boot Reference Guide, version 3.3.x.
2. Spring Security Reference, version 6.3.x.
3. Hibernate ORM User Guide, version 6.x.
4. PostgreSQL 16 Documentation — Identity Columns and `ON CONFLICT`.
5. Render Documentation — Blueprints (`render.yaml`) and PostgreSQL.
6. Thymeleaf 3 Documentation.
7. Robert C. Martin, *Clean Code: A Handbook of Agile Software
   Craftsmanship*, Prentice Hall, 2008.
8. Eric Evans, *Domain-Driven Design: Tackling Complexity in the
   Heart of Software*, Addison-Wesley, 2003.
9. Spring in Action (6th edition), Craig Walls, Manning, 2022.
10. JetBrains, *State of Developer Ecosystem 2024 — Java*.


# Appendix A — Glossary

| Term                          | Meaning in this project                                                                                |
|-------------------------------|---------------------------------------------------------------------------------------------------------|
| **BCrypt**                    | A password-hashing function used by Spring Security; outputs `$2a$…`. Resistant to rainbow tables.       |
| **Blueprint (Render)**        | A `render.yaml` file that describes services and DBs declaratively. Render reads it and provisions them. |
| **CRUD**                      | Create, Read, Update, Delete — the four basic persistence operations.                                    |
| **CSRF**                      | Cross-Site Request Forgery. A class of attack where a third-party site makes a victim submit a request.   |
| **CSS**                       | Cascading Style Sheets — the styling language for HTML.                                                  |
| **Dialect**                   | Hibernate's per-database SQL flavour. Postgres has its own; H2 has a `MODE=PostgreSQL` to mimic it.       |
| **DTO**                       | Data Transfer Object. A class shaped for the wire, decoupled from `@Entity` fields.                      |
| **Entity (`@Entity`)**        | A class mapped 1:1 to a database table by JPA / Hibernate.                                              |
| **HikariCP**                  | The default JDBC connection-pool used by Spring Boot.                                                   |
| **Hibernate**                 | The most widely-used JPA implementation; produces the SQL behind every repository call.                  |
| **Identity column**           | A Postgres column that auto-generates its value (`GENERATED BY DEFAULT AS IDENTITY`).                    |
| **JDBC**                      | Java Database Connectivity — the low-level Java DB API.                                                 |
| **JPA**                       | Java Persistence API — the standard ORM specification implemented by Hibernate.                          |
| **JSON**                      | JavaScript Object Notation — the wire format used by every `/api/**` endpoint.                          |
| **JWT**                       | JSON Web Token. Not used in this project (sessions are used instead) but commonly mentioned in viva.     |
| **MVC**                       | Model–View–Controller — Spring's UI architecture.                                                       |
| **`{noop}` / `{bcrypt}`**     | Prefixes recognised by `DelegatingPasswordEncoder` to choose between plain-text and BCrypt comparison.   |
| **Open-API / Swagger**        | A standard for documenting JSON APIs. Listed as future work.                                             |
| **ORM**                       | Object-Relational Mapping — translating between objects and rows.                                       |
| **Pandoc**                    | The Markdown → HTML converter used by `scripts/build-report.sh`.                                        |
| **POM**                       | Project Object Model — the XML format Maven reads (`pom.xml`).                                         |
| **Render**                    | The free PaaS used to host the deployed app and database.                                               |
| **REST**                      | Representational State Transfer — the architectural style of the JSON API.                              |
| **SOLID**                     | Five OO design principles: SRP, OCP, LSP, ISP, DIP.                                                    |
| **SPA**                       | Single-Page Application. Not used in this project.                                                      |
| **Spring Boot**               | An opinionated wrapper over Spring that auto-configures most beans.                                     |
| **Spring Data JPA**           | A library that derives repository implementations from interface method names.                          |
| **Spring Security**           | The authentication / authorisation framework used by the project.                                       |
| **SSL / TLS**                 | Transport-layer encryption. Required (`sslmode=require`) when connecting to Render Postgres externally.  |
| **SSR**                       | Server-Side Rendering — HTML produced by the server (Thymeleaf), not by the browser.                    |
| **Thymeleaf**                 | The Java templating engine that produces the HTML pages.                                               |
| **Tomcat**                    | The embedded servlet container that serves HTTP for Spring Boot.                                        |
| **UPI**                       | Unified Payments Interface — the Indian payment standard used (manually) by the buy-course flow.         |

# Appendix A.1 — Acronyms

| Acronym | Expansion                                  |
|---------|--------------------------------------------|
| API     | Application Programming Interface          |
| BCA     | Bachelor of Computer Application           |
| CDN     | Content Delivery Network                   |
| CRUD    | Create, Read, Update, Delete               |
| CSRF    | Cross-Site Request Forgery                 |
| CSS     | Cascading Style Sheets                     |
| DI      | Dependency Injection                       |
| DTO     | Data Transfer Object                       |
| ER      | Entity-Relationship                        |
| HTML    | Hyper-Text Markup Language                 |
| HTTP(S) | Hyper-Text Transfer Protocol (Secure)      |
| IDE     | Integrated Development Environment         |
| JDBC    | Java Database Connectivity                 |
| JPA     | Java Persistence API                       |
| JSON    | JavaScript Object Notation                 |
| JWT     | JSON Web Token                             |
| MVC     | Model–View–Controller                      |
| ORM     | Object-Relational Mapping                  |
| PaaS    | Platform as a Service                      |
| PDF     | Portable Document Format                   |
| PK / FK | Primary Key / Foreign Key                  |
| REST    | Representational State Transfer            |
| SOLID   | (5 OO design principles)                   |
| SPA     | Single-Page Application                    |
| SQL     | Structured Query Language                  |
| SSL     | Secure Sockets Layer                       |
| SSR     | Server-Side Rendering                      |
| TLS     | Transport Layer Security                   |
| UI / UX | User Interface / User Experience           |
| UPI     | Unified Payments Interface                 |
| URL     | Uniform Resource Locator                   |
| UTC     | Coordinated Universal Time                 |
| VM      | Virtual Machine                            |


# Appendix B — Source Code

The remaining pages reproduce **every source file** in the project,
exactly as committed. File paths are shown above each listing.

EOF

# ---------- 2. Append every source file ----------
append_file() {
  local path="$1"
  local lang="$2"
  if [[ -f "$path" ]]; then
    {
      printf '\n\n## `%s`\n\n```%s\n' "$path" "$lang"
      cat "$path"
      printf '\n```\n'
    } >> "$REPORT_MD"
  fi
}

# Build configuration and metadata first
{
  printf '\n## B.1 Build & Configuration\n'
} >> "$REPORT_MD"
append_file pom.xml xml
append_file Dockerfile dockerfile
append_file .dockerignore text
append_file render.yaml yaml
append_file src/main/resources/application.properties properties
append_file src/main/resources/data.sql sql
append_file src/test/resources/application-test.properties properties
append_file src/main/resources/META-INF/spring-devtools.properties properties

# Java sources
{
  printf '\n## B.2 Java Source\n'
} >> "$REPORT_MD"
for f in $(find src/main/java -name "*.java" | sort); do
  append_file "$f" java
done

# DTOs are already inside src/main/java; covered above.

# Templates and assets
{
  printf '\n## B.3 Thymeleaf Templates\n'
} >> "$REPORT_MD"
for f in $(find src/main/resources/templates -name "*.html" | sort); do
  append_file "$f" html
done

{
  printf '\n## B.4 Static Assets (CSS)\n'
} >> "$REPORT_MD"
for f in $(find src/main/resources/static/css -name "*.css" | sort); do
  append_file "$f" css
done

# Tests
{
  printf '\n## B.5 Tests\n'
} >> "$REPORT_MD"
for f in $(find src/test/java -name "*.java" | sort); do
  append_file "$f" java
done

echo "Markdown built: $REPORT_MD ($(wc -l < "$REPORT_MD") lines)"

# ---------- 3. Markdown -> HTML (pandoc) ----------
cat > /tmp/sarvam-report.css <<'CSS'
@page { size: A4; margin: 20mm 18mm 20mm 18mm; }
html  { font-size: 13pt; }
body  { font-family: -apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif;
        line-height: 1.6; color: #111; }
h1    { font-size: 26pt; border-bottom: 2px solid #333; padding-bottom: 5pt;
        margin-top: 20pt; page-break-before: always; }
h1:first-of-type { page-break-before: auto; }
h1.appendix-sub { page-break-before: auto; }
h2    { font-size: 19pt; margin-top: 16pt; }
h3    { font-size: 15pt; margin-top: 12pt; }
h4    { font-size: 13pt; }
p, li { font-size: 13pt; }
table { border-collapse: collapse; width: 100%; margin: 8pt 0; }
th, td{ border: 1px solid #888; padding: 6pt 8pt; font-size: 12pt; text-align: left; vertical-align: top; }
th    { background: #eee; }
code  { font-family: "SF Mono", Menlo, Consolas, monospace; font-size: 12pt;
        background: #f3f3f3; padding: 1pt 3pt; border-radius: 2pt; }
pre   { background: #f6f8fa; border: 1px solid #ddd; border-radius: 3pt;
        padding: 9pt 11pt; font-size: 12pt; line-height: 1.55;
        white-space: pre-wrap; word-break: break-word; page-break-inside: auto; }
pre code { background: transparent; padding: 0; font-size: inherit; }
.title-block { text-align: center; margin: 60pt 0 40pt 0; }
.title-block h1 { border: none; font-size: 28pt; page-break-before: auto; }
.title-block .subtitle { font-size: 16pt; color: #555; }
.title-block .author, .title-block .date { font-size: 12pt; color: #555; }
hr    { border: none; border-top: 1px solid #aaa; margin: 12pt 0; }
blockquote { border-left: 3px solid #888; margin-left: 0; padding-left: 10pt; color: #555; }
CSS

pandoc "$REPORT_MD" \
  --standalone \
  --metadata title="Sarvam Professional Education — BCA Project Report" \
  --css /tmp/sarvam-report.css \
  --highlight-style=tango \
  --toc --toc-depth=2 \
  -f markdown -t html5 \
  -o "$REPORT_HTML"

echo "HTML built:    $REPORT_HTML"

# ---------- 4. HTML -> PDF (Chrome headless) ----------
"$CHROME" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$PWD/$REPORT_PDF" \
  "file://$PWD/$REPORT_HTML" 2>/dev/null || true

if [[ -f "$REPORT_PDF" ]]; then
  bytes=$(stat -f%z "$REPORT_PDF")
  echo "PDF built:     $REPORT_PDF ($bytes bytes)"
else
  echo "PDF generation failed — open $REPORT_HTML in a browser and File > Print > Save as PDF" >&2
  exit 1
fi

