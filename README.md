# Sarvam Professional Education — E-Learning Platform

A full-stack e-learning web application built with **Spring Boot 3**, **Thymeleaf**, **Spring Security**, **JPA/Hibernate**, and **MySQL**. The platform supports three user roles — **Student**, **Teacher**, and **Admin** — each with a dedicated dashboard, role-based access control, and both server-rendered UI routes and JSON REST APIs.

> `com.sarvam:sarvam-elearning:1.0`

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Prerequisites](#prerequisites)
5. [Setup & Installation](#setup--installation)
6. [Running the Application](#running-the-application)
7. [Demo Accounts](#demo-accounts)
8. [Configuration](#configuration)
9. [Database Schema](#database-schema)
10. [Application Routes](#application-routes)
11. [REST API Reference](#rest-api-reference)
12. [Security Model](#security-model)
13. [Build & Packaging](#build--packaging)
14. [Logging](#logging)
15. [Troubleshooting](#troubleshooting)

---

## Features

### Authentication
- Sign up, log in, and change password flows
- Form-based login backed by Spring Security
- Role-based redirection after login (Student / Teacher / Admin)

### Student
- Personal dashboard showing enrollments, payment history, and available courses
- Buy a course via UPI reference — creates a `Payment` and an `Enrollment`
- Watch lectures (YouTube + Google Meet links), download notes (PDF), attempt quizzes
- Submit quiz answers and view computed results
- Contact support form

### Teacher
- Personal dashboard with owned courses, students enrolled, and performance overview
- Full CRUD for **courses**, **lectures**, **notes**, and **quizzes**
- View enrolled students per course (`My Students` section)

### Admin
- Global dashboard with system-wide counts (users, courses, payments, contacts)
- Full CRUD for **users**, **courses**
- **Verify payments** submitted by students
- Reply to support contact requests
- Reports section for high-level metrics

---

## Tech Stack

| Layer            | Technology                                 |
|------------------|--------------------------------------------|
| Language         | Java 17+                                   |
| Framework        | Spring Boot 3.2.5                          |
| Web              | Spring MVC + Thymeleaf templates           |
| Security         | Spring Security (form login, role-based)   |
| Persistence      | Spring Data JPA + Hibernate                |
| Database         | MySQL 8 (`mysql-connector-j`)              |
| Build            | Maven (Maven Wrapper included)             |
| Validation       | Jakarta Bean Validation (`spring-boot-starter-validation`) |
| Dev Productivity | Spring Boot DevTools                       |
| Testing          | JUnit 5 (`spring-boot-starter-test`)       |

---

## Project Structure

```
sarvam-elearning/
├── pom.xml                              # Maven build descriptor
├── mvnw / mvnw.cmd                      # Maven Wrapper scripts
├── PROJECT_CODES_REQUIRED.md            # Functional spec / route checklist
├── src/
│   ├── main/
│   │   ├── java/com/Sarvam/Professional/Education/
│   │   │   ├── SarvamElearningApplication.java   # @SpringBootApplication entry point
│   │   │   ├── config/
│   │   │   │   └── SecurityConfig.java           # Spring Security filter chain
│   │   │   ├── controller/
│   │   │   │   ├── HomeController.java           # `/`, `/login`, `/signup`, `/dashboard`
│   │   │   │   ├── AuthController.java           # Form-based auth flows
│   │   │   │   ├── AuthApiController.java        # JSON auth APIs
│   │   │   │   ├── StudentController.java        # Student UI + APIs
│   │   │   │   ├── TeacherController.java        # Teacher UI + APIs
│   │   │   │   ├── AdminController.java          # Admin UI + APIs
│   │   │   │   └── ApiExceptionHandler.java      # @ControllerAdvice for API errors
│   │   │   ├── dto/
│   │   │   │   ├── SignUpRequest.java
│   │   │   │   ├── LoginRequest.java
│   │   │   │   ├── ChangePasswordRequest.java
│   │   │   │   ├── BuyCourseRequest.java
│   │   │   │   ├── QuizSubmitRequest.java
│   │   │   │   └── ContactReplyRequest.java
│   │   │   ├── model/
│   │   │   │   ├── User.java        Role.java
│   │   │   │   ├── Course.java      Lecture.java   Note.java
│   │   │   │   ├── Quiz.java        Result.java
│   │   │   │   ├── Enrollment.java  Payment.java
│   │   │   │   └── Contact.java
│   │   │   ├── repository/                         # Spring Data JPA repositories
│   │   │   └── service/
│   │   │       └── UserService.java
│   │   └── resources/
│   │       ├── application.properties              # All app config
│   │       ├── data.sql                            # Demo / seed data (idempotent)
│   │       ├── templates/                          # Thymeleaf views
│   │       │   ├── index.html        login.html        signup.html
│   │       │   ├── change-password.html
│   │       │   ├── student-dashboard.html  student-course.html
│   │       │   ├── teacher-dashboard.html
│   │       │   └── admin-dashboard.html
│   │       └── static/
│   │           ├── css/sarvam-theme.css
│   │           └── images/sarvam-logo.png
│   └── test/java/.../SarvamElearningApplicationTests.java
└── target/                              # Maven build output
```

---

## Prerequisites

- **Java 17** (pinned via `<java.version>17</java.version>` in `pom.xml`)
- **MySQL 8** running locally on `localhost:3306`
- **Maven** — *not required* if you use the bundled wrapper (`./mvnw`)

---

## Setup & Installation

### 1. Clone the repository

```bash
git clone <your-repo-url> sarvam-elearning
cd sarvam-elearning
```

### 2. Create the MySQL database

The application is configured to connect to a database named `sarvam_db` with user `root` / password `root1234`. Either match those defaults or update `application.properties` (see [Configuration](#configuration)).

```sql
CREATE DATABASE sarvam_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

> Tables are auto-created by Hibernate on first run (`spring.jpa.hibernate.ddl-auto=update`).
> Seed data in `src/main/resources/data.sql` is loaded automatically on every startup using `INSERT IGNORE`, so it is safe to re-run.

### 3. (Optional) Adjust `application.properties`

Edit `src/main/resources/application.properties` if your local MySQL credentials differ from the defaults.

---

## Running the Application

Using the Maven Wrapper (recommended — no separate Maven install needed):

```bash
# macOS / Linux
./mvnw spring-boot:run

# Windows
mvnw.cmd spring-boot:run
```

Or with a system Maven install:

```bash
mvn spring-boot:run
```

On successful startup the console prints:

```
✅ Sarvam Professional Education Started Successfully!
🌐 Open Browser → http://localhost:8080
```

Visit **http://localhost:8080** in a browser.

---

## Demo Accounts

All demo accounts share the password **`password123`**. They are seeded automatically by `data.sql`.

| Role    | Email                  | Password      |
|---------|------------------------|---------------|
| Admin   | `admin@demo.sarvam`    | `password123` |
| Teacher | `teacher@demo.sarvam`  | `password123` |
| Student | `student@demo.sarvam`  | `password123` |

The seed dataset also includes 3 courses, 2 enrollments, 2 payments, lectures, notes, a quiz with a sample result, and two contact-support entries — enough to exercise every dashboard out of the box.

---

## Configuration

Key properties in `src/main/resources/application.properties`:

| Property                                   | Default                                      | Notes                                |
|--------------------------------------------|----------------------------------------------|--------------------------------------|
| `server.port`                              | `8080`                                       | HTTP port                            |
| `spring.datasource.url`                    | `jdbc:mysql://localhost:3306/sarvam_db?...`  | JDBC URL                             |
| `spring.datasource.username`               | `root`                                       | DB user                              |
| `spring.datasource.password`               | `root1234`                                   | DB password                          |
| `spring.jpa.hibernate.ddl-auto`            | `update`                                     | Auto-create / migrate schema         |
| `spring.sql.init.mode`                     | `always`                                     | Always run `data.sql` on startup     |
| `spring.jpa.defer-datasource-initialization` | `true`                                     | Run `data.sql` *after* JPA DDL       |
| `spring.thymeleaf.cache`                   | `false`                                      | Hot-reload templates in dev          |
| `spring.devtools.restart.enabled`          | `false`                                      | DevTools restart kept off by default |
| `spring.servlet.multipart.max-file-size`   | `10MB`                                       | Reserved for future upload features  |

---

## Database Schema

JPA entities map to the following tables (created automatically):

| Table         | Entity        | Purpose                                                |
|---------------|---------------|--------------------------------------------------------|
| `users`       | `User`        | Accounts; `role` ∈ {ADMIN, TEACHER, STUDENT}; `active` |
| `courses`     | `Course`      | Course catalog (title, price, instructor, thumbnail)   |
| `lectures`    | `Lecture`     | Per-course videos / live meeting links                 |
| `notes`       | `Note`        | Per-course downloadable PDFs                           |
| `quiz`        | `Quiz`        | MCQ items with `option_a..d` and `correct_option`      |
| `results`     | `Result`      | Student quiz attempts (totals, %)                      |
| `enrollments` | `Enrollment`  | (student_id, course_id) join with `enrolled_at`        |
| `payments`    | `Payment`     | UPI reference, amount, status, invoice number          |
| `contact`     | `Contact`     | Support requests with optional admin reply             |

`Role` is a Java enum: `STUDENT`, `TEACHER`, `ADMIN`.

---

## Application Routes

### Public (Thymeleaf)

| Method | Path               | Description                       |
|--------|--------------------|-----------------------------------|
| GET    | `/`                | Home / landing page               |
| GET    | `/login`           | Login page                        |
| GET    | `/signup`          | Sign-up page                      |
| GET    | `/change-password` | Change password page              |
| GET    | `/dashboard`       | Post-login redirect by role       |

### Student (`ROLE_STUDENT`)

| Method | Path                        | Description                                     |
|--------|-----------------------------|-------------------------------------------------|
| GET    | `/student/dashboard`        | Dashboard: enrollments, payments, courses, etc. |
| POST   | `/student/buy-course`       | Purchase a course (UPI ref required)            |
| POST   | `/student/contact`          | Submit a support / contact request              |

### Teacher (`ROLE_TEACHER`)

| Method | Path                              | Description           |
|--------|-----------------------------------|-----------------------|
| GET    | `/teacher/dashboard`              | Teacher dashboard     |
| POST   | `/teacher/course/save`            | Create / update course|
| POST   | `/teacher/course/delete/{courseId}`     | Delete course         |
| POST   | `/teacher/lecture/save`           | Create / update lecture |
| POST   | `/teacher/lecture/delete/{lectureId}`   | Delete lecture        |
| POST   | `/teacher/note/save`              | Create / update note  |
| POST   | `/teacher/note/delete/{noteId}`         | Delete note           |
| POST   | `/teacher/quiz/save`              | Create / update quiz  |
| POST   | `/teacher/quiz/delete/{quizId}`         | Delete quiz           |

### Admin (`ROLE_ADMIN`)

| Method | Path                              | Description                      |
|--------|-----------------------------------|----------------------------------|
| GET    | `/admin/dashboard`                | Admin dashboard with reports     |
| POST   | `/admin/user/save`                | Create / update user             |
| POST   | `/admin/user/delete/{userId}`        | Delete user                      |
| POST   | `/admin/course/delete/{courseId}`    | Delete course                    |
| POST   | `/admin/payment/verify/{paymentId}`  | Mark a payment as verified       |
| POST   | `/admin/contact/reply/{contactId}`   | Reply to a contact request       |

---

## REST API Reference

All endpoints accept and return `application/json`.

### Authentication — `/api/auth/**` (public)

| Method | Path                          | Body                                            | Returns                        |
|--------|-------------------------------|-------------------------------------------------|--------------------------------|
| POST   | `/api/auth/signup`            | `SignUpRequest`                                 | Created user / status          |
| POST   | `/api/auth/login`             | `LoginRequest`                                  | `{ role, redirectTo, ... }`    |
| POST   | `/api/auth/change-password`   | `ChangePasswordRequest`                         | Status                         |

`redirectTo` from `/api/auth/login`:
- `STUDENT`  → `/student/dashboard`
- `TEACHER`  → `/teacher/dashboard`
- `ADMIN`    → `/admin/dashboard`

### Student APIs — `/api/student/**`

| Method | Path                                 | Description                            |
|--------|--------------------------------------|----------------------------------------|
| GET    | `/api/student/dashboard/{studentId}` | Dashboard payload for a student        |
| GET    | `/api/student/courses`               | List available courses                 |
| POST   | `/api/student/buy-course`            | Purchase course (`BuyCourseRequest`)   |
| GET    | `/api/student/lectures/{courseId}`   | Lectures for a course                  |
| GET    | `/api/student/notes/{courseId}`      | Notes for a course                     |
| GET    | `/api/student/quiz/{courseId}`       | Quiz items for a course                |
| POST   | `/api/student/quiz/submit`           | Submit answers (`QuizSubmitRequest`)   |
| POST   | `/api/student/contact`               | Submit a support request               |

### Teacher APIs — `/api/teacher/**`

| Method | Path                          | Description                       |
|--------|-------------------------------|-----------------------------------|
| GET    | `/api/teacher/dashboard`      | Teacher dashboard payload         |
| GET    | `/api/teacher/courses`        | List courses owned by teacher     |
| POST   | `/api/teacher/courses`        | Create / update a course          |
| POST   | `/api/teacher/lectures`       | Create / update a lecture         |
| POST   | `/api/teacher/notes`          | Create / update a note            |
| POST   | `/api/teacher/quiz`           | Create / update a quiz item       |
| GET    | `/api/teacher/students`       | Students enrolled in own courses  |
| GET    | `/api/teacher/performance`    | Aggregated performance metrics    |

### Admin APIs — `/api/admin/**`

| Method | Path                                       | Description                       |
|--------|--------------------------------------------|-----------------------------------|
| GET    | `/api/admin/dashboard`                     | System overview                   |
| GET    | `/api/admin/users`                         | List all users                    |
| PUT    | `/api/admin/users/{userId}`                | Update a user                     |
| GET    | `/api/admin/courses`                       | List all courses                  |
| GET    | `/api/admin/payments`                      | List all payments                 |
| PUT    | `/api/admin/payments/{paymentId}/verify`   | Verify a payment                  |
| GET    | `/api/admin/reports`                       | Aggregated counts / KPIs          |
| GET    | `/api/admin/contacts`                      | List contact / support requests   |
| PUT    | `/api/admin/contacts/{contactId}/reply`    | Post an admin reply               |

### Error responses

`ApiExceptionHandler` (`@ControllerAdvice`) maps thrown exceptions to consistent JSON error payloads.

### Example request

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@demo.sarvam","password":"password123"}'
```

---

## Security Model

Defined in `config/SecurityConfig.java`:

- **Public routes:** `/`, `/login`, `/signup`, `/change-password`, `/css/**`, `/images/**`, `/api/auth/**`
- **Role-protected routes:**
  - `/student/**` → `ROLE_STUDENT`
  - `/teacher/**` → `ROLE_TEACHER`
  - `/admin/**`   → `ROLE_ADMIN`
- **Form login:** custom page at `/login`, posts to `/login`, uses `email` + `password` parameters; success redirects to `/dashboard`, failure to `/login?error`.
- **CSRF:** disabled (project is intended for local / academic use; re-enable for production).
- **Password storage:** `DelegatingPasswordEncoder` with `NoOpPasswordEncoder` as the default-for-matches. The custom `UserDetailsService` auto-prefixes stored passwords with `{noop}` (or `{bcrypt}` for hashed values) so that legacy plain-text demo passwords coexist with future BCrypt-hashed credentials.

> ⚠️ Plain-text passwords are intentional for the demo dataset only. For any non-academic use, hash all stored passwords with BCrypt and remove the `{noop}` fallback.

---

## Build & Packaging

Build a runnable fat JAR:

```bash
./mvnw clean package
java -jar target/sarvam-elearning-1.0.jar
```

Run tests:

```bash
./mvnw test
```

---

## Logging

- Console-only output at `INFO`, with application packages (`com.sarvam`) at `DEBUG`.
- Hibernate SQL logging is **disabled** by default (`logging.level.org.hibernate.SQL=OFF`); enable it temporarily for debugging by setting `spring.jpa.show-sql=true` or raising the Hibernate log level.

---

## Troubleshooting

**`Communications link failure` / DB connection errors**
Ensure MySQL is running on `localhost:3306` and that `sarvam_db` exists. Verify the credentials in `application.properties`.

**`Table 'sarvam_db.users' doesn't exist`**
Start the app once with `spring.jpa.hibernate.ddl-auto=update` (the default) so Hibernate can create the schema before `data.sql` runs.

**Login keeps failing for demo users**
Re-run the app — `data.sql` uses `INSERT IGNORE`, so existing rows are preserved. If you previously changed a demo password, reset that user row directly in MySQL or sign up a new account.

**Templates not refreshing**
`spring.thymeleaf.cache` is `false` so edits to `.html` files reload on the next request. If they don't, ensure you're editing the file under `src/main/resources/templates/` and not a copy under `target/`.

**Port `8080` already in use**
Change `server.port` in `application.properties`, or stop the conflicting process.

---

## Project Info

- **Project name:** Sarvam Professional Education
- **Version:** 1.0
- **Year:** 2026
