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
