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


## B.1 Build & Configuration


## `pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>
    <groupId>com.sarvam</groupId>
    <artifactId>sarvam-elearning</artifactId>
    <version>1.0</version>
    <name>Sarvam Professional Education</name>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.5</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <!-- Core Spring Boot -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-thymeleaf</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- DevTools & Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>false</filtering>
                <includes>
                    <include>**/*</include>
                </includes>
            </resource>
        </resources>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```


## `src/main/resources/application.properties`

```properties
# ================================================
# SARVAM PROFESSIONAL EDUCATION
# Application Properties
# ================================================
spring.application.name=Sarvam Professional Education
# ====================== SERVER ======================
server.port=8080
server.servlet.context-path=/
# ====================== DATABASE (MySQL) ======================
spring.datasource.url=jdbc:mysql://localhost:3306/sarvam_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=root1234
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
# ====================== JPA & HIBERNATE ======================
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
spring.jpa.properties.hibernate.format_sql=false
logging.level.org.hibernate=WARN
logging.level.org.hibernate.SQL=OFF
logging.level.org.hibernate.orm.jdbc.bind=OFF
logging.level.org.hibernate.stat=OFF
# ====================== THYMELEAF ======================
spring.thymeleaf.prefix=classpath:/templates/
spring.thymeleaf.suffix=.html
spring.thymeleaf.mode=HTML
spring.thymeleaf.cache=false
spring.thymeleaf.check-template-location=true
# DevTools restart classloader can make templates "missing" in the IDE; keep off unless you need hot restart
spring.devtools.restart.enabled=false
# ====================== STATIC RESOURCES ======================
spring.web.resources.static-locations=classpath:/static/
# ====================== SECURITY ======================
spring.security.user.name=admin
spring.security.user.password=admin123
# ====================== LOGGING ======================
logging.level.root=INFO
logging.level.com.sarvam=DEBUG
# ====================== UPLOAD SETTINGS (Future use ke liye) ======================
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
# ====================== DEMO DATA (classpath:data.sql) ======================
# Runs after JPA creates/updates tables. INSERT IGNORE = safe on every startup.
spring.jpa.defer-datasource-initialization=true
spring.sql.init.mode=always
spring.sql.init.encoding=UTF-8
# ====================== PROJECT INFO ======================
project.version=1.0
project.developer=Sudhir
project.year=2026

```


## `src/main/resources/data.sql`

```sql
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
INSERT
IGNORE INTO users (user_id, name, email, password, role, active) VALUES
  (1, 'Admin Demo', 'admin@demo.sarvam', 'password123', 'ADMIN', 1),
  (2, 'Priya Sharma', 'teacher@demo.sarvam', 'password123', 'TEACHER', 1),
  (3, 'Rahul Verma', 'student@demo.sarvam', 'password123', 'STUDENT', 1);

-- -----------------------------------------------------------------------------
-- Courses (3 available; student enrolls in 2, leaves 1 for "Buy" testing)
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO courses (course_id, title, price, instructor, thumbnail) VALUES
  (1, 'Web Development Fundamentals', 499, 'Priya Sharma', NULL),
  (2, 'Database Systems with MySQL', 599, 'Priya Sharma', NULL),
  (3, 'Data Structures & Algorithms', 799, 'Priya Sharma', NULL);

-- -----------------------------------------------------------------------------
-- Enrollments — student id 3 in courses 1 and 2
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO enrollments (enrollment_id, student_id, course_id, enrolled_at) VALUES
  (1, 3, 1, '2026-01-10 10:30:00'),
  (2, 3, 2, '2026-01-14 15:00:00');

-- -----------------------------------------------------------------------------
-- Payments — UPI refs + invoices (matches enrollments; course 3 unpaid)
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO payments (payment_id, invoice_no, student_id, course_id, upi_ref, amount, status, paid_at) VALUES
  (1, 'INV-DEMO0001', 3, 1, 'UPIREFWEB499001', 499.00, 'VERIFIED', '2026-01-10 10:31:00'),
  (2, 'INV-DEMO0002', 3, 2, 'UPIREFDB599002', 599.00, 'SUCCESS', '2026-01-14 15:02:00');

-- -----------------------------------------------------------------------------
-- Lectures — public YouTube videos (freeCodeCamp / Programming with Mosh)
-- One lecture per seeded course (ids 1, 2, 3) so the demo works end-to-end.
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO lectures (lecture_id, course_id, title, video_url, meeting_url) VALUES
  (1, 1, 'HTML Full Course - Build a Website Tutorial', 'https://www.youtube.com/watch?v=pQN-pnXPaVg', NULL),
  (2, 1, 'Live doubt session (week 1)', NULL, 'https://meet.google.com/demo-week1-sarvam'),
  (3, 2, 'MySQL Tutorial for Beginners', 'https://www.youtube.com/watch?v=7S_tz1z_5bA', NULL),
  (4, 3, 'Data Structures Easy to Advanced Course', 'https://www.youtube.com/watch?v=RBSGKlAvoiM', NULL);

-- -----------------------------------------------------------------------------
-- Notes — downloadable file URLs (stable Mozilla-hosted PDFs)
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO notes (note_id, course_id, title, file_url) VALUES
  (1, 1, 'Week 1 — HTML cheat sheet', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf'),
  (2, 1, 'CSS layout checklist', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf'),
  (3, 2, 'SQL basics handout', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf'),
  (4, 3, 'Big-O cheat sheet', 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf');

-- -----------------------------------------------------------------------------
-- Quiz — one sample question (columns match Quiz @Column snake_case names)
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO `quiz` (`quiz_id`, `course_id`, `question`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`) VALUES
  (1, 1, 'What does HTML stand for?', 'Hyper Text Markup Language', 'High Tech Modern Language', 'Home Tool Markup Language', 'Hyperlinks Text Mark Language', 'A');

-- -----------------------------------------------------------------------------
-- Contact / support — one pending, one answered
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO contact (contact_id, name, email, phone, message, admin_reply, created_at) VALUES
  (1, 'Rahul Verma', 'student@demo.sarvam', '9876500000', 'When is the next live session for Web Dev?', 'Tuesday 6 PM IST. Link is in Lecture 2.', '2026-01-12 09:00:00'),
  (2, 'Rahul Verma', 'student@demo.sarvam', '9876500000', 'Can I get an invoice copy for tax?', NULL, '2026-01-18 11:20:00');

-- -----------------------------------------------------------------------------
-- Quiz result — sample attempt for student on course 1
-- -----------------------------------------------------------------------------
INSERT
IGNORE INTO results (result_id, student_id, course_id, total_questions, correct_answers, percentage, submitted_at) VALUES
  (1, 3, 1, 1, 1, 100.00, '2026-01-16 18:45:00');

```


## `src/test/resources/application-test.properties`

```properties
# Test profile — uses in-memory H2 so tests do not touch local MySQL.
spring.datasource.url=jdbc:h2:mem:sarvam_test;MODE=MySQL;DB_CLOSE_DELAY=-1
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect
# data.sql uses INSERT IGNORE (MySQL-specific) — skip it in tests
spring.sql.init.mode=never

```


## `src/main/resources/META-INF/spring-devtools.properties`

```properties
# Disable full application restart; avoids missing Thymeleaf templates on some IDE class loaders.
# LiveReload for static assets still works when enabled in the browser extension.
restart.enabled=false

```

## B.2 Java Source


## `src/main/java/com/Sarvam/Professional/Education/SarvamElearningApplication.java`

```java
package com.Sarvam.Professional.Education;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SarvamElearningApplication {

    public static void main(String[] args) {
        SpringApplication.run(SarvamElearningApplication.class, args);

        System.out.println("=====================================");
        System.out.println("✅ Sarvam Professional Education Started Successfully!");
        System.out.println("🌐 Open Browser → http://localhost:8080");
    }
}
```


## `src/main/java/com/Sarvam/Professional/Education/config/SecurityConfig.java`

```java
package com.Sarvam.Professional.Education.config;

import com.Sarvam.Professional.Education.repository.UserRepository;
import com.Sarvam.Professional.Education.util.PasswordPrefixUtil;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final UserRepository userRepository;

    public SecurityConfig(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        PasswordEncoder delegating = PasswordEncoderFactories.createDelegatingPasswordEncoder();
        if (delegating instanceof org.springframework.security.crypto.password.DelegatingPasswordEncoder dpe) {
            dpe.setDefaultPasswordEncoderForMatches(NoOpPasswordEncoder.getInstance());
        }
        return delegating;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/", "/login", "/signup", "/change-password", "/css/**", "/images/**")
                        .permitAll()
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/student/**").hasRole("STUDENT")
                        .requestMatchers("/teacher/**").hasRole("TEACHER")
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )
                .formLogin(form -> form
                        .loginPage("/login")
                        .loginProcessingUrl("/login")
                        .usernameParameter("email")
                        .passwordParameter("password")
                        .defaultSuccessUrl("/dashboard", true)
                        .failureUrl("/login?error")
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutSuccessUrl("/")
                        .permitAll()
                )
                .exceptionHandling(ex -> ex.accessDeniedHandler(accessDeniedHandler()));

        return http.build();
    }

    @Bean
    public AccessDeniedHandler accessDeniedHandler() {
        return (request, response, accessDeniedException) -> {
            if (request.getUserPrincipal() == null) {
                response.sendRedirect(request.getContextPath() + "/login");
                return;
            }
            boolean isAdmin = request.isUserInRole("ADMIN");
            boolean isTeacher = request.isUserInRole("TEACHER");
            String target = isAdmin ? "/admin/dashboard"
                    : isTeacher ? "/teacher/dashboard"
                    : "/student/dashboard";
            response.sendRedirect(request.getContextPath() + target + "?denied");
        };
    }

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> userRepository.findByEmail(username)
                .map(user -> User.withUsername(user.getEmail())
                        .password(PasswordPrefixUtil.normalize(user.getPassword()))
                        .roles(user.getRole().name())
                        .build())
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }
}
```


## `src/main/java/com/Sarvam/Professional/Education/controller/AdminController.java`

```java
package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.dto.ContactReplyRequest;
import com.Sarvam.Professional.Education.model.Contact;
import com.Sarvam.Professional.Education.model.Course;
import com.Sarvam.Professional.Education.model.Payment;
import com.Sarvam.Professional.Education.model.User;
import com.Sarvam.Professional.Education.repository.ContactRepository;
import com.Sarvam.Professional.Education.repository.CourseRepository;
import com.Sarvam.Professional.Education.repository.PaymentRepository;
import com.Sarvam.Professional.Education.repository.UserRepository;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final PaymentRepository paymentRepository;
    private final ContactRepository contactRepository;

    public AdminController(
            UserRepository userRepository,
            CourseRepository courseRepository,
            PaymentRepository paymentRepository,
            ContactRepository contactRepository
    ) {
        this.userRepository = userRepository;
        this.courseRepository = courseRepository;
        this.paymentRepository = paymentRepository;
        this.contactRepository = contactRepository;
    }

    @GetMapping("/dashboard")
    public String dashboard() {
        return "Admin Dashboard";
    }

    @GetMapping("/users")
    public List<User> users() {
        return userRepository.findAll();
    }

    @PutMapping("/users/{userId}")
    public User updateUser(@PathVariable Long userId, @RequestBody User payload) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found"));
        user.setName(payload.getName());
        user.setRole(payload.getRole());
        user.setActive(payload.isActive());
        return userRepository.save(user);
    }

    @GetMapping("/courses")
    public List<Course> courses() {
        return courseRepository.findAll();
    }

    @GetMapping("/payments")
    public List<Payment> payments() {
        return paymentRepository.findAll();
    }

    @PutMapping("/payments/{paymentId}/verify")
    public Payment verifyPayment(@PathVariable Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId).orElseThrow(() -> new RuntimeException("Payment not found"));
        payment.setStatus("VERIFIED");
        return paymentRepository.save(payment);
    }

    @GetMapping("/reports")
    public Map<String, Long> reports() {
        return Map.of(
                "totalUsers", userRepository.count(),
                "totalCourses", courseRepository.count(),
                "totalPayments", paymentRepository.count(),
                "totalContacts", contactRepository.count()
        );
    }

    @GetMapping("/contacts")
    public List<Contact> contacts() {
        return contactRepository.findAll();
    }

    @PutMapping("/contacts/{contactId}/reply")
    public Contact reply(@PathVariable Long contactId, @RequestBody ContactReplyRequest request) {
        Contact contact = contactRepository.findById(contactId).orElseThrow(() -> new RuntimeException("Message not found"));
        contact.setAdminReply(request.adminReply);
        return contactRepository.save(contact);
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/controller/ApiExceptionHandler.java`

```java
package com.Sarvam.Professional.Education.controller;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", ex.getMessage()));
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/controller/AuthApiController.java`

```java
package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.dto.ChangePasswordRequest;
import com.Sarvam.Professional.Education.dto.LoginRequest;
import com.Sarvam.Professional.Education.dto.SignUpRequest;
import com.Sarvam.Professional.Education.model.Role;
import com.Sarvam.Professional.Education.model.User;
import com.Sarvam.Professional.Education.repository.UserRepository;
import com.Sarvam.Professional.Education.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthApiController {

    private final UserRepository userRepository;
    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;

    public AuthApiController(
            UserRepository userRepository,
            UserService userService,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager
    ) {
        this.userRepository = userRepository;
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
    }

    @PostMapping("/signup")
    public ResponseEntity<Map<String, Object>> signUp(@RequestBody SignUpRequest req) {
        if (req.email == null || req.email.isBlank() || req.password == null || req.password.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Email and password are required."));
        }
        if (userRepository.findByEmail(req.email.trim()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Email already registered."));
        }
        User user = new User();
        user.setName(req.name != null ? req.name.trim() : "User");
        user.setEmail(req.email.trim());
        user.setPassword(passwordEncoder.encode(req.password));
        user.setRole(parseRole(req.role));
        user.setActive(true);
        userRepository.save(user);
        return ResponseEntity.ok(Map.of("success", true, "message", "Registration successful."));
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(
            @RequestBody LoginRequest req,
            HttpServletRequest request,
            HttpServletResponse response
    ) {
        if (req.email == null || req.password == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Email and password are required."));
        }
        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.email.trim(), req.password));
            SecurityContextHolder.getContext().setAuthentication(auth);
            new HttpSessionSecurityContextRepository().saveContext(SecurityContextHolder.getContext(), request, response);

            User user = userRepository.findByEmail(req.email.trim())
                    .orElseThrow(() -> new IllegalStateException("User missing after login."));
            String redirectTo = switch (user.getRole()) {
                case STUDENT -> "/student/dashboard";
                case TEACHER -> "/teacher/dashboard";
                case ADMIN -> "/admin/dashboard";
            };
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "role", user.getRole().name(),
                    "redirectTo", redirectTo,
                    "name", user.getName()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Invalid email or password."));
        }
    }

    @PostMapping("/change-password")
    public ResponseEntity<Map<String, Object>> changePassword(@RequestBody ChangePasswordRequest req) {
        if (req.email == null || req.oldPassword == null || req.newPassword == null) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Email, old password, and new password are required."));
        }
        try {
            userService.changePassword(req.email.trim(), req.oldPassword, req.newPassword);
            return ResponseEntity.ok(Map.of("success", true, "message", "Password updated."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    private static Role parseRole(String role) {
        if (role == null || role.isBlank()) {
            return Role.STUDENT;
        }
        try {
            return Role.valueOf(role.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return Role.STUDENT;
        }
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/controller/AuthController.java`

```java
package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.model.User;
import com.Sarvam.Professional.Education.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class AuthController {

    @Autowired
    private UserService userService;

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @GetMapping("/signup")
    public String signupPage(Model model) {
        model.addAttribute("user", new User());
        return "signup";
    }

    @PostMapping("/signup")
    public String registerUser(@ModelAttribute User user) {
        User savedUser = userService.saveUser(user);
        System.out.println("Registered new user: " + savedUser.toString());
        return "redirect:/login?registered";
    }

    @GetMapping("/change-password")
    public String changePasswordPage() {
        return "change-password";
    }

    @PostMapping("/change-password")
    public String changePasswordSubmit(
            @RequestParam String email,
            @RequestParam String currentPassword,
            @RequestParam String newPassword,
            org.springframework.web.servlet.mvc.support.RedirectAttributes redirectAttributes
    ) {
        try {
            userService.changePassword(email.trim(), currentPassword, newPassword);
            redirectAttributes.addFlashAttribute("passwordSuccess", true);
            return "redirect:/login";
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("passwordError", e.getMessage());
            return "redirect:/change-password";
        }
    }
}
```


## `src/main/java/com/Sarvam/Professional/Education/controller/HomeController.java`

```java
package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.model.Contact;
import com.Sarvam.Professional.Education.model.Course;
import com.Sarvam.Professional.Education.model.Enrollment;
import com.Sarvam.Professional.Education.model.Lecture;
import com.Sarvam.Professional.Education.model.Note;
import com.Sarvam.Professional.Education.model.Payment;
import com.Sarvam.Professional.Education.model.Quiz;
import com.Sarvam.Professional.Education.model.Role;
import com.Sarvam.Professional.Education.model.User;
import com.Sarvam.Professional.Education.repository.ContactRepository;
import com.Sarvam.Professional.Education.repository.CourseRepository;
import com.Sarvam.Professional.Education.repository.EnrollmentRepository;
import com.Sarvam.Professional.Education.repository.LectureRepository;
import com.Sarvam.Professional.Education.repository.NoteRepository;
import com.Sarvam.Professional.Education.repository.PaymentRepository;
import com.Sarvam.Professional.Education.repository.QuizRepository;
import com.Sarvam.Professional.Education.repository.UserRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class HomeController {

    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final LectureRepository lectureRepository;
    private final NoteRepository noteRepository;
    private final QuizRepository quizRepository;
    private final PaymentRepository paymentRepository;
    private final ContactRepository contactRepository;
    private final PasswordEncoder passwordEncoder;

    public HomeController(
            UserRepository userRepository,
            CourseRepository courseRepository,
            EnrollmentRepository enrollmentRepository,
            LectureRepository lectureRepository,
            NoteRepository noteRepository,
            QuizRepository quizRepository,
            PaymentRepository paymentRepository,
            ContactRepository contactRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.courseRepository = courseRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.lectureRepository = lectureRepository;
        this.noteRepository = noteRepository;
        this.quizRepository = quizRepository;
        this.paymentRepository = paymentRepository;
        this.contactRepository = contactRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/home")
    public String home() {
        return "index";
    }

    /**
     * Enrolled students: watch lectures (YouTube embed or link) and download notes.
     */
    @GetMapping("/student/course/{courseId}")
    public String studentCourse(@PathVariable Long courseId, Authentication authentication, Model model) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Student not found"));
        if (!enrollmentRepository.existsByStudentIdAndCourseId(user.getUserId(), courseId)) {
            return "redirect:/student/dashboard?tab=courses";
        }
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        List<Lecture> lectures = lectureRepository.findByCourseId(courseId);
        List<Note> notes = noteRepository.findByCourseId(courseId);

        List<Map<String, Object>> lectureRows = new ArrayList<>();
        for (Lecture l : lectures) {
            Map<String, Object> row = new HashMap<>();
            row.put("title", l.getTitle());
            row.put("videoUrl", l.getVideoUrl());
            row.put("meetingUrl", l.getMeetingUrl());
            row.put("youtubeEmbedId", extractYoutubeEmbedId(l.getVideoUrl()));
            lectureRows.add(row);
        }

        model.addAttribute("course", course);
        model.addAttribute("lectureRows", lectureRows);
        model.addAttribute("notes", notes);
        model.addAttribute("displayName", user.getName());
        return "student-course";
    }

    private static String extractYoutubeEmbedId(String url) {
        if (url == null || url.isBlank()) {
            return null;
        }
        Matcher m = Pattern.compile("(?:youtube\\.com/watch\\?v=|youtu\\.be/|youtube\\.com/embed/)([\\w-]{11})")
                .matcher(url.trim());
        return m.find() ? m.group(1) : null;
    }

    @GetMapping("/dashboard")
    public String dashboard(Authentication authentication) {
        if (authentication == null) {
            return "redirect:/login";
        }
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) {
            return "redirect:/admin/dashboard";
        }

        boolean isTeacher = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_TEACHER"));
        if (isTeacher) {
            return "redirect:/teacher/dashboard";
        }

        return "redirect:/student/dashboard";
    }

    @GetMapping("/student/dashboard")
    public String studentDashboard(Authentication authentication,
                                   @RequestParam(defaultValue = "overview") String tab,
                                   Model model) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email).orElse(null);
        List<Course> courses = courseRepository.findAll();

        int enrolledCount = 0;
        List<Enrollment> myEnrollments = List.of();
        List<Payment> myPayments = List.of();
        List<Contact> myContacts = List.of();
        String displayName = "Student";
        String roleBadge = "STUDENT";
        Long studentId = null;
        if (user != null) {
            displayName = user.getName();
            roleBadge = user.getRole().name();
            studentId = user.getUserId();
            myEnrollments = enrollmentRepository.findByStudentId(user.getUserId());
            enrolledCount = myEnrollments.size();
            myPayments = paymentRepository.findByStudentId(user.getUserId());
            myContacts = contactRepository.findAll().stream()
                    .filter(c -> c.getEmail() != null && c.getEmail().equalsIgnoreCase(user.getEmail()))
                    .toList();
        }

        int hoursLearned = enrolledCount == 0 ? 24 : enrolledCount * 12;
        Map<Long, String> courseTitles = new HashMap<>();
        for (Course c : courses) {
            courseTitles.put(c.getCourseId(), c.getTitle());
        }
        model.addAttribute("courseTitles", courseTitles);
        model.addAttribute("displayName", displayName);
        model.addAttribute("roleBadge", roleBadge);
        model.addAttribute("studentId", studentId);
        model.addAttribute("enrolledCount", enrolledCount);
        model.addAttribute("hoursLearned", hoursLearned);
        model.addAttribute("currentStreak", 7);
        model.addAttribute("courses", courses);
        model.addAttribute("myEnrollments", myEnrollments);
        model.addAttribute("myPayments", myPayments);
        model.addAttribute("myContacts", myContacts);
        model.addAttribute("contactForm", new Contact());
        model.addAttribute("activeTab", tab);
        return "student-dashboard";
    }

    @PostMapping("/student/buy-course")
    public String buyCourse(Authentication authentication,
                            @RequestParam Long courseId,
                            @RequestParam String upiRef) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Student not found"));
        if (enrollmentRepository.existsByStudentIdAndCourseId(user.getUserId(), courseId)) {
            return "redirect:/student/dashboard";
        }

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        Payment payment = new Payment();
        payment.setStudentId(user.getUserId());
        payment.setCourseId(courseId);
        payment.setAmount(course.getPrice());
        payment.setUpiRef(upiRef);
        payment.setStatus("SUCCESS");
        payment.setPaidAt(LocalDateTime.now());
        paymentRepository.save(payment);

        Enrollment enrollment = new Enrollment();
        enrollment.setStudentId(user.getUserId());
        enrollment.setCourseId(courseId);
        enrollment.setEnrolledAt(LocalDateTime.now());
        enrollmentRepository.save(enrollment);
        return "redirect:/student/dashboard?tab=courses";
    }

    @PostMapping("/student/contact")
    public String submitContact(Authentication authentication, @ModelAttribute Contact contact) {
        User user = userRepository.findByEmail(authentication.getName()).orElse(null);
        if (user != null) {
            if (contact.getName() == null || contact.getName().isBlank()) {
                contact.setName(user.getName());
            }
            if (contact.getEmail() == null || contact.getEmail().isBlank()) {
                contact.setEmail(user.getEmail());
            }
        }
        contact.setCreatedAt(LocalDateTime.now());
        contactRepository.save(contact);
        return "redirect:/student/dashboard?tab=support";
    }

    @GetMapping("/teacher/dashboard")
    public String teacherDashboard(Authentication authentication,
                                   @RequestParam(defaultValue = "overview") String tab,
                                   Model model) {
        User teacher = userRepository.findByEmail(authentication.getName()).orElse(null);
        model.addAttribute("displayName", teacher != null ? teacher.getName() : "Teacher");
        model.addAttribute("roleBadge", "TEACHER");
        model.addAttribute("courses", courseRepository.findAll());
        model.addAttribute("lectures", lectureRepository.findAll());
        model.addAttribute("notes", noteRepository.findAll());
        model.addAttribute("quizzes", quizRepository.findAll());
        model.addAttribute("students", enrollmentRepository.findAll());
        model.addAttribute("courseForm", new Course());
        model.addAttribute("lectureForm", new Lecture());
        model.addAttribute("noteForm", new Note());
        model.addAttribute("quizForm", new Quiz());
        model.addAttribute("activeTab", tab);
        return "teacher-dashboard";
    }

    @PostMapping("/teacher/course/save")
    public String saveCourse(@RequestParam(required = false) Long courseId,
                             @RequestParam String title,
                             @RequestParam int price,
                             @RequestParam String instructor,
                             @RequestParam(required = false) String thumbnail) {
        Course course = courseId == null
                ? new Course()
                : courseRepository.findById(courseId).orElse(new Course());
        course.setTitle(title);
        course.setPrice(price);
        course.setInstructor(instructor);
        course.setThumbnail(thumbnail);
        courseRepository.save(course);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/course/delete/{courseId}")
    public String deleteCourse(@PathVariable Long courseId) {
        courseRepository.deleteById(courseId);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/lecture/save")
    public String saveLecture(@RequestParam(required = false) Long lectureId,
                              @RequestParam Long courseId,
                              @RequestParam String title,
                              @RequestParam(required = false) String videoUrl,
                              @RequestParam(required = false) String meetingUrl) {
        Lecture lecture = lectureId == null
                ? new Lecture()
                : lectureRepository.findById(lectureId).orElse(new Lecture());
        lecture.setCourseId(courseId);
        lecture.setTitle(title);
        lecture.setVideoUrl(videoUrl);
        lecture.setMeetingUrl(meetingUrl);
        lectureRepository.save(lecture);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/lecture/delete/{lectureId}")
    public String deleteLecture(@PathVariable Long lectureId) {
        lectureRepository.deleteById(lectureId);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/note/save")
    public String saveNote(@RequestParam(required = false) Long noteId,
                           @RequestParam Long courseId,
                           @RequestParam String title,
                           @RequestParam String fileUrl) {
        Note note = noteId == null ? new Note() : noteRepository.findById(noteId).orElse(new Note());
        note.setCourseId(courseId);
        note.setTitle(title);
        note.setFileUrl(fileUrl);
        noteRepository.save(note);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/note/delete/{noteId}")
    public String deleteNote(@PathVariable Long noteId) {
        noteRepository.deleteById(noteId);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/quiz/save")
    public String saveQuiz(@RequestParam(required = false) Long quizId,
                           @RequestParam Long courseId,
                           @RequestParam String question,
                           @RequestParam String optionA,
                           @RequestParam String optionB,
                           @RequestParam String optionC,
                           @RequestParam String optionD,
                           @RequestParam String correctOption) {
        Quiz quiz = quizId == null ? new Quiz() : quizRepository.findById(quizId).orElse(new Quiz());
        quiz.setCourseId(courseId);
        quiz.setQuestion(question);
        quiz.setOptionA(optionA);
        quiz.setOptionB(optionB);
        quiz.setOptionC(optionC);
        quiz.setOptionD(optionD);
        quiz.setCorrectOption(correctOption);
        quizRepository.save(quiz);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/quiz/delete/{quizId}")
    public String deleteQuiz(@PathVariable Long quizId) {
        quizRepository.deleteById(quizId);
        return "redirect:/teacher/dashboard";
    }

    @GetMapping("/admin/dashboard")
    public String adminDashboard(Authentication authentication,
                                 @RequestParam(defaultValue = "overview") String tab,
                                 Model model) {
        String displayName = "Admin";
        if (authentication != null) {
            String email = authentication.getName();
            User user = userRepository.findByEmail(email).orElse(null);
            if (user != null) {
                displayName = user.getName();
            }
        }
        model.addAttribute("displayName", displayName);
        model.addAttribute("roleBadge", "ADMIN");
        model.addAttribute("totalUsers", userRepository.count());
        model.addAttribute("totalCourses", courseRepository.count());
        model.addAttribute("totalPayments", paymentRepository.count());
        model.addAttribute("totalContacts", contactRepository.count());
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("courses", courseRepository.findAll());
        model.addAttribute("payments", paymentRepository.findAll());
        model.addAttribute("contacts", contactRepository.findAll());
        model.addAttribute("roles", Role.values());
        model.addAttribute("userForm", new User());
        model.addAttribute("activeTab", tab);
        return "admin-dashboard";
    }

    @PostMapping("/admin/user/save")
    public String saveUser(@RequestParam(required = false) Long userId,
                           @RequestParam String name,
                           @RequestParam String email,
                           @RequestParam Role role,
                           @RequestParam(defaultValue = "true") boolean active,
                           @RequestParam(required = false) String password) {
        User user = userId == null ? new User() : userRepository.findById(userId).orElse(new User());
        user.setName(name);
        user.setEmail(email);
        user.setRole(role);
        user.setActive(active);
        if (userId == null) {
            String rawPassword = (password == null || password.isBlank()) ? "123456" : password;
            user.setPassword(passwordEncoder.encode(rawPassword));
        } else if (password != null && !password.isBlank()) {
            user.setPassword(passwordEncoder.encode(password));
        }
        userRepository.save(user);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/user/delete/{userId}")
    public String deleteUser(@PathVariable Long userId) {
        userRepository.deleteById(userId);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/course/delete/{courseId}")
    public String adminDeleteCourse(@PathVariable Long courseId) {
        courseRepository.deleteById(courseId);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/payment/verify/{paymentId}")
    public String verifyPayment(@PathVariable Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId).orElseThrow(() -> new RuntimeException("Payment not found"));
        payment.setStatus("VERIFIED");
        paymentRepository.save(payment);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/contact/reply/{contactId}")
    public String replyContact(@PathVariable Long contactId, @RequestParam String adminReply) {
        Contact contact = contactRepository.findById(contactId).orElseThrow(() -> new RuntimeException("Contact not found"));
        contact.setAdminReply(adminReply);
        contactRepository.save(contact);
        return "redirect:/admin/dashboard";
    }
}
```


## `src/main/java/com/Sarvam/Professional/Education/controller/StudentController.java`

```java
package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.dto.BuyCourseRequest;
import com.Sarvam.Professional.Education.dto.QuizSubmitRequest;
import com.Sarvam.Professional.Education.model.*;
import com.Sarvam.Professional.Education.repository.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/student")
public class StudentController {

    private final UserRepository userRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final PaymentRepository paymentRepository;
    private final LectureRepository lectureRepository;
    private final NoteRepository noteRepository;
    private final QuizRepository quizRepository;
    private final ResultRepository resultRepository;
    private final ContactRepository contactRepository;

    public StudentController(
            UserRepository userRepository,
            CourseRepository courseRepository,
            EnrollmentRepository enrollmentRepository,
            PaymentRepository paymentRepository,
            LectureRepository lectureRepository,
            NoteRepository noteRepository,
            QuizRepository quizRepository,
            ResultRepository resultRepository,
            ContactRepository contactRepository
    ) {
        this.userRepository = userRepository;
        this.courseRepository = courseRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.paymentRepository = paymentRepository;
        this.lectureRepository = lectureRepository;
        this.noteRepository = noteRepository;
        this.quizRepository = quizRepository;
        this.resultRepository = resultRepository;
        this.contactRepository = contactRepository;
    }

    @GetMapping("/dashboard/{studentId}")
    public Map<String, Object> studentDashboard(@PathVariable Long studentId) {
        User user = userRepository.findById(studentId).orElseThrow(() -> new RuntimeException("Student not found"));
        List<Enrollment> enrollments = enrollmentRepository.findByStudentId(studentId);
        List<Payment> payments = paymentRepository.findByStudentId(studentId);
        List<Result> results = resultRepository.findByStudentId(studentId);
        return Map.of("user", user, "enrollments", enrollments, "payments", payments, "results", results);
    }

    @GetMapping("/courses")
    public List<Course> allCourses() {
        return courseRepository.findAll();
    }

    @PostMapping("/buy-course")
    public Payment buyCourse(@RequestBody BuyCourseRequest request) {
        Course course = courseRepository.findById(request.courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        if (enrollmentRepository.existsByStudentIdAndCourseId(request.studentId, request.courseId)) {
            throw new RuntimeException("Already enrolled in this course");
        }

        Payment payment = new Payment();
        payment.setStudentId(request.studentId);
        payment.setCourseId(request.courseId);
        payment.setAmount(course.getPrice());
        payment.setUpiRef(request.upiRef);
        payment.setStatus("SUCCESS");
        payment.setPaidAt(LocalDateTime.now());
        paymentRepository.save(payment);

        Enrollment enrollment = new Enrollment();
        enrollment.setStudentId(request.studentId);
        enrollment.setCourseId(request.courseId);
        enrollment.setEnrolledAt(LocalDateTime.now());
        enrollmentRepository.save(enrollment);

        return payment;
    }

    @GetMapping("/lectures/{courseId}")
    public List<Lecture> lectures(@PathVariable Long courseId) {
        return lectureRepository.findByCourseId(courseId);
    }

    @GetMapping("/notes/{courseId}")
    public List<Note> notes(@PathVariable Long courseId) {
        return noteRepository.findByCourseId(courseId);
    }

    @GetMapping("/quiz/{courseId}")
    public List<Quiz> quiz(@PathVariable Long courseId) {
        return quizRepository.findByCourseId(courseId);
    }

    @PostMapping("/quiz/submit")
    public Result submitQuiz(@RequestBody QuizSubmitRequest request) {
        List<Quiz> questions = quizRepository.findByCourseId(request.courseId);
        int total = questions.size();
        int correct = 0;

        for (Quiz q : questions) {
            String selected = request.answers.get(q.getQuizId());
            if (q.getCorrectOption().equalsIgnoreCase(selected)) {
                correct++;
            }
        }

        Result result = new Result();
        result.setStudentId(request.studentId);
        result.setCourseId(request.courseId);
        result.setTotalQuestions(total);
        result.setCorrectAnswers(correct);
        result.setPercentage(total == 0 ? 0 : (correct * 100.0) / total);
        result.setSubmittedAt(LocalDateTime.now());
        return resultRepository.save(result);
    }

    @PostMapping("/contact")
    public Contact contactUs(@RequestBody Contact contact) {
        contact.setCreatedAt(LocalDateTime.now());
        return contactRepository.save(contact);
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/controller/TeacherController.java`

```java
package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.model.*;
import com.Sarvam.Professional.Education.repository.*;

import java.util.List;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/teacher")
public class TeacherController {

    private final CourseRepository courseRepository;
    private final LectureRepository lectureRepository;
    private final NoteRepository noteRepository;
    private final QuizRepository quizRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ResultRepository resultRepository;

    public TeacherController(
            CourseRepository courseRepository,
            LectureRepository lectureRepository,
            NoteRepository noteRepository,
            QuizRepository quizRepository,
            EnrollmentRepository enrollmentRepository,
            ResultRepository resultRepository
    ) {
        this.courseRepository = courseRepository;
        this.lectureRepository = lectureRepository;
        this.noteRepository = noteRepository;
        this.quizRepository = quizRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.resultRepository = resultRepository;
    }

    @GetMapping("/dashboard")
    public String dashboard() {
        return "Teacher Dashboard";
    }

    @PostMapping("/courses")
    public Course addCourse(@RequestBody Course course) {
        return courseRepository.save(course);
    }

    @GetMapping("/courses")
    public List<Course> allCourses() {
        return courseRepository.findAll();
    }

    @PostMapping("/lectures")
    public Lecture addLecture(@RequestBody Lecture lecture) {
        return lectureRepository.save(lecture);
    }

    @PostMapping("/notes")
    public Note addNote(@RequestBody Note note) {
        return noteRepository.save(note);
    }

    @PostMapping("/quiz")
    public Quiz addQuiz(@RequestBody Quiz quiz) {
        return quizRepository.save(quiz);
    }

    @GetMapping("/students")
    public List<Enrollment> enrolledStudents() {
        return enrollmentRepository.findAll();
    }

    @GetMapping("/performance")
    public List<Result> performance() {
        return resultRepository.findAll();
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/dto/BuyCourseRequest.java`

```java
package com.Sarvam.Professional.Education.dto;

public class BuyCourseRequest {
    public Long studentId;
    public Long courseId;
    public String upiRef;
}

```


## `src/main/java/com/Sarvam/Professional/Education/dto/ChangePasswordRequest.java`

```java
package com.Sarvam.Professional.Education.dto;

public class ChangePasswordRequest {
    public String email;
    public String oldPassword;
    public String newPassword;
}

```


## `src/main/java/com/Sarvam/Professional/Education/dto/ContactReplyRequest.java`

```java
package com.Sarvam.Professional.Education.dto;

public class ContactReplyRequest {
    public String adminReply;
}

```


## `src/main/java/com/Sarvam/Professional/Education/dto/LoginRequest.java`

```java
package com.Sarvam.Professional.Education.dto;

public class LoginRequest {
    public String email;
    public String password;
}

```


## `src/main/java/com/Sarvam/Professional/Education/dto/QuizSubmitRequest.java`

```java
package com.Sarvam.Professional.Education.dto;

import java.util.Map;

public class QuizSubmitRequest {
    public Long studentId;
    public Long courseId;
    public Map<Long, String> answers;
}

```


## `src/main/java/com/Sarvam/Professional/Education/dto/SignUpRequest.java`

```java
package com.Sarvam.Professional.Education.dto;

public class SignUpRequest {
    public String name;
    public String email;
    public String password;
    public String role;
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Contact.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "contact")
public class Contact {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "contact_id")
    private Long contactId;

    private String name;
    private String email;
    private String phone;

    @Column(columnDefinition = "TEXT")
    private String message;

    @Column(name = "admin_reply")
    private String adminReply;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public Long getContactId() {
        return contactId;
    }

    public void setContactId(Long contactId) {
        this.contactId = contactId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getAdminReply() {
        return adminReply;
    }

    public void setAdminReply(String adminReply) {
        this.adminReply = adminReply;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Course.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

@Entity
@Table(name = "courses")
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "course_id")
    private Long courseId;

    private String title;
    private int price;
    private String instructor;
    private String thumbnail;

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public int getPrice() {
        return price;
    }

    public void setPrice(int price) {
        this.price = price;
    }

    public String getInstructor() {
        return instructor;
    }

    public void setInstructor(String instructor) {
        this.instructor = instructor;
    }

    public String getThumbnail() {
        return thumbnail;
    }

    public void setThumbnail(String thumbnail) {
        this.thumbnail = thumbnail;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Enrollment.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "enrollments")
public class Enrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "enrollment_id")
    private Long enrollmentId;

    @Column(name = "student_id")
    private Long studentId;

    @Column(name = "course_id")
    private Long courseId;

    @Column(name = "enrolled_at")
    private LocalDateTime enrolledAt;

    public Long getEnrollmentId() {
        return enrollmentId;
    }

    public void setEnrollmentId(Long enrollmentId) {
        this.enrollmentId = enrollmentId;
    }

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public LocalDateTime getEnrolledAt() {
        return enrolledAt;
    }

    public void setEnrolledAt(LocalDateTime enrolledAt) {
        this.enrolledAt = enrolledAt;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Lecture.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

@Entity
@Table(name = "lectures")
public class Lecture {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "lecture_id")
    private Long lectureId;

    @Column(name = "course_id")
    private Long courseId;

    private String title;

    @Column(name = "video_url")
    private String videoUrl;

    @Column(name = "meeting_url")
    private String meetingUrl;

    public Long getLectureId() {
        return lectureId;
    }

    public void setLectureId(Long lectureId) {
        this.lectureId = lectureId;
    }

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
    }

    public String getMeetingUrl() {
        return meetingUrl;
    }

    public void setMeetingUrl(String meetingUrl) {
        this.meetingUrl = meetingUrl;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Note.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

@Entity
@Table(name = "notes")
public class Note {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "note_id")
    private Long noteId;

    @Column(name = "course_id")
    private Long courseId;

    private String title;

    @Column(name = "file_url")
    private String fileUrl;

    public Long getNoteId() {
        return noteId;
    }

    public void setNoteId(Long noteId) {
        this.noteId = noteId;
    }

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getFileUrl() {
        return fileUrl;
    }

    public void setFileUrl(String fileUrl) {
        this.fileUrl = fileUrl;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Payment.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "payments")
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "payment_id")
    private Long paymentId;

    @Column(name = "invoice_no", nullable = false, unique = true)
    private String invoiceNo = "INV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

    @Column(name = "student_id")
    private Long studentId;

    @Column(name = "course_id")
    private Long courseId;

    @Column(name = "upi_ref")
    private String upiRef;

    private double amount;
    private String status;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    public Long getPaymentId() {
        return paymentId;
    }

    public void setPaymentId(Long paymentId) {
        this.paymentId = paymentId;
    }

    public String getInvoiceNo() {
        return invoiceNo;
    }

    public void setInvoiceNo(String invoiceNo) {
        this.invoiceNo = invoiceNo;
    }

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public String getUpiRef() {
        return upiRef;
    }

    public void setUpiRef(String upiRef) {
        this.upiRef = upiRef;
    }

    public double getAmount() {
        return amount;
    }

    public void setAmount(double amount) {
        this.amount = amount;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getPaidAt() {
        return paidAt;
    }

    public void setPaidAt(LocalDateTime paidAt) {
        this.paidAt = paidAt;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Quiz.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

@Entity
@Table(name = "quiz")
public class Quiz {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "quiz_id")
    private Long quizId;

    @Column(name = "course_id")
    private Long courseId;

    private String question;

    @Column(name = "option_a")
    private String optionA;

    @Column(name = "option_b")
    private String optionB;

    @Column(name = "option_c")
    private String optionC;

    @Column(name = "option_d")
    private String optionD;

    @Column(name = "correct_option")
    private String correctOption;

    public Long getQuizId() {
        return quizId;
    }

    public void setQuizId(Long quizId) {
        this.quizId = quizId;
    }

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public String getOptionA() {
        return optionA;
    }

    public void setOptionA(String optionA) {
        this.optionA = optionA;
    }

    public String getOptionB() {
        return optionB;
    }

    public void setOptionB(String optionB) {
        this.optionB = optionB;
    }

    public String getOptionC() {
        return optionC;
    }

    public void setOptionC(String optionC) {
        this.optionC = optionC;
    }

    public String getOptionD() {
        return optionD;
    }

    public void setOptionD(String optionD) {
        this.optionD = optionD;
    }

    public String getCorrectOption() {
        return correctOption;
    }

    public void setCorrectOption(String correctOption) {
        this.correctOption = correctOption;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Result.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "results")
public class Result {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "result_id")
    private Long resultId;

    @Column(name = "student_id")
    private Long studentId;

    @Column(name = "course_id")
    private Long courseId;

    @Column(name = "total_questions")
    private int totalQuestions;

    @Column(name = "correct_answers")
    private int correctAnswers;

    private double percentage;

    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    public Long getResultId() {
        return resultId;
    }

    public void setResultId(Long resultId) {
        this.resultId = resultId;
    }

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public Long getCourseId() {
        return courseId;
    }

    public void setCourseId(Long courseId) {
        this.courseId = courseId;
    }

    public int getTotalQuestions() {
        return totalQuestions;
    }

    public void setTotalQuestions(int totalQuestions) {
        this.totalQuestions = totalQuestions;
    }

    public int getCorrectAnswers() {
        return correctAnswers;
    }

    public void setCorrectAnswers(int correctAnswers) {
        this.correctAnswers = correctAnswers;
    }

    public double getPercentage() {
        return percentage;
    }

    public void setPercentage(double percentage) {
        this.percentage = percentage;
    }

    public LocalDateTime getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(LocalDateTime submittedAt) {
        this.submittedAt = submittedAt;
    }
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/Role.java`

```java
package com.Sarvam.Professional.Education.model;

public enum Role {
    STUDENT,
    TEACHER,
    ADMIN
}

```


## `src/main/java/com/Sarvam/Professional/Education/model/User.java`

```java
package com.Sarvam.Professional.Education.model;

import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    private String name;

    @Column(unique = true, nullable = false)
    private String email;

    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean active = true;

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
```


## `src/main/java/com/Sarvam/Professional/Education/repository/ContactRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Contact;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContactRepository extends JpaRepository<Contact, Long> {
}

```


## `src/main/java/com/Sarvam/Professional/Education/repository/CourseRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Course;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseRepository extends JpaRepository<Course, Long> {
}
```


## `src/main/java/com/Sarvam/Professional/Education/repository/EnrollmentRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    List<Enrollment> findByStudentId(Long studentId);

    boolean existsByStudentIdAndCourseId(Long studentId, Long courseId);
}
```


## `src/main/java/com/Sarvam/Professional/Education/repository/LectureRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Lecture;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface LectureRepository extends JpaRepository<Lecture, Long> {
    List<Lecture> findByCourseId(Long courseId);
}

```


## `src/main/java/com/Sarvam/Professional/Education/repository/NoteRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Note;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NoteRepository extends JpaRepository<Note, Long> {
    List<Note> findByCourseId(Long courseId);
}

```


## `src/main/java/com/Sarvam/Professional/Education/repository/PaymentRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Payment;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    List<Payment> findByStudentId(Long studentId);
}

```


## `src/main/java/com/Sarvam/Professional/Education/repository/QuizRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Quiz;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface QuizRepository extends JpaRepository<Quiz, Long> {
    List<Quiz> findByCourseId(Long courseId);
}

```


## `src/main/java/com/Sarvam/Professional/Education/repository/ResultRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Result;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ResultRepository extends JpaRepository<Result, Long> {
    List<Result> findByStudentId(Long studentId);
}

```


## `src/main/java/com/Sarvam/Professional/Education/repository/UserRepository.java`

```java
package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);
}
```


## `src/main/java/com/Sarvam/Professional/Education/service/UserService.java`

```java
package com.Sarvam.Professional.Education.service;

import com.Sarvam.Professional.Education.model.User;
import com.Sarvam.Professional.Education.repository.UserRepository;
import com.Sarvam.Professional.Education.util.PasswordPrefixUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public User saveUser(User user) {
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        return userRepository.save(user);
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public boolean existsByEmail(String email) {
        return userRepository.findByEmail(email).isPresent();
    }

    /**
     * Verifies current password against the database and stores the new encoded password.
     */
    public void changePassword(String email, String currentPassword, String newPassword) {
        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters.");
        }
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found."));
        if (!passwordEncoder.matches(currentPassword, PasswordPrefixUtil.normalize(user.getPassword()))) {
            throw new IllegalArgumentException("Current password is incorrect.");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
}
```


## `src/main/java/com/Sarvam/Professional/Education/util/PasswordPrefixUtil.java`

```java
package com.Sarvam.Professional.Education.util;

import java.util.regex.Pattern;

/**
 * Adds the encoder prefix Spring Security's DelegatingPasswordEncoder needs
 * (e.g. {noop}, {bcrypt}) when a stored password is missing one. Used by both
 * authentication (login) and the change-password flow so they stay in sync.
 */
public final class PasswordPrefixUtil {

    private static final Pattern PREFIX_PATTERN = Pattern.compile("^\\{.+}.*");

    private PasswordPrefixUtil() {
    }

    public static String normalize(String storedPassword) {
        if (storedPassword == null) {
            return null;
        }
        if (PREFIX_PATTERN.matcher(storedPassword).matches()) {
            return storedPassword;
        }
        if (isBcryptHash(storedPassword)) {
            return "{bcrypt}" + storedPassword;
        }
        return "{noop}" + storedPassword;
    }

    private static boolean isBcryptHash(String value) {
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }
}

```

## B.3 Thymeleaf Templates


## `src/main/resources/templates/admin-dashboard.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - Sarvam</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link href="/css/sarvam-theme.css" rel="stylesheet">
</head>
<body class="sarvam-app">
<div class="sarvam-shell">
    <header class="sarvam-topbar">
        <a class="sarvam-brand" href="/admin/dashboard">
            <img alt="" src="/images/sarvam-logo.png">
            <span>Sarvam Professional Education</span>
        </a>
        <div class="sarvam-topbar-actions">
            <span class="sarvam-greet">Namaste, <span th:text="${displayName}">Admin</span></span>
            <span class="sarvam-badge-role" th:text="${roleBadge}">ADMIN</span>
            <a class="btn-sarvam-ghost" href="/logout"><i class="fa-solid fa-right-from-bracket"></i> Logout</a>
        </div>
    </header>

    <div class="sarvam-layout">
        <aside class="sarvam-sidebar">
            <div class="sarvam-sidebar-logo"><img alt="" src="/images/sarvam-logo.png"></div>
            <nav>
                <a class="sarvam-nav-link" href="/admin/dashboard?tab=overview"
                   th:classappend="${activeTab == 'overview'} ? ' active'"><i class="fa-solid fa-house"></i>
                    Dashboard</a>
                <a class="sarvam-nav-link" href="/admin/dashboard?tab=users"
                   th:classappend="${activeTab == 'users'} ? ' active'"><i class="fa-solid fa-users"></i> Users</a>
                <a class="sarvam-nav-link" href="/admin/dashboard?tab=courses"
                   th:classappend="${activeTab == 'courses'} ? ' active'"><i class="fa-solid fa-book"></i> Courses</a>
                <a class="sarvam-nav-link" href="/admin/dashboard?tab=payments"
                   th:classappend="${activeTab == 'payments'} ? ' active'"><i class="fa-solid fa-credit-card"></i>
                    Payments</a>
                <a class="sarvam-nav-link" href="/admin/dashboard?tab=reports"
                   th:classappend="${activeTab == 'reports'} ? ' active'"><i class="fa-solid fa-chart-column"></i>
                    Reports</a>
                <a class="sarvam-nav-link" href="/admin/dashboard?tab=contacts"
                   th:classappend="${activeTab == 'contacts'} ? ' active'"><i class="fa-solid fa-envelope"></i> Contacts</a>
            </nav>
        </aside>

        <main class="sarvam-main">
            <h1 class="sarvam-page-title">Admin dashboard</h1>
            <p class="sarvam-page-lead">Users, courses, payment verification, reports, and contact replies.</p>

            <div class="row g-3 mb-2" th:if="${activeTab == 'overview'}">
                <div class="col-6 col-lg-3">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Users</div>
                        <div class="sarvam-kpi-value" th:text="${totalUsers}">0</div>
                    </div>
                </div>
                <div class="col-6 col-lg-3">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Courses</div>
                        <div class="sarvam-kpi-value accent-teal" th:text="${totalCourses}">0</div>
                    </div>
                </div>
                <div class="col-6 col-lg-3">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Payments</div>
                        <div class="sarvam-kpi-value" th:text="${totalPayments}">0</div>
                    </div>
                </div>
                <div class="col-6 col-lg-3">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Messages</div>
                        <div class="sarvam-kpi-value accent-amber" th:text="${totalContacts}">0</div>
                    </div>
                </div>
            </div>

            <div class="row g-3 mb-4" th:if="${activeTab == 'overview'}">
                <div class="col-md-4">
                    <div class="sarvam-panel mb-0 h-100">
                        <div class="fw-semibold mb-2">User management</div>
                        <p class="small text-muted mb-3">Create, update, or remove accounts.</p>
                        <a class="btn btn-primary btn-sm w-100" href="/admin/dashboard?tab=users">Open users</a>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="sarvam-panel mb-0 h-100">
                        <div class="fw-semibold mb-2">Payments</div>
                        <p class="small text-muted mb-3">Verify student UPI payments.</p>
                        <a class="btn btn-outline-primary btn-sm w-100" href="/admin/dashboard?tab=payments">Verify
                            payments</a>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="sarvam-panel mb-0 h-100">
                        <div class="fw-semibold mb-2">Support inbox</div>
                        <p class="small text-muted mb-3">Reply to contact messages.</p>
                        <a class="btn btn-outline-primary btn-sm w-100" href="/admin/dashboard?tab=contacts">View
                            contacts</a>
                    </div>
                </div>
            </div>

            <section class="sarvam-panel" th:if="${activeTab == 'users'}">
                <h2 class="h6 fw-bold mb-3">Create / update user</h2>
                <form action="/admin/user/save" class="row g-2 align-items-end" method="post">
                    <div class="col-lg-1 col-md-2"><input class="form-control form-control-sm" name="userId"
                                                          aria-label="User ID (optional)"
                                                          placeholder="ID"></div>
                    <div class="col-lg-2 col-md-3"><input class="form-control form-control-sm" name="name"
                                                          aria-label="User name"
                                                          placeholder="Name" required></div>
                    <div class="col-lg-2 col-md-3"><input class="form-control form-control-sm" name="email"
                                                          aria-label="User email"
                                                          placeholder="Email" required></div>
                    <div class="col-lg-2 col-md-2">
                        <select class="form-select form-select-sm" name="role" aria-label="User role" required>
                            <option value="STUDENT">STUDENT</option>
                            <option value="TEACHER">TEACHER</option>
                            <option value="ADMIN">ADMIN</option>
                        </select>
                    </div>
                    <div class="col-lg-2 col-md-3"><input class="form-control form-control-sm" name="password"
                                                          aria-label="User password"
                                                          placeholder="Password"></div>
                    <div class="col-lg-1 col-md-2">
                        <select class="form-select form-select-sm" name="active" aria-label="Account status">
                            <option value="true">Active</option>
                            <option value="false">Blocked</option>
                        </select>
                    </div>
                    <div class="col-lg-2 col-md-12">
                        <button class="btn btn-primary btn-sm w-100" type="submit">Save</button>
                    </div>
                </form>
                <div class="sarvam-table-wrap mt-3">
                    <table class="table table-hover table-sm align-middle mb-0">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Role</th>
                            <th>Active</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="u : ${users}">
                            <td th:text="${u.userId}"></td>
                            <td th:text="${u.name}"></td>
                            <td th:text="${u.email}"></td>
                            <td th:text="${u.role}"></td>
                            <td th:text="${u.active}"></td>
                            <td>
                                <form class="d-inline" method="post" th:action="@{'/admin/user/delete/' + ${u.userId}}">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'courses'}">
                <h2 class="h6 fw-bold mb-3">Courses</h2>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover table-sm align-middle mb-0">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Title</th>
                            <th>Price</th>
                            <th>Instructor</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="c : ${courses}">
                            <td th:text="${c.courseId}"></td>
                            <td th:text="${c.title}"></td>
                            <td th:text="${c.price}"></td>
                            <td th:text="${c.instructor}"></td>
                            <td>
                                <form class="d-inline" method="post" th:action="@{'/admin/course/delete/' + ${c.courseId}}">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'payments'}">
                <h2 class="h6 fw-bold mb-3">Verify payments</h2>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover table-sm align-middle mb-0">
                        <thead>
                        <tr>
                            <th>Invoice</th>
                            <th>Student</th>
                            <th>Course</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="p : ${payments}">
                            <td th:text="${p.invoiceNo}"></td>
                            <td th:text="${p.studentId}"></td>
                            <td th:text="${p.courseId}"></td>
                            <td th:text="${p.amount}"></td>
                            <td th:text="${p.status}"></td>
                            <td>
                                <form class="d-inline" method="post" th:action="@{'/admin/payment/verify/' + ${p.paymentId}}">
                                    <button class="btn btn-sm btn-success" type="submit">Verify</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'reports'}">
                <h2 class="h6 fw-bold mb-3">Summary</h2>
                <ul class="list-unstyled mb-0 small">
                    <li class="mb-2">Total users: <strong th:text="${totalUsers}">0</strong></li>
                    <li class="mb-2">Total courses: <strong th:text="${totalCourses}">0</strong></li>
                    <li class="mb-2">Total payments: <strong th:text="${totalPayments}">0</strong></li>
                    <li>Contact messages: <strong th:text="${totalContacts}">0</strong></li>
                </ul>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'contacts'}">
                <h2 class="h6 fw-bold mb-3">Contact messages</h2>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover table-sm align-middle mb-0">
                        <thead>
                        <tr>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Message</th>
                            <th>Reply</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="c : ${contacts}">
                            <td th:text="${c.name}"></td>
                            <td th:text="${c.email}"></td>
                            <td th:text="${c.message}"></td>
                            <td th:text="${c.adminReply != null ? c.adminReply : 'Pending'}"></td>
                            <td style="min-width: 200px;">
                                <form class="d-flex gap-1" method="post"
                                      th:action="@{'/admin/contact/reply/' + ${c.contactId}}">
                                    <input class="form-control form-control-sm" name="adminReply"
                                           aria-label="Admin reply" placeholder="Reply" required>
                                    <button class="btn btn-sm btn-primary" type="submit">Send</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </main>
    </div>
</div>
</body>
</html>

```


## `src/main/resources/templates/change-password.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta content="width=device-width, initial-scale=1.0" name="viewport">
    <title>Change Password - Sarvam</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/sarvam-theme.css" rel="stylesheet">
</head>
<body class="sarvam-app sarvam-auth-page">
<div class="sarvam-auth-card">
    <h3 class="mb-4">Change password</h3>
    <div class="alert alert-danger py-2 small mb-3" th:if="${passwordError}" th:text="${passwordError}">Error</div>
    <form method="post" th:action="@{/change-password}">
        <div class="mb-3">
            <label class="form-label" for="cp-email">Email</label>
            <input id="cp-email" autocomplete="username" class="form-control" name="email" required type="email">
        </div>
        <div class="mb-3">
            <label class="form-label" for="cp-current-password">Current password</label>
            <input id="cp-current-password" autocomplete="current-password" class="form-control" name="currentPassword"
                   required type="password">
        </div>
        <div class="mb-4">
            <label class="form-label" for="cp-new-password">New password</label>
            <input id="cp-new-password" autocomplete="new-password" class="form-control" minlength="6"
                   name="newPassword" required
                   type="password">
        </div>
        <button class="btn btn-primary w-100 py-2" type="submit">Update password</button>
    </form>
    <p class="text-center mt-4 mb-0 small">
        <a href="/">← Back to home</a>
    </p>
</div>
</body>
</html>

```


## `src/main/resources/templates/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sarvam Professional Education</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link href="/css/sarvam-theme.css" rel="stylesheet">
</head>
<body class="sarvam-app sarvam-home-page">
<header class="sarvam-home-nav">
    <div class="sarvam-home-nav-inner">
        <a class="sarvam-home-brand" href="/">
                <span class="sarvam-home-logo-wrap">
                    <img alt="" src="/images/sarvam-logo.png">
                </span>
            <span class="sarvam-home-brand-text">Sarvam Professional Education</span>
        </a>
        <nav aria-label="Account" class="sarvam-home-nav-links">
            <a class="btn-sarvam-secondary" href="/login">Login</a>
            <a class="btn-sarvam-primary" href="/signup">Sign Up</a>
        </nav>
    </div>
</header>

<main class="sarvam-home-main">
    <section class="sarvam-home-hero">
        <div class="sarvam-home-hero-copy">
            <h1>Learn on your schedule. Grow with guided courses.</h1>
            <p class="lead">A single place for video lectures, live classes, notes, quizzes, and secure payments—built
                for students, teachers, and administrators.</p>
            <div class="sarvam-home-badges">
                <span class="sarvam-home-badge">Courses &amp; enrollments</span>
                <span class="sarvam-home-badge">UPI payments &amp; invoices</span>
                <span class="sarvam-home-badge">Role-based dashboards</span>
            </div>
        </div>
        <aside aria-labelledby="at-a-glance" class="sarvam-home-hero-card">
            <h2 id="at-a-glance">At a glance</h2>
            <div class="sarvam-home-stat">
                <span>Student experience</span>
                <strong>Browse → Pay → Learn</strong>
            </div>
            <div class="sarvam-home-stat">
                <span>Teachers</span>
                <strong>Content &amp; quizzes</strong>
            </div>
            <div class="sarvam-home-stat">
                <span>Admins</span>
                <strong>Users &amp; verification</strong>
            </div>
        </aside>
    </section>

    <h2 class="sarvam-home-section-title">What you can do here</h2>
    <section class="sarvam-home-features">
        <article class="sarvam-home-feature">
            <div class="sarvam-home-feature-icon"><i class="fa-solid fa-graduation-cap"></i></div>
            <h3>For students</h3>
            <p>Enroll in courses, pay with UPI, watch lectures and join live sessions, download notes, and track
                payments.</p>
        </article>
        <article class="sarvam-home-feature">
            <div class="sarvam-home-feature-icon"><i class="fa-solid fa-chalkboard-user"></i></div>
            <h3>For teachers</h3>
            <p>Publish courses, upload lectures with video or meeting links, share materials, and build quizzes.</p>
        </article>
        <article class="sarvam-home-feature">
            <div class="sarvam-home-feature-icon"><i class="fa-solid fa-shield-halved"></i></div>
            <h3>For admins</h3>
            <p>Manage accounts, oversee the catalog, verify payments, and respond to support messages.</p>
        </article>
    </section>

    <section class="sarvam-home-about">
        <p><strong class="text-dark">Sarvam Professional Education</strong> connects a Spring Boot backend with MySQL so
            your data stays consistent—users, courses, enrollments, payments, and messages all live in one system.</p>
        <p>Use <strong class="text-dark">Login</strong> if you already have an account, or <strong class="text-dark">Sign
            Up</strong> to register as a student, teacher, or admin (as allowed by your institution).</p>
    </section>
</main>

<footer class="sarvam-home-footer">
    Sarvam Professional Education · E-learning platform
</footer>
</body>
</html>

```


## `src/main/resources/templates/login.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Sarvam</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="/css/sarvam-theme.css">
</head>
<body class="sarvam-app sarvam-auth-page">
    <div class="sarvam-auth-card">
        <div class="text-center mb-4">
            <img src="/images/sarvam-logo.png" alt="" style="width: 72px; height: auto;">
        </div>
        <h3 class="mb-4">Sign in</h3>
        <div th:if="${param.error}" class="alert alert-danger py-2 small mb-3">Invalid email or password. Check your details and try again.</div>
        <div th:if="${param.registered}" class="alert alert-success py-2 small mb-3">Registration successful. Please sign in.</div>
        <div th:if="${passwordSuccess}" class="alert alert-success py-2 small mb-3">Password updated. Sign in with your new password.</div>

        <div th:if="${param.error}" class="sarvam-forgot-callout">
            <strong>Forgot your password?</strong>
            <p>If you still know your current password, you can set a new one on the update page. Contact your administrator if you are locked out.</p>
            <a href="/change-password" class="btn btn-primary btn-sm w-100">Go to update password</a>
        </div>

        <form th:action="@{/login}" method="post">
            <div class="mb-3">
                <label for="login-email">Email</label>
                <input id="login-email" type="email" name="email" class="form-control" required autocomplete="username">
            </div>
            <div class="mb-4">
                <label for="login-password">Password</label>
                <input id="login-password" type="password" name="password" class="form-control" required
                       autocomplete="current-password">
            </div>
            <button type="submit" class="btn btn-primary w-100 py-2">Sign in</button>
        </form>

        <p class="text-center mt-4 mb-2 small text-muted">
            No account? <a href="/signup" class="fw-semibold">Create one</a>
        </p>
        <p class="text-center mb-0 small">
            <a href="/" class="text-muted">← Back to home</a>
        </p>
    </div>
</body>
</html>

```


## `src/main/resources/templates/signup.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign Up - Sarvam</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="/css/sarvam-theme.css">
</head>
<body class="sarvam-app sarvam-auth-page">
<div class="sarvam-auth-card">
    <div class="text-center mb-4">
        <img src="/images/sarvam-logo.png" alt="" style="width: 72px; height: auto;">
    </div>
    <h3 class="mb-4">Create account</h3>

    <form th:action="@{/signup}" method="post" th:object="${user}">
        <div class="mb-3">
            <label for="name">Full name</label>
            <input id="name" type="text" th:field="*{name}" class="form-control" required>
        </div>
        <div class="mb-3">
            <label for="email">Email</label>
            <input id="email" type="email" th:field="*{email}" class="form-control" required>
        </div>
        <div class="mb-3">
            <label for="password">Password</label>
            <input id="password" type="password" th:field="*{password}" class="form-control" required>
        </div>
        <div class="mb-4">
            <label for="role">Role</label>
            <select id="role" th:field="*{role}" class="form-select">
                <option value="STUDENT">Student</option>
                <option value="TEACHER">Teacher</option>
                <option value="ADMIN">Admin</option>
            </select>
        </div>
        <button type="submit" class="btn btn-primary w-100 py-2">Register</button>
    </form>

    <p class="text-center mt-4 mb-2 small">
        <a href="/login">Already have an account? Sign in</a>
    </p>
    <p class="text-center mb-0 small"><a href="/" class="text-muted">← Home</a></p>
</div>
</body>
</html>

```


## `src/main/resources/templates/student-course.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title th:text="${course.title} + ' · Sarvam'">Course</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="/css/sarvam-theme.css">
</head>
<body class="sarvam-app">
<div class="sarvam-narrow">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
        <a href="/student/dashboard?tab=courses" class="btn btn-outline-secondary btn-sm"><i
                class="fa-solid fa-arrow-left me-1"></i> Back to my courses</a>
        <span class="small text-muted">Signed in as <span class="fw-semibold text-dark"
                                                          th:text="${displayName}">Student</span></span>
    </div>

    <div class="sarvam-content-block mb-4">
        <h1 class="sarvam-page-title mb-1" th:text="${course.title}">Course</h1>
        <p class="sarvam-page-lead mb-0">Instructor: <span th:text="${course.instructor}">—</span></p>
    </div>

    <h2 class="sarvam-section-title"><i class="fa-solid fa-circle-play me-2" style="color: var(--color-primary);"></i>Lectures
    </h2>
    <div th:if="${#lists.isEmpty(lectureRows)}" class="sarvam-content-block text-muted">No lectures for this course
        yet.
    </div>
    <div th:each="row : ${lectureRows}" class="sarvam-content-block">
        <h3 class="h6 fw-bold mb-3" th:text="${row.title}">Lecture</h3>
        <div th:if="${row.youtubeEmbedId != null}" class="ratio ratio-16x9 mb-3">
            <iframe th:src="|https://www.youtube.com/embed/${row.youtubeEmbedId}|" title="Video" allowfullscreen
                    class="rounded"></iframe>
        </div>
        <div th:if="${row.youtubeEmbedId == null and row.videoUrl != null and !#strings.isEmpty(row.videoUrl)}"
             class="mb-2">
            <a th:href="${row.videoUrl}" target="_blank" rel="noopener" class="btn btn-primary btn-sm"><i
                    class="fa-solid fa-play me-1"></i> Open video</a>
        </div>
        <div th:if="${row.meetingUrl != null and !#strings.isEmpty(row.meetingUrl)}" class="mt-2">
            <a th:href="${row.meetingUrl}" target="_blank" rel="noopener" class="btn btn-outline-primary btn-sm"><i
                    class="fa-solid fa-video me-1"></i> Join live class</a>
        </div>
        <p th:if="${row.youtubeEmbedId == null and (row.videoUrl == null or #strings.isEmpty(row.videoUrl)) and (row.meetingUrl == null or #strings.isEmpty(row.meetingUrl))}"
           class="text-muted small mb-0">No video or meeting link.</p>
    </div>

    <h2 class="sarvam-section-title mt-4"><i class="fa-solid fa-file-arrow-down me-2"
                                             style="color: var(--color-accent);"></i>Notes</h2>
    <div th:if="${#lists.isEmpty(notes)}" class="sarvam-content-block text-muted">No notes uploaded.</div>
    <ul class="list-group mb-4" th:if="${!#lists.isEmpty(notes)}">
        <li th:each="n : ${notes}"
            class="list-group-item d-flex justify-content-between align-items-center rounded-3 mb-2 border"
            style="border-color: var(--color-border) !important;">
            <span class="fw-medium" th:text="${n.title}">Note</span>
            <a th:if="${n.fileUrl != null and !#strings.isEmpty(n.fileUrl)}"
               th:href="${n.fileUrl}" download target="_blank" rel="noopener"
               class="btn btn-sm btn-primary">Download</a>
            <span th:if="${n.fileUrl == null or #strings.isEmpty(n.fileUrl)}" class="small text-muted">No file</span>
        </li>
    </ul>
</div>
</body>
</html>

```


## `src/main/resources/templates/student-dashboard.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Dashboard - Sarvam</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="/css/sarvam-theme.css">
</head>
<body class="sarvam-app">
<div class="sarvam-shell">
    <header class="sarvam-topbar">
        <a href="/student/dashboard" class="sarvam-brand">
            <img src="/images/sarvam-logo.png" alt="">
            <span>Sarvam Professional Education</span>
        </a>
        <div class="sarvam-topbar-actions">
            <span class="sarvam-greet">Namaste, <span th:text="${displayName}">Student</span></span>
            <span class="sarvam-badge-role" th:text="${roleBadge}">STUDENT</span>
            <a class="btn-sarvam-ghost" href="/logout"><i class="fa-solid fa-right-from-bracket"></i> Logout</a>
        </div>
    </header>

    <div class="sarvam-layout">
        <aside class="sarvam-sidebar">
            <div class="sarvam-sidebar-logo">
                <img src="/images/sarvam-logo.png" alt="">
            </div>
            <nav>
                <a href="/student/dashboard?tab=overview" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'overview'} ? ' active'"><i class="fa-solid fa-house"></i>
                    Dashboard</a>
                <a href="/student/dashboard?tab=buy" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'buy'} ? ' active'"><i class="fa-solid fa-cart-shopping"></i> Buy
                    courses</a>
                <a href="/student/dashboard?tab=courses" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'courses'} ? ' active'"><i class="fa-solid fa-book"></i> My courses
                    &amp; lectures</a>
                <a href="/student/dashboard?tab=payments" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'payments'} ? ' active'"><i class="fa-solid fa-receipt"></i> Payments</a>
                <a href="/student/dashboard?tab=support" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'support'} ? ' active'"><i class="fa-solid fa-headset"></i>
                    Support</a>
            </nav>
        </aside>

        <main class="sarvam-main">
            <h1 class="sarvam-page-title">Student dashboard</h1>
            <p class="sarvam-page-lead" th:if="${activeTab == 'overview'}">Signed in as <strong
                    th:text="${displayName}">Student</strong>. Below is a quick snapshot; use the menu for all features.
            </p>
            <p class="sarvam-page-lead" th:if="${activeTab == 'buy'}">Purchase access with a UPI reference. Your invoice
                and enrollment are saved automatically.</p>
            <p class="sarvam-page-lead" th:if="${activeTab == 'courses'}">Open any course to watch lectures and download
                notes.</p>
            <p class="sarvam-page-lead" th:if="${activeTab == 'payments'}">Invoices and payment status for your
                purchases.</p>
            <p class="sarvam-page-lead" th:if="${activeTab == 'support'}">Send a message to the admin team.</p>

            <div class="row g-3 mb-2" th:if="${activeTab == 'overview'}">
                <div class="col-md-4">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Enrolled courses</div>
                        <div class="sarvam-kpi-value" th:text="${enrolledCount}">0</div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Hours learned</div>
                        <div class="sarvam-kpi-value accent-teal" th:text="${hoursLearned}">0</div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="sarvam-kpi">
                        <div class="sarvam-kpi-label">Current streak</div>
                        <div class="sarvam-kpi-value accent-amber"><span th:text="${currentStreak}">0</span> days</div>
                    </div>
                </div>
            </div>

            <div class="row g-3 mb-4" th:if="${activeTab == 'overview'}">
                <div class="col-md-4">
                    <div class="sarvam-panel mb-0 h-100">
                        <div class="fw-semibold mb-2"><i class="fa-solid fa-cart-shopping text-primary me-2"></i>Browse
                            catalog
                        </div>
                        <p class="small text-muted mb-3">See available courses and enroll with UPI.</p>
                        <a href="/student/dashboard?tab=buy" class="btn btn-primary btn-sm w-100">Go to buy courses</a>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="sarvam-panel mb-0 h-100">
                        <div class="fw-semibold mb-2"><i class="fa-solid fa-play text-primary me-2"></i>Continue
                            learning
                        </div>
                        <p class="small text-muted mb-3">Open lectures, videos, and notes.</p>
                        <a href="/student/dashboard?tab=courses" class="btn btn-outline-primary btn-sm w-100">My
                            courses</a>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="sarvam-panel mb-0 h-100">
                        <div class="fw-semibold mb-2"><i class="fa-solid fa-receipt text-primary me-2"></i>Receipts
                        </div>
                        <p class="small text-muted mb-3">Review invoices and payment status.</p>
                        <a href="/student/dashboard?tab=payments" class="btn btn-outline-primary btn-sm w-100">Payment
                            history</a>
                    </div>
                </div>
            </div>

            <section th:if="${activeTab == 'buy'}">
                <h2 class="sarvam-section-title">Available courses</h2>
                <div class="row g-3">
                    <div class="col-md-6 col-xl-4" th:if="${#lists.isEmpty(courses)}">
                        <div class="sarvam-course-card"><p class="text-muted mb-0">No courses yet. Check back soon.</p>
                        </div>
                    </div>
                    <div class="col-md-6 col-xl-4" th:each="course : ${courses}">
                        <div class="sarvam-course-card">
                            <div class="sarvam-course-icon"><i class="fa-solid fa-laptop-code"></i></div>
                            <h3 class="h6 fw-bold mb-1" th:text="${course.title}">Title</h3>
                            <p class="small text-muted mb-3">Instructor: <span th:text="${course.instructor}">—</span>
                            </p>
                            <div class="mt-auto d-flex flex-wrap align-items-center justify-content-between gap-2">
                                <span class="sarvam-price">₹<span th:text="${course.price}">0</span></span>
                                <form action="/student/buy-course" method="post"
                                      class="d-flex align-items-center gap-2 flex-wrap">
                                    <input type="hidden" name="courseId" th:value="${course.courseId}">
                                    <input type="text" name="upiRef" class="form-control form-control-sm"
                                           aria-label="UPI reference number"
                                           placeholder="UPI ref" required style="max-width: 130px;">
                                    <button class="btn-sarvam-buy" type="submit">Buy</button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section th:if="${activeTab == 'courses'}">
                <h2 class="sarvam-section-title">My enrollments</h2>
                <p class="small text-muted mb-3">Watch YouTube lectures, join Meet or Zoom, and download materials.</p>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Course</th>
                            <th>Enrolled</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:if="${#lists.isEmpty(myEnrollments)}">
                            <td colspan="4" class="text-muted py-4 text-center">No enrollments yet.</td>
                        </tr>
                        <tr th:each="e : ${myEnrollments}">
                            <td th:text="${e.enrollmentId}"></td>
                            <td th:text="${courseTitles.get(e.courseId) != null ? courseTitles.get(e.courseId) : ('Course #' + e.courseId)}"></td>
                            <td th:text="${e.enrolledAt}"></td>
                            <td class="text-end">
                                <a class="btn btn-primary btn-sm" th:href="@{/student/course/{courseId}(courseId=${e.courseId})}">Open</a>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section th:if="${activeTab == 'payments'}">
                <h2 class="sarvam-section-title">Payment history</h2>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>Invoice</th>
                            <th>Course</th>
                            <th>Amount</th>
                            <th>UPI ref</th>
                            <th>Status</th>
                            <th>Paid</th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:if="${#lists.isEmpty(myPayments)}">
                            <td colspan="6" class="text-muted py-4 text-center">No payments yet.</td>
                        </tr>
                        <tr th:each="p : ${myPayments}">
                            <td th:text="${p.invoiceNo}"></td>
                            <td th:text="${courseTitles.get(p.courseId) != null ? courseTitles.get(p.courseId) : ('Course #' + p.courseId)}"></td>
                            <td th:text="${p.amount}"></td>
                            <td th:text="${p.upiRef}"></td>
                            <td><span class="badge rounded-pill text-bg-light border" th:text="${p.status}"></span></td>
                            <td th:text="${p.paidAt}"></td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section th:if="${activeTab == 'support'}">
                <h2 class="sarvam-section-title">Contact support</h2>
                <form action="/student/contact" method="post" class="row g-2 mb-4 sarvam-panel">
                    <div class="col-md-3"><input class="form-control" name="name" aria-label="Your name"
                                                 placeholder="Name"></div>
                    <div class="col-md-3"><input class="form-control" name="email" aria-label="Your email"
                                                 placeholder="Email"></div>
                    <div class="col-md-2"><input class="form-control" name="phone" aria-label="Your phone"
                                                 placeholder="Phone"></div>
                    <div class="col-md-3"><input class="form-control" name="message" aria-label="Message"
                                                 placeholder="Message" required>
                    </div>
                    <div class="col-md-1">
                        <button class="btn btn-primary w-100" type="submit">Send</button>
                    </div>
                </form>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>Name</th>
                            <th>Message</th>
                            <th>Reply</th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:if="${#lists.isEmpty(myContacts)}">
                            <td colspan="3" class="text-muted py-4 text-center">No messages yet.</td>
                        </tr>
                        <tr th:each="c : ${myContacts}">
                            <td th:text="${c.name}"></td>
                            <td th:text="${c.message}"></td>
                            <td th:text="${c.adminReply != null ? c.adminReply : 'Pending'}"></td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </main>
    </div>
</div>
</body>
</html>

```


## `src/main/resources/templates/teacher-dashboard.html`

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Dashboard - Sarvam</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="/css/sarvam-theme.css">
</head>
<body class="sarvam-app">
<div class="sarvam-shell">
    <header class="sarvam-topbar">
        <a href="/teacher/dashboard" class="sarvam-brand">
            <img src="/images/sarvam-logo.png" alt="">
            <span>Sarvam Professional Education</span>
        </a>
        <div class="sarvam-topbar-actions">
            <span class="sarvam-greet">Namaste, <span th:text="${displayName}">Teacher</span></span>
            <span class="sarvam-badge-role" th:text="${roleBadge}">TEACHER</span>
            <a class="btn-sarvam-ghost" href="/logout"><i class="fa-solid fa-right-from-bracket"></i> Logout</a>
        </div>
    </header>

    <div class="sarvam-layout">
        <aside class="sarvam-sidebar">
            <div class="sarvam-sidebar-logo"><img src="/images/sarvam-logo.png" alt=""></div>
            <nav>
                <a href="/teacher/dashboard?tab=overview" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'overview'} ? ' active'"><i class="fa-solid fa-house"></i>
                    Dashboard</a>
                <a href="/teacher/dashboard?tab=courses" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'courses'} ? ' active'"><i class="fa-solid fa-book"></i> Courses</a>
                <a href="/teacher/dashboard?tab=lectures" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'lectures'} ? ' active'"><i class="fa-solid fa-upload"></i>
                    Lectures</a>
                <a href="/teacher/dashboard?tab=notes" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'notes'} ? ' active'"><i class="fa-solid fa-file-arrow-up"></i> Notes</a>
                <a href="/teacher/dashboard?tab=quizzes" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'quizzes'} ? ' active'"><i class="fa-solid fa-circle-question"></i>
                    Quizzes</a>
                <a href="/teacher/dashboard?tab=students" class="sarvam-nav-link"
                   th:classappend="${activeTab == 'students'} ? ' active'"><i class="fa-solid fa-users"></i>
                    Students</a>
            </nav>
        </aside>

        <main class="sarvam-main">
            <h1 class="sarvam-page-title">Teacher dashboard</h1>
            <p class="sarvam-page-lead">Manage courses, lectures, notes, quizzes, and view enrollments.</p>

            <section th:if="${activeTab == 'overview'}">
                <div class="row g-3 mb-4">
                    <div class="col-6 col-lg-3">
                        <div class="sarvam-kpi">
                            <div class="sarvam-kpi-label">Courses</div>
                            <div class="sarvam-kpi-value" th:text="${#lists.size(courses)}">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-lg-3">
                        <div class="sarvam-kpi">
                            <div class="sarvam-kpi-label">Lectures</div>
                            <div class="sarvam-kpi-value accent-teal" th:text="${#lists.size(lectures)}">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-lg-3">
                        <div class="sarvam-kpi">
                            <div class="sarvam-kpi-label">Notes</div>
                            <div class="sarvam-kpi-value" th:text="${#lists.size(notes)}">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-lg-3">
                        <div class="sarvam-kpi">
                            <div class="sarvam-kpi-label">Enrollments</div>
                            <div class="sarvam-kpi-value accent-amber" th:text="${#lists.size(students)}">0</div>
                        </div>
                    </div>
                </div>
                <div class="row g-3">
                    <div class="col-md-4">
                        <div class="sarvam-panel mb-0 h-100">
                            <div class="fw-semibold mb-2">Courses</div>
                            <p class="small text-muted mb-3">Add or edit course catalog entries.</p>
                            <a href="/teacher/dashboard?tab=courses" class="btn btn-primary btn-sm w-100">Manage
                                courses</a>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="sarvam-panel mb-0 h-100">
                            <div class="fw-semibold mb-2">Content</div>
                            <p class="small text-muted mb-3">Upload lectures and note file links.</p>
                            <a href="/teacher/dashboard?tab=lectures"
                               class="btn btn-outline-primary btn-sm w-100 me-0 mb-2">Lectures</a>
                            <a href="/teacher/dashboard?tab=notes"
                               class="btn btn-outline-primary btn-sm w-100">Notes</a>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="sarvam-panel mb-0 h-100">
                            <div class="fw-semibold mb-2">Learners</div>
                            <p class="small text-muted mb-3">See who enrolled in your courses.</p>
                            <a href="/teacher/dashboard?tab=students" class="btn btn-outline-primary btn-sm w-100">View
                                students</a>
                        </div>
                    </div>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'courses'}">
                <h2 class="h6 fw-bold mb-3">Add / update course</h2>
                <form method="post" action="/teacher/course/save" class="row g-2 align-items-end">
                    <div class="col-md-2"><input class="form-control form-control-sm" name="courseId"
                                                 aria-label="Course ID (optional)"
                                                 placeholder="ID (optional)"></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="title"
                                                 aria-label="Course title"
                                                 placeholder="Title" required></div>
                    <div class="col-md-2"><input class="form-control form-control-sm" name="price" type="number"
                                                 aria-label="Course price"
                                                 placeholder="Price" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="instructor"
                                                 aria-label="Instructor name"
                                                 placeholder="Instructor" required></div>
                    <div class="col-md-2">
                        <button class="btn btn-primary btn-sm w-100" type="submit">Save</button>
                    </div>
                </form>
                <div class="sarvam-table-wrap mt-3">
                    <table class="table table-hover table-sm mb-0">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Title</th>
                            <th>Price</th>
                            <th>Instructor</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="c : ${courses}">
                            <td th:text="${c.courseId}"></td>
                            <td th:text="${c.title}"></td>
                            <td th:text="${c.price}"></td>
                            <td th:text="${c.instructor}"></td>
                            <td>
                                <form th:action="@{'/teacher/course/delete/' + ${c.courseId}}" method="post" class="d-inline">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'lectures'}">
                <h2 class="h6 fw-bold mb-3">Add / update lecture</h2>
                <form method="post" action="/teacher/lecture/save" class="row g-2">
                    <div class="col-md-2"><input class="form-control form-control-sm" name="lectureId"
                                                 aria-label="Lecture ID (optional)"
                                                 placeholder="ID (optional)"></div>
                    <div class="col-md-2"><input class="form-control form-control-sm" name="courseId"
                                                 aria-label="Course ID"
                                                 placeholder="Course ID" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="title"
                                                 aria-label="Lecture title"
                                                 placeholder="Title" required></div>
                    <div class="col-md-2"><input class="form-control form-control-sm" name="videoUrl"
                                                 aria-label="YouTube video URL"
                                                 placeholder="YouTube URL"></div>
                    <div class="col-md-2"><input class="form-control form-control-sm" name="meetingUrl"
                                                 aria-label="Meet or Zoom URL"
                                                 placeholder="Meet/Zoom URL"></div>
                    <div class="col-md-1">
                        <button class="btn btn-primary btn-sm w-100" type="submit">Save</button>
                    </div>
                </form>
                <p class="small text-muted mt-2 mb-0">To edit, include the existing lecture ID.</p>
                <div class="sarvam-table-wrap mt-3">
                    <table class="table table-hover table-sm mb-0">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Course</th>
                            <th>Title</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="l : ${lectures}">
                            <td th:text="${l.lectureId}"></td>
                            <td th:text="${l.courseId}"></td>
                            <td th:text="${l.title}"></td>
                            <td>
                                <form th:action="@{'/teacher/lecture/delete/' + ${l.lectureId}}" method="post"
                                      class="d-inline">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'notes'}">
                <h2 class="h6 fw-bold mb-3">Add / update note</h2>
                <form method="post" action="/teacher/note/save" class="row g-2 align-items-end">
                    <div class="col-md-2"><input class="form-control form-control-sm" name="noteId"
                                                 aria-label="Note ID (optional)"
                                                 placeholder="ID (optional)"></div>
                    <div class="col-md-2"><input class="form-control form-control-sm" name="courseId"
                                                 aria-label="Course ID"
                                                 placeholder="Course ID" required></div>
                    <div class="col-md-4"><input class="form-control form-control-sm" name="title"
                                                 aria-label="Note title"
                                                 placeholder="Title" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="fileUrl"
                                                 aria-label="File URL"
                                                 placeholder="File URL" required></div>
                    <div class="col-md-1">
                        <button class="btn btn-primary btn-sm w-100" type="submit">Save</button>
                    </div>
                </form>
                <div class="sarvam-table-wrap mt-3">
                    <table class="table table-hover table-sm mb-0">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Course</th>
                            <th>Title</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="n : ${notes}">
                            <td th:text="${n.noteId}"></td>
                            <td th:text="${n.courseId}"></td>
                            <td th:text="${n.title}"></td>
                            <td>
                                <form th:action="@{'/teacher/note/delete/' + ${n.noteId}}" method="post" class="d-inline">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'quizzes'}">
                <h2 class="h6 fw-bold mb-3">Add / update quiz</h2>
                <form method="post" action="/teacher/quiz/save" class="row g-2">
                    <div class="col-md-2"><input class="form-control form-control-sm" name="quizId"
                                                 aria-label="Quiz ID (optional)"
                                                 placeholder="ID (optional)"></div>
                    <div class="col-md-2"><input class="form-control form-control-sm" name="courseId"
                                                 aria-label="Course ID"
                                                 placeholder="Course ID" required></div>
                    <div class="col-md-8"><input class="form-control form-control-sm" name="question"
                                                 aria-label="Quiz question"
                                                 placeholder="Question" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="optionA"
                                                 aria-label="Option A"
                                                 placeholder="A" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="optionB"
                                                 aria-label="Option B"
                                                 placeholder="B" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="optionC"
                                                 aria-label="Option C"
                                                 placeholder="C" required></div>
                    <div class="col-md-3"><input class="form-control form-control-sm" name="optionD"
                                                 aria-label="Option D"
                                                 placeholder="D" required></div>
                    <div class="col-md-10"><input class="form-control form-control-sm" name="correctOption"
                                                  aria-label="Correct option (A/B/C/D)"
                                                  placeholder="Correct (A/B/C/D)" required></div>
                    <div class="col-md-2">
                        <button class="btn btn-primary btn-sm w-100" type="submit">Save</button>
                    </div>
                </form>
                <div class="sarvam-table-wrap mt-3">
                    <table class="table table-hover table-sm mb-0">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Course</th>
                            <th>Question</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="q : ${quizzes}">
                            <td th:text="${q.quizId}"></td>
                            <td th:text="${q.courseId}"></td>
                            <td th:text="${q.question}"></td>
                            <td>
                                <form th:action="@{'/teacher/quiz/delete/' + ${q.quizId}}" method="post" class="d-inline">
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="sarvam-panel" th:if="${activeTab == 'students'}">
                <h2 class="h6 fw-bold mb-3">Enrolled students</h2>
                <div class="sarvam-table-wrap">
                    <table class="table table-hover table-sm mb-0">
                        <thead>
                        <tr>
                            <th>Enrollment</th>
                            <th>Student</th>
                            <th>Course</th>
                            <th>Enrolled</th>
                        </tr>
                        </thead>
                        <tbody>
                        <tr th:each="s : ${students}">
                            <td th:text="${s.enrollmentId}"></td>
                            <td th:text="${s.studentId}"></td>
                            <td th:text="${s.courseId}"></td>
                            <td th:text="${s.enrolledAt}"></td>
                        </tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </main>
    </div>
</div>
</body>
</html>

```

## B.4 Static Assets (CSS)


## `src/main/resources/static/css/sarvam-theme.css`

```css
/* Sarvam Professional Education — unified UI theme */

@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap');

:root {
    --font-sans: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
    --color-bg: #eef2f7;
    --color-bg-elevated: #f8fafc;
    --color-surface: #ffffff;
    --color-primary: #2563eb;
    --color-primary-soft: #eff6ff;
    --color-primary-dark: #1d4ed8;
    --color-accent: #0d9488;
    --color-text: #0f172a;
    --color-muted: #64748b;
    --color-border: #e2e8f0;
    --color-success: #059669;
    --shadow-sm: 0 1px 2px rgba(15, 23, 42, 0.05);
    --shadow-md: 0 4px 6px -1px rgba(15, 23, 42, 0.07), 0 2px 4px -2px rgba(15, 23, 42, 0.05);
    --shadow-lg: 0 10px 40px -10px rgba(15, 23, 42, 0.12);
    --radius: 12px;
    --radius-lg: 16px;
    --space-page: clamp(16px, 3vw, 24px);
}

*,
*::before,
*::after {
    box-sizing: border-box;
}

html {
    font-size: 16px;
    -webkit-font-smoothing: antialiased;
}

body.sarvam-app {
    margin: 0;
    min-height: 100vh;
    font-family: var(--font-sans), sans-serif;
    font-size: 0.9375rem;
    line-height: 1.5;
    color: var(--color-text);
    background: var(--color-bg);
}

/* ——— Auth pages (login, signup, change password, landing) ——— */
.sarvam-auth-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--space-page);
    background: radial-gradient(ellipse 120% 80% at 50% -20%, rgba(37, 99, 235, 0.12), transparent 50%),
    radial-gradient(ellipse 80% 50% at 100% 100%, rgba(13, 148, 136, 0.08), transparent 45%),
    var(--color-bg);
}

.sarvam-auth-card {
    width: 100%;
    max-width: 440px;
    background: var(--color-surface);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-lg);
    border: 1px solid var(--color-border);
    padding: 2rem 2.25rem;
}

.sarvam-auth-card h1,
.sarvam-auth-card h3 {
    font-weight: 700;
    font-size: 1.5rem;
    letter-spacing: -0.02em;
    color: var(--color-text);
    margin-bottom: 1.5rem;
    text-align: center;
}

.sarvam-auth-card label,
.sarvam-auth-card .form-label {
    font-weight: 500;
    font-size: 0.875rem;
    color: var(--color-muted);
    margin-bottom: 0.35rem;
}

.sarvam-auth-card .form-control,
.sarvam-auth-card .form-select {
    border-radius: var(--radius);
    border-color: var(--color-border);
    padding: 0.6rem 0.85rem;
    font-size: 0.9375rem;
}

.sarvam-auth-card .form-control:focus,
.sarvam-auth-card .form-select:focus {
    border-color: var(--color-primary);
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
}

/* Home page (marketing landing) */
.sarvam-home-page {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    background: radial-gradient(ellipse 90% 50% at 50% -15%, rgba(37, 99, 235, 0.12), transparent 55%),
    radial-gradient(ellipse 50% 40% at 0% 100%, rgba(13, 148, 136, 0.08), transparent 50%),
    var(--color-bg);
}

.sarvam-home-nav {
    position: sticky;
    top: 0;
    z-index: 50;
    background: rgba(255, 255, 255, 0.85);
    backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
}

.sarvam-home-nav-inner {
    max-width: 1120px;
    margin: 0 auto;
    padding: 0.75rem var(--space-page);
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem 1rem;
}

/* Brand left; Login + Sign Up right */
.sarvam-home-brand {
    display: inline-flex;
    align-items: center;
    gap: 0.65rem;
    text-decoration: none;
    color: var(--color-text);
    font-weight: 700;
    font-size: 1.05rem;
    letter-spacing: -0.02em;
    flex-shrink: 0;
}

.sarvam-home-brand-text {
    white-space: nowrap;
}

@media (max-width: 520px) {
    .sarvam-home-brand-text {
        white-space: normal;
        max-width: 12rem;
        line-height: 1.25;
    }
}

.sarvam-home-logo-wrap {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    box-shadow: var(--shadow-sm);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 4px;
    overflow: hidden;
}

.sarvam-home-logo-wrap img {
    width: 100%;
    height: 100%;
    object-fit: contain;
}

.sarvam-home-nav-links {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 0.5rem;
    flex-wrap: wrap;
    margin: 0;
    padding: 0;
    list-style: none;
    flex-shrink: 0;
    margin-left: auto;
}

.sarvam-home-nav-links .btn-sarvam-primary,
.sarvam-home-nav-links .btn-sarvam-secondary {
    padding: 0.5rem 1.1rem;
    font-size: 0.875rem;
    border-radius: 10px;
}

@media (max-width: 640px) {
    .sarvam-home-nav-inner {
        flex-direction: column;
        align-items: stretch;
    }

    .sarvam-home-nav-links {
        width: 100%;
        margin-left: 0;
        justify-content: flex-end;
    }
}

.sarvam-home-main {
    flex: 1;
    max-width: 1120px;
    margin: 0 auto;
    padding: 2rem var(--space-page) 3rem;
    width: 100%;
}

.sarvam-home-hero {
    display: grid;
    grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr);
    gap: 2.5rem;
    align-items: center;
    margin-bottom: 3rem;
}

@media (max-width: 900px) {
    .sarvam-home-hero {
        grid-template-columns: 1fr;
    }
}

.sarvam-home-hero-copy h1 {
    font-size: clamp(1.85rem, 4vw, 2.5rem);
    font-weight: 700;
    letter-spacing: -0.03em;
    line-height: 1.2;
    color: var(--color-text);
    margin: 0 0 1rem;
}

.sarvam-home-hero-copy .lead {
    font-size: 1.0625rem;
    color: var(--color-muted);
    margin-bottom: 1.25rem;
    max-width: 36rem;
}

.sarvam-home-badges {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-top: 1.25rem;
}

.sarvam-home-badge {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    padding: 0.35rem 0.65rem;
    border-radius: 999px;
    background: var(--color-primary-soft);
    color: var(--color-primary-dark);
}

.sarvam-home-hero-card {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1.5rem;
    box-shadow: var(--shadow-lg);
}

.sarvam-home-hero-card h2 {
    font-size: 0.8125rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--color-muted);
    margin: 0 0 1rem;
}

.sarvam-home-stat {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    padding: 0.65rem 0;
    border-bottom: 1px solid var(--color-border);
    font-size: 0.9375rem;
}

.sarvam-home-stat:last-child {
    border-bottom: 0;
}

.sarvam-home-stat strong {
    color: var(--color-primary);
    font-size: 1.125rem;
}

.sarvam-home-section-title {
    font-size: 1.25rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    margin: 0 0 1.25rem;
    color: var(--color-text);
}

.sarvam-home-features {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.25rem;
    margin-bottom: 2.5rem;
}

@media (max-width: 768px) {
    .sarvam-home-features {
        grid-template-columns: 1fr;
    }
}

.sarvam-home-feature {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1.35rem 1.25rem;
    box-shadow: var(--shadow-sm);
    transition: box-shadow 0.2s ease, border-color 0.2s ease;
}

.sarvam-home-feature:hover {
    box-shadow: var(--shadow-md);
    border-color: rgba(37, 99, 235, 0.25);
}

.sarvam-home-feature-icon {
    width: 44px;
    height: 44px;
    border-radius: var(--radius);
    background: var(--color-primary-soft);
    color: var(--color-primary);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.15rem;
    margin-bottom: 0.85rem;
}

.sarvam-home-feature h3 {
    font-size: 1rem;
    font-weight: 700;
    margin: 0 0 0.4rem;
    color: var(--color-text);
}

.sarvam-home-feature p {
    font-size: 0.875rem;
    color: var(--color-muted);
    margin: 0;
    line-height: 1.5;
}

.sarvam-home-about {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1.5rem 1.75rem;
    box-shadow: var(--shadow-sm);
}

.sarvam-home-about p {
    margin: 0;
    color: var(--color-muted);
    font-size: 0.9375rem;
    line-height: 1.65;
}

.sarvam-home-about p + p {
    margin-top: 0.75rem;
}

.sarvam-home-footer {
    margin-top: auto;
    padding: 1.25rem var(--space-page);
    text-align: center;
    font-size: 0.8125rem;
    color: var(--color-muted);
    border-top: 1px solid var(--color-border);
    background: rgba(255, 255, 255, 0.6);
}

/* Login: forgot password hint after failed attempt */
.sarvam-forgot-callout {
    background: var(--color-primary-soft);
    border: 1px solid rgba(37, 99, 235, 0.22);
    border-radius: var(--radius);
    padding: 1rem 1.1rem;
    margin-bottom: 1rem;
}

.sarvam-forgot-callout strong {
    display: block;
    font-size: 0.9375rem;
    margin-bottom: 0.35rem;
    color: var(--color-text);
}

.sarvam-forgot-callout p {
    font-size: 0.8125rem;
    color: var(--color-muted);
    margin: 0 0 0.75rem;
    line-height: 1.45;
}

/* Buttons */
.btn-sarvam-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.65rem 1.35rem;
    font-family: var(--font-sans), sans-serif;
    font-weight: 600;
    font-size: 0.9375rem;
    border-radius: var(--radius);
    border: none;
    background: linear-gradient(180deg, var(--color-primary) 0%, var(--color-primary-dark) 100%);
    color: #fff !important;
    text-decoration: none;
    box-shadow: 0 2px 4px rgba(37, 99, 235, 0.25);
    transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.btn-sarvam-primary:hover {
    color: #fff !important;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(37, 99, 235, 0.35);
}

.btn-sarvam-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.65rem 1.35rem;
    font-family: var(--font-sans), sans-serif;
    font-weight: 600;
    font-size: 0.9375rem;
    border-radius: var(--radius);
    border: 1px solid var(--color-border);
    background: var(--color-surface);
    color: var(--color-text) !important;
    text-decoration: none;
    box-shadow: var(--shadow-sm);
    transition: border-color 0.15s ease, background 0.15s ease;
}

.btn-sarvam-secondary:hover {
    border-color: var(--color-primary);
    background: var(--color-primary-soft);
    color: var(--color-primary-dark) !important;
}

.btn-sarvam-ghost {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
    padding: 0.5rem 1rem;
    font-family: var(--font-sans), sans-serif;
    font-weight: 600;
    font-size: 0.875rem;
    border-radius: var(--radius);
    border: 1px solid var(--color-border);
    background: transparent;
    color: var(--color-muted) !important;
    text-decoration: none;
    transition: color 0.15s ease, border-color 0.15s ease;
}

.btn-sarvam-ghost:hover {
    color: var(--color-text) !important;
    border-color: var(--color-muted);
}

.btn-sarvam-lg {
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    border-radius: 14px;
}

/* ——— Dashboard shell (student, teacher, admin) ——— */
.sarvam-shell {
    max-width: 1440px;
    margin: 0 auto;
    padding: var(--space-page);
    min-height: 100vh;
}

.sarvam-topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 1rem;
    padding: 0.875rem 1.25rem;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-sm);
    margin-bottom: 1rem;
}

.sarvam-brand {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    font-weight: 700;
    font-size: 1.05rem;
    letter-spacing: -0.02em;
    color: var(--color-text);
    text-decoration: none;
}

.sarvam-brand img {
    width: 48px;
    height: 48px;
    object-fit: contain;
    border-radius: 10px;
    border: 1px solid var(--color-border);
    padding: 4px;
    background: #fff;
}

.sarvam-topbar-actions {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 0.75rem 1rem;
}

.sarvam-greet {
    font-size: 0.9375rem;
    font-weight: 500;
    color: var(--color-text);
}

.sarvam-badge-role {
    display: inline-block;
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    padding: 0.35rem 0.75rem;
    border-radius: 999px;
    background: var(--color-primary-soft);
    color: var(--color-primary-dark);
}

.sarvam-layout {
    display: grid;
    grid-template-columns: 260px minmax(0, 1fr);
    gap: 1rem;
    align-items: start;
    min-height: calc(100vh - 120px);
}

.sarvam-sidebar {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1rem 0.75rem;
    box-shadow: var(--shadow-sm);
    position: sticky;
    top: var(--space-page);
}

.sarvam-sidebar-logo {
    padding: 0 0.75rem 1rem;
    margin-bottom: 0.75rem;
    border-bottom: 1px solid var(--color-border);
}

.sarvam-sidebar-logo img {
    width: 44px;
    height: 44px;
    object-fit: contain;
    border-radius: 8px;
}

.sarvam-nav-link {
    display: flex;
    align-items: center;
    gap: 0.65rem;
    padding: 0.65rem 0.85rem;
    margin-bottom: 0.25rem;
    border-radius: var(--radius);
    font-size: 0.9rem;
    font-weight: 500;
    color: var(--color-text);
    text-decoration: none;
    transition: background 0.15s ease, color 0.15s ease;
}

.sarvam-nav-link i {
    width: 1.25rem;
    text-align: center;
    opacity: 0.85;
    font-size: 0.95rem;
}

.sarvam-nav-link:hover {
    background: var(--color-primary-soft);
    color: var(--color-primary-dark);
}

.sarvam-nav-link.active {
    background: var(--color-primary-soft);
    color: var(--color-primary-dark);
    font-weight: 600;
}

.sarvam-main {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1.5rem 1.75rem 2rem;
    box-shadow: var(--shadow-sm);
    min-height: 420px;
}

.sarvam-page-title {
    font-size: clamp(1.5rem, 2.5vw, 1.85rem);
    font-weight: 700;
    letter-spacing: -0.02em;
    margin: 0 0 0.35rem;
    color: var(--color-text);
}

.sarvam-page-lead {
    font-size: 0.9375rem;
    color: var(--color-muted);
    margin: 0 0 1.5rem;
}

.sarvam-section-title {
    font-size: 1.1rem;
    font-weight: 700;
    margin: 0 0 1rem;
    color: var(--color-text);
}

/* KPI / stat cards */
.sarvam-kpi {
    background: var(--color-bg-elevated);
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    padding: 1.15rem 1.25rem;
    height: 100%;
    transition: box-shadow 0.15s ease;
}

.sarvam-kpi:hover {
    box-shadow: var(--shadow-md);
}

.sarvam-kpi-label {
    font-size: 0.8125rem;
    font-weight: 600;
    color: var(--color-muted);
    text-transform: uppercase;
    letter-spacing: 0.04em;
    margin-bottom: 0.35rem;
}

.sarvam-kpi-value {
    font-size: clamp(1.75rem, 3vw, 2.25rem);
    font-weight: 700;
    line-height: 1.15;
    color: var(--color-primary);
}

.sarvam-kpi-value.accent-teal {
    color: var(--color-accent);
}

.sarvam-kpi-value.accent-amber {
    color: #d97706;
}

/* Cards & tables */
.sarvam-panel {
    background: var(--color-bg-elevated);
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    padding: 1.25rem;
    margin-bottom: 1rem;
}

.sarvam-table-wrap {
    border-radius: var(--radius);
    border: 1px solid var(--color-border);
    overflow: hidden;
}

.sarvam-table-wrap .table {
    margin-bottom: 0;
    font-size: 0.875rem;
}

.sarvam-table-wrap .table thead th {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: var(--color-muted);
    font-weight: 600;
    background: var(--color-bg-elevated);
    border-bottom: 1px solid var(--color-border);
    padding: 0.65rem 0.85rem;
}

.sarvam-table-wrap .table td {
    padding: 0.65rem 0.85rem;
    vertical-align: middle;
}

/* Course cards (student buy) */
.sarvam-course-card {
    background: var(--color-bg-elevated);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1.25rem;
    height: 100%;
    display: flex;
    flex-direction: column;
    transition: box-shadow 0.2s ease, border-color 0.2s ease;
}

.sarvam-course-card:hover {
    border-color: rgba(37, 99, 235, 0.35);
    box-shadow: var(--shadow-md);
}

.sarvam-course-icon {
    width: 48px;
    height: 48px;
    border-radius: var(--radius);
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--color-primary-soft);
    color: var(--color-primary);
    font-size: 1.35rem;
    margin-bottom: 0.75rem;
}

.sarvam-price {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--color-text);
}

.btn-sarvam-buy {
    border: none;
    border-radius: 999px;
    padding: 0.5rem 1.15rem;
    font-weight: 600;
    font-size: 0.875rem;
    background: linear-gradient(180deg, #10b981 0%, #059669 100%);
    color: #fff;
    white-space: nowrap;
}

/* Student course (lectures) page */
.sarvam-narrow {
    max-width: 920px;
    margin: 0 auto;
    padding: var(--space-page);
}

.sarvam-content-block {
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1.25rem 1.5rem;
    box-shadow: var(--shadow-sm);
    margin-bottom: 1rem;
}

@media (max-width: 991px) {
    .sarvam-layout {
        grid-template-columns: 1fr;
    }

    .sarvam-sidebar {
        position: static;
    }
}

/* Align Bootstrap primary with theme */
body.sarvam-app .btn-primary {
    background-color: var(--color-primary);
    border-color: var(--color-primary-dark);
    font-weight: 600;
    border-radius: var(--radius);
}

body.sarvam-app .btn-primary:hover,
body.sarvam-app .btn-primary:focus {
    background-color: #1d4ed8;
    border-color: #1e40af;
}

body.sarvam-app .btn-outline-danger {
    border-radius: var(--radius);
    font-weight: 500;
}

body.sarvam-app .btn-success {
    border-radius: var(--radius);
    font-weight: 600;
}

```

## B.5 Tests


## `src/test/java/com/Sarvam/Professional/Education/SarvamElearningApplicationTests.java`

```java
package com.Sarvam.Professional.Education;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class SarvamElearningApplicationTests {

    @Test
    void contextLoads() {
    }
}

```


## `src/test/java/com/Sarvam/Professional/Education/controller/HomeControllerTest.java`

```java
package com.Sarvam.Professional.Education.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class HomeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void rootRendersIndexView() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(view().name("index"));
    }

    @Test
    void loginPageIsPubliclyAccessible() throws Exception {
        mockMvc.perform(get("/login"))
                .andExpect(status().isOk());
    }

    @Test
    void protectedRouteRedirectsAnonymousToLogin() throws Exception {
        mockMvc.perform(get("/student/dashboard"))
                .andExpect(status().is3xxRedirection());
    }
}

```


## `src/test/java/com/Sarvam/Professional/Education/util/PasswordPrefixUtilTest.java`

```java
package com.Sarvam.Professional.Education.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class PasswordPrefixUtilTest {

    @Test
    void plainTextPasswordGetsNoopPrefix() {
        assertEquals("{noop}password123", PasswordPrefixUtil.normalize("password123"));
    }

    @Test
    void bcryptHashGetsBcryptPrefix() {
        String hash = "$2a$10$abcdefghijklmnopqrstuvabcdefghijklmnopqrstuvwxyz0123456";
        assertEquals("{bcrypt}" + hash, PasswordPrefixUtil.normalize(hash));
    }

    @Test
    void alreadyPrefixedPasswordIsLeftAlone() {
        assertEquals("{noop}secret", PasswordPrefixUtil.normalize("{noop}secret"));
        assertEquals("{bcrypt}$2a$10$xyz", PasswordPrefixUtil.normalize("{bcrypt}$2a$10$xyz"));
    }

    @Test
    void nullInputReturnsNull() {
        assertNull(PasswordPrefixUtil.normalize(null));
    }
}

```
