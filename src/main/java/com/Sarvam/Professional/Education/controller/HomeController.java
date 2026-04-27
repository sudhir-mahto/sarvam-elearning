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