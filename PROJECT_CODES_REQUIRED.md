# Sarvam E-Learning - Codes Required for Programming

## 1) Connection Coding (Frontend <-> Backend <-> Database)

- Backend framework: Spring Boot + JPA + MySQL
- API base URL: `http://localhost:8080`
- Database configured in `src/main/resources/application.properties`

Example frontend API helper (JavaScript):

```javascript
const API_BASE = "http://localhost:8080/api";

export async function apiPost(path, body) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.message || "Request failed");
  return data;
}
```

## 2) Application Start (Home Screen)

- Home endpoint: `GET /`
- Returns startup options: Login, Sign Up, Change Password

## 3) User Authentication

- Sign Up (new user): `POST /api/auth/signup`
- Login (existing user): `POST /api/auth/login`
- Change Password: `POST /api/auth/change-password`

## 4) Redirect Logic After Login

`/api/auth/login` response contains:
- `role`: `STUDENT` / `TEACHER` / `ADMIN`
- `redirectTo`:
  - Student -> `/student/dashboard`
  - Teacher -> `/teacher/dashboard`
  - Admin -> `/admin/dashboard`

## 5) Student Dashboard

- UI Dashboard: `GET /student/dashboard`
- Button/feature routes (all functional):
  - Buy course: `POST /student/buy-course` (UPI ref required, creates payment + enrollment)
  - My Enrollments table: rendered on `/student/dashboard`
  - Payment history table: rendered on `/student/dashboard`
  - Contact support form: `POST /student/contact`
- API routes also available:
  - `GET /api/student/dashboard/{studentId}`
  - `GET /api/student/courses`
  - `POST /api/student/buy-course`
  - `GET /api/student/lectures/{courseId}`
  - `GET /api/student/notes/{courseId}`
  - `GET /api/student/quiz/{courseId}`
  - `POST /api/student/quiz/submit`
  - `POST /api/student/contact`

## 6) Teacher Dashboard

- UI Dashboard: `GET /teacher/dashboard`
- Button/CRUD routes (all functional):
  - Course create/update: `POST /teacher/course/save`
  - Course delete: `POST /teacher/course/delete/{id}`
  - Lecture create/update: `POST /teacher/lecture/save`
  - Lecture delete: `POST /teacher/lecture/delete/{id}`
  - Note create/update: `POST /teacher/note/save`
  - Note delete: `POST /teacher/note/delete/{id}`
  - Quiz create/update: `POST /teacher/quiz/save`
  - Quiz delete: `POST /teacher/quiz/delete/{id}`
  - Student enrollments list shown in dashboard (`My Students` section)
- API routes also available:
  - `GET /api/teacher/dashboard`
  - `POST /api/teacher/courses`, `GET /api/teacher/courses`
  - `POST /api/teacher/lectures`
  - `POST /api/teacher/notes`
  - `POST /api/teacher/quiz`
  - `GET /api/teacher/students`
  - `GET /api/teacher/performance`

## 7) Admin Dashboard

- UI Dashboard: `GET /admin/dashboard`
- Button/CRUD routes (all functional):
  - User create/update: `POST /admin/user/save`
  - User delete: `POST /admin/user/delete/{id}`
  - Course delete: `POST /admin/course/delete/{id}`
  - Payment verify: `POST /admin/payment/verify/{id}`
  - Contact reply: `POST /admin/contact/reply/{id}`
  - Reports section shows total counts in dashboard
- API routes also available:
  - `GET /api/admin/dashboard`
  - `GET /api/admin/users`, `PUT /api/admin/users/{id}`
  - `GET /api/admin/courses`
  - `GET /api/admin/payments`, `PUT /api/admin/payments/{id}/verify`
  - `GET /api/admin/reports`
  - `GET /api/admin/contacts`
  - `PUT /api/admin/contacts/{id}/reply`

## 8) Database Tables Implemented

- `users`
- `courses`
- `lectures`
- `enrollments`
- `payments`
- `notes`
- `quiz`
- `results`
- `contact`
