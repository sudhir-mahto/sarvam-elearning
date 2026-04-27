# Sarvam Professional Education — Codes Required for Programming

This document is the **functional reference / API catalogue** for the Sarvam Professional Education e-learning platform. It enumerates every UI route, REST endpoint, request payload, and database table the application exposes — useful as a viva / report appendix and as a contract for frontend integration.

> Stack: Spring Boot 3.3.5 · Spring Security · Spring Data JPA · Thymeleaf · MySQL 8 · Java 17

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Connection Layer (Frontend ↔ Backend ↔ Database)](#2-connection-layer-frontend--backend--database)
3. [Application Start (Home Screen)](#3-application-start-home-screen)
4. [User Authentication](#4-user-authentication)
5. [Redirect Logic After Login](#5-redirect-logic-after-login)
6. [Student Module](#6-student-module)
7. [Teacher Module](#7-teacher-module)
8. [Admin Module](#8-admin-module)
9. [Database Tables Implemented](#9-database-tables-implemented)
10. [Request DTOs (Wire Format)](#10-request-dtos-wire-format)
11. [HTTP Status & Error Handling](#11-http-status--error-handling)
12. [End-to-End Flows](#12-end-to-end-flows)

---

## 1. System Overview

The platform is a 3-tier web application:

```
┌────────────────────┐    HTTPS / Form POST + JSON     ┌────────────────────┐    JDBC     ┌─────────────────┐
│  Browser / Client  │ ─────────────────────────────▶ │   Spring Boot App   │ ──────────▶ │   MySQL 8       │
│  (Thymeleaf HTML   │ ◀───────────────────────────── │   (port 8080)       │ ◀────────── │   sarvam_db     │
│   + fetch() calls) │       HTML / JSON              │                     │             │                 │
└────────────────────┘                                 └────────────────────┘             └─────────────────┘
```

Three primary user roles are enforced by Spring Security: **STUDENT**, **TEACHER**, **ADMIN**. Each role has both a server-rendered Thymeleaf dashboard *and* a parallel JSON API surface so the same backend can power a future SPA / mobile client.

---

## 2. Connection Layer (Frontend ↔ Backend ↔ Database)

### Backend → Database

| Setting        | Value                                                     |
|----------------|-----------------------------------------------------------|
| Driver         | `com.mysql.cj.jdbc.Driver`                                |
| JDBC URL       | `jdbc:mysql://localhost:3306/sarvam_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC` |
| Username       | `root`                                                    |
| Password       | `root1234` *(default — change in `application.properties`)* |
| ORM            | Spring Data JPA + Hibernate (`spring.jpa.hibernate.ddl-auto=update`) |
| Seed loader    | `src/main/resources/data.sql` (idempotent `INSERT IGNORE`) |

### Frontend → Backend

- **Base URL:** `http://localhost:8080`
- **API prefix:** `/api`
- **Auth-protected APIs:** require an authenticated session cookie (Spring Security form login). Public endpoints live under `/api/auth/**`.

#### Reusable JS helper (use from any Thymeleaf page)

```javascript
const API_BASE = "http://localhost:8080/api";

async function apiRequest(method, path, body) {
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: { "Content-Type": "application/json" },
    credentials: "include",                        // send session cookie
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message || `HTTP ${res.status}`);
  return data;
}

export const apiGet  = (path)        => apiRequest("GET",  path);
export const apiPost = (path, body)  => apiRequest("POST", path, body);
export const apiPut  = (path, body)  => apiRequest("PUT",  path, body);
```

---

## 3. Application Start (Home Screen)

| Method | Path  | Auth   | Purpose                                              |
|--------|-------|--------|------------------------------------------------------|
| GET    | `/`   | public | Landing page rendered by `templates/index.html`      |

The home page exposes three primary call-to-actions:

1. **Login** → `/login`
2. **Sign Up** → `/signup`
3. **Change Password** → `/change-password`

---

## 4. User Authentication

All auth APIs are public (no session required) and live under `/api/auth/**`. Form-login endpoints under `/login` are also public.

### 4.1 Sign Up — `POST /api/auth/signup`

Creates a new user account. The `role` field accepts `STUDENT`, `TEACHER`, or `ADMIN`.

**Request body** (`SignUpRequest`)
```json
{
  "name":     "Aarav Singh",
  "email":    "aarav@example.com",
  "password": "Secret@123",
  "role":     "STUDENT"
}
```

**Success — 200 OK**
```json
{ "status": "ok", "userId": 7, "role": "STUDENT" }
```

**Failure — 400/409**
```json
{ "status": "error", "message": "Email already registered" }
```

### 4.2 Login — `POST /api/auth/login`

**Request body** (`LoginRequest`)
```json
{ "email": "student@demo.sarvam", "password": "password123" }
```

**Success — 200 OK**
```json
{
  "status":     "ok",
  "userId":     3,
  "name":       "Rahul Verma",
  "role":       "STUDENT",
  "redirectTo": "/student/dashboard"
}
```

> Form-login alternative: `POST /login` with `application/x-www-form-urlencoded` parameters `email` + `password`. On success Spring Security redirects to `/dashboard`, which then forwards to the role-specific dashboard.

### 4.3 Change Password — `POST /api/auth/change-password`

```json
{
  "email":       "student@demo.sarvam",
  "oldPassword": "password123",
  "newPassword": "NewSecret@456"
}
```

---

## 5. Redirect Logic After Login

| Role      | Redirect target          |
|-----------|--------------------------|
| `STUDENT` | `/student/dashboard`     |
| `TEACHER` | `/teacher/dashboard`     |
| `ADMIN`   | `/admin/dashboard`       |

The redirect is computed both server-side (form login → `/dashboard` → role check) and is mirrored in the JSON `redirectTo` field returned by `POST /api/auth/login`.

---

## 6. Student Module

> All `/student/**` UI routes and `/api/student/**` JSON routes require `ROLE_STUDENT`.

### 6.1 Thymeleaf UI

| Method | Path                  | Description                                                    |
|--------|-----------------------|----------------------------------------------------------------|
| GET    | `/student/dashboard`  | Personal dashboard: enrollments table + payments table + course catalog + contact form |
| POST   | `/student/buy-course` | Buys a course (form POST, expects `courseId` + `upiRef`)       |
| POST   | `/student/contact`    | Submits a contact / support request                            |

### 6.2 JSON API

| Method | Path                                 | Body / Params              | Returns                                                     |
|--------|--------------------------------------|----------------------------|-------------------------------------------------------------|
| GET    | `/api/student/dashboard/{studentId}` | path: `studentId`          | `{ enrollments[], payments[], availableCourses[], results[] }` |
| GET    | `/api/student/courses`               | —                          | `[{ id, title, price, instructor, thumbnail }]`             |
| POST   | `/api/student/buy-course`            | `BuyCourseRequest`         | `{ status, paymentId, enrollmentId, invoiceNo }`            |
| GET    | `/api/student/lectures/{courseId}`   | path: `courseId`           | `[{ id, title, videoUrl, meetingUrl }]`                     |
| GET    | `/api/student/notes/{courseId}`      | path: `courseId`           | `[{ id, title, fileUrl }]`                                  |
| GET    | `/api/student/quiz/{courseId}`       | path: `courseId`           | `[{ id, question, optionA, optionB, optionC, optionD }]` *(no answers)* |
| POST   | `/api/student/quiz/submit`           | `QuizSubmitRequest`        | `{ totalQuestions, correctAnswers, percentage }` (also persisted to `results`) |
| POST   | `/api/student/contact`               | `{ name, email, phone, message }` | `{ status, contactId }`                                |

### 6.3 Buy-course flow

1. Student visits the dashboard, picks a course from "Available Courses".
2. Submits UPI reference via the buy-course form / API.
3. Backend creates a `Payment` row (status `SUCCESS`, generated `invoiceNo`) and an `Enrollment` row.
4. Admin can later mark the payment as `VERIFIED` (see §8).

---

## 7. Teacher Module

> All `/teacher/**` UI routes and `/api/teacher/**` JSON routes require `ROLE_TEACHER`.

### 7.1 Thymeleaf UI

| Method | Path                              | Description                          |
|--------|-----------------------------------|--------------------------------------|
| GET    | `/teacher/dashboard`              | Owned courses + enrolled students + content CRUD forms |
| POST   | `/teacher/course/save`            | Create or update a course            |
| POST   | `/teacher/course/delete/{courseId}`     | Delete a course                      |
| POST   | `/teacher/lecture/save`           | Create or update a lecture           |
| POST   | `/teacher/lecture/delete/{lectureId}`   | Delete a lecture                     |
| POST   | `/teacher/note/save`              | Create or update a note              |
| POST   | `/teacher/note/delete/{noteId}`         | Delete a note                        |
| POST   | `/teacher/quiz/save`              | Create or update a quiz item         |
| POST   | `/teacher/quiz/delete/{quizId}`         | Delete a quiz item                   |

> All `*/save` endpoints accept multipart form fields matching the underlying entity (e.g., for a course: `courseId` *(blank for new)*, `title`, `price`, `instructor`, `thumbnail`). For lectures use `lectureId`, for notes `noteId`, for quizzes `quizId`.

### 7.2 JSON API

| Method | Path                          | Body / Returns                                                    |
|--------|-------------------------------|-------------------------------------------------------------------|
| GET    | `/api/teacher/dashboard`      | `{ courses[], totalStudents, recentEnrollments[] }`               |
| GET    | `/api/teacher/courses`        | `[{ id, title, price, instructor, thumbnail }]`                   |
| POST   | `/api/teacher/courses`        | `Course` JSON → returns saved entity                              |
| POST   | `/api/teacher/lectures`       | `Lecture` JSON → returns saved entity                             |
| POST   | `/api/teacher/notes`          | `Note` JSON → returns saved entity                                |
| POST   | `/api/teacher/quiz`           | `Quiz` JSON (with `correctOption`) → returns saved entity         |
| GET    | `/api/teacher/students`       | `[{ studentId, name, email, courseId, enrolledAt }]`              |
| GET    | `/api/teacher/performance`    | `[{ courseId, courseTitle, attempts, avgPercentage }]`            |

---

## 8. Admin Module

> All `/admin/**` UI routes and `/api/admin/**` JSON routes require `ROLE_ADMIN`.

### 8.1 Thymeleaf UI

| Method | Path                              | Description                              |
|--------|-----------------------------------|------------------------------------------|
| GET    | `/admin/dashboard`                | KPIs + users / payments / contacts tables |
| POST   | `/admin/user/save`                | Create or update a user                  |
| POST   | `/admin/user/delete/{userId}`        | Delete a user                            |
| POST   | `/admin/course/delete/{courseId}`    | Delete any course                        |
| POST   | `/admin/payment/verify/{paymentId}`  | Mark a payment as `VERIFIED`             |
| POST   | `/admin/contact/reply/{contactId}`   | Reply to a support request               |

### 8.2 JSON API

| Method | Path                                       | Returns / Body                                          |
|--------|--------------------------------------------|---------------------------------------------------------|
| GET    | `/api/admin/dashboard`                     | Aggregated counts (users, courses, payments, contacts)  |
| GET    | `/api/admin/users`                         | All users                                               |
| PUT    | `/api/admin/users/{userId}`                | Update user (`User` JSON; supports `active=false` to disable) |
| GET    | `/api/admin/courses`                       | All courses                                             |
| GET    | `/api/admin/payments`                      | All payments with status                                |
| PUT    | `/api/admin/payments/{paymentId}/verify`   | Marks the payment `VERIFIED`                            |
| GET    | `/api/admin/reports`                       | High-level report card                                  |
| GET    | `/api/admin/contacts`                      | All contact / support requests                          |
| PUT    | `/api/admin/contacts/{contactId}/reply`    | `ContactReplyRequest` body                              |

---

## 9. Database Tables Implemented

Tables are auto-created by Hibernate from the JPA entities in `model/`. Schema is updated on every startup (`spring.jpa.hibernate.ddl-auto=update`).

> Convention: every table's primary key is named `<entity>_id` (e.g., `user_id`, `course_id`). Foreign keys keep the same name as the PK they reference, prefixed by role where ambiguous (e.g., `student_id` in `enrollments` references `users.user_id` because the user is acting *as a student*).

### 9.1 `users`

| Column     | Type           | Notes                                                  |
|------------|----------------|--------------------------------------------------------|
| `user_id`  | `BIGINT` PK    | Auto-increment                                         |
| `name`     | `VARCHAR`      | Display name                                           |
| `email`    | `VARCHAR`      | **Unique**, **not null**                               |
| `password` | `VARCHAR`      | Plain-text demo passwords; production should hash      |
| `role`     | `ENUM` (string)| One of `STUDENT`, `TEACHER`, `ADMIN`                   |
| `active`   | `BOOLEAN`      | Soft-disable flag                                      |

### 9.2 `courses`

| Column       | Type      | Notes                |
|--------------|-----------|----------------------|
| `course_id`  | `BIGINT`  | PK                   |
| `title`      | `VARCHAR` | Course title         |
| `price`      | `INT`     | Price in INR         |
| `instructor` | `VARCHAR` | Free-text name       |
| `thumbnail`  | `VARCHAR` | Optional image URL   |

### 9.3 `lectures`

| Column        | Type      | Notes                                       |
|---------------|-----------|---------------------------------------------|
| `lecture_id`  | `BIGINT`  | PK                                          |
| `course_id`   | `BIGINT`  | FK to `courses.course_id`                   |
| `title`       | `VARCHAR` |                                             |
| `video_url`   | `VARCHAR` | YouTube / Vimeo / etc.                      |
| `meeting_url` | `VARCHAR` | Optional Google Meet / Zoom link            |

### 9.4 `notes`

| Column      | Type      | Notes                                |
|-------------|-----------|--------------------------------------|
| `note_id`   | `BIGINT`  | PK                                   |
| `course_id` | `BIGINT`  | FK to `courses.course_id`            |
| `title`     | `VARCHAR` |                                      |
| `file_url`  | `VARCHAR` | Downloadable PDF / file URL          |

### 9.5 `quiz`

| Column           | Type      | Notes                                |
|------------------|-----------|--------------------------------------|
| `quiz_id`        | `BIGINT`  | PK                                   |
| `course_id`      | `BIGINT`  | FK to `courses.course_id`            |
| `question`       | `VARCHAR` |                                      |
| `option_a..d`    | `VARCHAR` | Four MCQ options                     |
| `correct_option` | `CHAR(1)` | One of `A`, `B`, `C`, `D`            |

### 9.6 `results`

| Column            | Type        | Notes                              |
|-------------------|-------------|------------------------------------|
| `result_id`       | `BIGINT`    | PK                                 |
| `student_id`      | `BIGINT`    | FK to `users.user_id`              |
| `course_id`       | `BIGINT`    | FK to `courses.course_id`          |
| `total_questions` | `INT`       |                                    |
| `correct_answers` | `INT`       |                                    |
| `percentage`      | `DOUBLE`    | Computed server-side               |
| `submitted_at`    | `DATETIME`  | Timestamp of submission            |

### 9.7 `enrollments`

| Column          | Type        | Notes                               |
|-----------------|-------------|-------------------------------------|
| `enrollment_id` | `BIGINT`    | PK                                  |
| `student_id`    | `BIGINT`    | FK to `users.user_id`               |
| `course_id`     | `BIGINT`    | FK to `courses.course_id`           |
| `enrolled_at`   | `DATETIME`  | Auto-set on insert                  |

### 9.8 `payments`

| Column       | Type        | Notes                                                       |
|--------------|-------------|-------------------------------------------------------------|
| `payment_id` | `BIGINT`    | PK                                                          |
| `invoice_no` | `VARCHAR`   | **Unique**, generated as `INV-` + 8 hex chars               |
| `student_id` | `BIGINT`    | FK to `users.user_id`                                       |
| `course_id`  | `BIGINT`    | FK to `courses.course_id`                                   |
| `upi_ref`    | `VARCHAR`   | Customer-supplied UPI reference                             |
| `amount`     | `DOUBLE`    | Amount paid (mirrors course price)                          |
| `status`     | `VARCHAR`   | `SUCCESS` (default) → `VERIFIED` once admin approves        |
| `paid_at`    | `DATETIME`  |                                                             |

### 9.9 `contact`

| Column        | Type        | Notes                                       |
|---------------|-------------|---------------------------------------------|
| `contact_id`  | `BIGINT`    | PK                                          |
| `name`        | `VARCHAR`   |                                             |
| `email`       | `VARCHAR`   |                                             |
| `phone`       | `VARCHAR`   |                                             |
| `message`     | `TEXT`      | The user's question                         |
| `admin_reply` | `VARCHAR`   | Set when an admin replies (null = pending)  |
| `created_at`  | `DATETIME`  |                                             |

---

## 10. Request DTOs (Wire Format)

Every JSON endpoint that accepts a body uses one of the following shapes from `dto/`.

### `SignUpRequest`
```json
{ "name": "string", "email": "string", "password": "string", "role": "STUDENT|TEACHER|ADMIN" }
```

### `LoginRequest`
```json
{ "email": "string", "password": "string" }
```

### `ChangePasswordRequest`
```json
{ "email": "string", "oldPassword": "string", "newPassword": "string" }
```

### `BuyCourseRequest`
```json
{ "studentId": 0, "courseId": 0, "upiRef": "string" }
```

### `QuizSubmitRequest`
```json
{
  "studentId": 0,
  "courseId":  0,
  "answers":   { "1": "A", "2": "C", "3": "B" }
}
```
> The `answers` map is keyed by **quiz item id** (string) → **selected option letter** (`A` / `B` / `C` / `D`).

### `ContactReplyRequest`
```json
{ "adminReply": "string" }
```

---

## 11. HTTP Status & Error Handling

`ApiExceptionHandler` (`@ControllerAdvice`) maps thrown exceptions to a consistent JSON envelope:

```json
{ "status": "error", "message": "Human-readable explanation" }
```

| Status | When                                                              |
|--------|-------------------------------------------------------------------|
| `200`  | Success (action completed; payload returned)                      |
| `400`  | Validation error / malformed request                              |
| `401`  | Not authenticated (session missing or expired)                    |
| `403`  | Authenticated but role is insufficient                            |
| `404`  | Entity not found (e.g., unknown course / user id)                 |
| `409`  | Conflict (e.g., duplicate email on signup)                        |
| `500`  | Unhandled server error                                            |

---

## 12. End-to-End Flows

These are the canonical user journeys exercised by the seed dataset and demo accounts. Use them as test scripts during demos / viva.

### 12.1 Student buys a course and takes the quiz

```
1. POST /api/auth/login  { student@demo.sarvam, password123 }      → 200 + redirectTo=/student/dashboard
2. GET  /api/student/courses                                       → list, pick course id 3
3. POST /api/student/buy-course  { studentId:3, courseId:3, upiRef:"UPI..." }
                                                                   → creates payment + enrollment
4. GET  /api/student/lectures/3                                    → watch
5. GET  /api/student/notes/3                                       → download
6. GET  /api/student/quiz/3                                        → render quiz (no answers)
7. POST /api/student/quiz/submit  { studentId:3, courseId:3, answers:{...} }
                                                                   → result row inserted
```

### 12.2 Teacher publishes content

```
1. POST /api/auth/login  { teacher@demo.sarvam, password123 }
2. POST /api/teacher/courses   { title:"...", price:799, instructor:"Priya Sharma" }
3. POST /api/teacher/lectures  { courseId, title, videoUrl }
4. POST /api/teacher/notes     { courseId, title, fileUrl }
5. POST /api/teacher/quiz      { courseId, question, optionA..D, correctOption:"A" }
6. GET  /api/teacher/students                                      → see who enrolled
7. GET  /api/teacher/performance                                   → average quiz scores
```

### 12.3 Admin verifies a payment and answers support

```
1. POST /api/auth/login  { admin@demo.sarvam, password123 }
2. GET  /api/admin/payments                                        → look for status="SUCCESS"
3. PUT  /api/admin/payments/{paymentId}/verify                     → status="VERIFIED"
4. GET  /api/admin/contacts                                        → list (admin_reply=null = pending)
5. PUT  /api/admin/contacts/{contactId}/reply  { adminReply:"..." }→ reply saved
6. GET  /api/admin/reports                                         → KPI snapshot
```

---

## Demo Accounts

All seeded accounts share password **`password123`**:

| Role    | Email                  |
|---------|------------------------|
| Admin   | `admin@demo.sarvam`    |
| Teacher | `teacher@demo.sarvam`  |
| Student | `student@demo.sarvam`  |
