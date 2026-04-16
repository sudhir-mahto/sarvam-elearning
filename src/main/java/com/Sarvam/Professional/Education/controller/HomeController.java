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
import java.util.List;
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

    @GetMapping("/home")
    public String home() {
        return "index";           // yeh templates/index.html hoga
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
            studentId = user.getId();
            myEnrollments = enrollmentRepository.findByStudentId(user.getId());
            enrolledCount = myEnrollments.size();
            myPayments = paymentRepository.findByStudentId(user.getId());
            myContacts = contactRepository.findAll().stream()
                    .filter(c -> c.getEmail() != null && c.getEmail().equalsIgnoreCase(user.getEmail()))
                    .toList();
        }

        int hoursLearned = enrolledCount == 0 ? 24 : enrolledCount * 12;
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
        if (enrollmentRepository.existsByStudentIdAndCourseId(user.getId(), courseId)) {
            return "redirect:/student/dashboard";
        }

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new RuntimeException("Course not found"));
        Payment payment = new Payment();
        payment.setStudentId(user.getId());
        payment.setCourseId(courseId);
        payment.setAmount(course.getPrice());
        payment.setUpiRef(upiRef);
        payment.setStatus("SUCCESS");
        payment.setPaidAt(LocalDateTime.now());
        paymentRepository.save(payment);

        Enrollment enrollment = new Enrollment();
        enrollment.setStudentId(user.getId());
        enrollment.setCourseId(courseId);
        enrollment.setEnrolledAt(LocalDateTime.now());
        enrollmentRepository.save(enrollment);
        return "redirect:/student/dashboard";
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
        return "redirect:/student/dashboard";
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
    public String saveCourse(@RequestParam(required = false) Long id,
                             @RequestParam String title,
                             @RequestParam int price,
                             @RequestParam String instructor,
                             @RequestParam(required = false) String thumbnail) {
        Course course = id == null ? new Course() : courseRepository.findById(id).orElse(new Course());
        course.setTitle(title);
        course.setPrice(price);
        course.setInstructor(instructor);
        course.setThumbnail(thumbnail);
        courseRepository.save(course);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/course/delete/{id}")
    public String deleteCourse(@PathVariable Long id) {
        courseRepository.deleteById(id);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/lecture/save")
    public String saveLecture(@RequestParam(required = false) Long id,
                              @RequestParam Long courseId,
                              @RequestParam String title,
                              @RequestParam(required = false) String videoUrl,
                              @RequestParam(required = false) String meetingUrl) {
        Lecture lecture = id == null ? new Lecture() : lectureRepository.findById(id).orElse(new Lecture());
        lecture.setCourseId(courseId);
        lecture.setTitle(title);
        lecture.setVideoUrl(videoUrl);
        lecture.setMeetingUrl(meetingUrl);
        lectureRepository.save(lecture);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/lecture/delete/{id}")
    public String deleteLecture(@PathVariable Long id) {
        lectureRepository.deleteById(id);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/note/save")
    public String saveNote(@RequestParam(required = false) Long id,
                           @RequestParam Long courseId,
                           @RequestParam String title,
                           @RequestParam String fileUrl) {
        Note note = id == null ? new Note() : noteRepository.findById(id).orElse(new Note());
        note.setCourseId(courseId);
        note.setTitle(title);
        note.setFileUrl(fileUrl);
        noteRepository.save(note);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/note/delete/{id}")
    public String deleteNote(@PathVariable Long id) {
        noteRepository.deleteById(id);
        return "redirect:/teacher/dashboard";
    }

    @PostMapping("/teacher/quiz/save")
    public String saveQuiz(@RequestParam(required = false) Long id,
                           @RequestParam Long courseId,
                           @RequestParam String question,
                           @RequestParam String optionA,
                           @RequestParam String optionB,
                           @RequestParam String optionC,
                           @RequestParam String optionD,
                           @RequestParam String correctOption) {
        Quiz quiz = id == null ? new Quiz() : quizRepository.findById(id).orElse(new Quiz());
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

    @PostMapping("/teacher/quiz/delete/{id}")
    public String deleteQuiz(@PathVariable Long id) {
        quizRepository.deleteById(id);
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
    public String saveUser(@RequestParam(required = false) Long id,
                           @RequestParam String name,
                           @RequestParam String email,
                           @RequestParam Role role,
                           @RequestParam(defaultValue = "true") boolean active,
                           @RequestParam(required = false) String password) {
        User user = id == null ? new User() : userRepository.findById(id).orElse(new User());
        user.setName(name);
        user.setEmail(email);
        user.setRole(role);
        user.setActive(active);
        if (id == null) {
            String rawPassword = (password == null || password.isBlank()) ? "123456" : password;
            user.setPassword(passwordEncoder.encode(rawPassword));
        } else if (password != null && !password.isBlank()) {
            user.setPassword(passwordEncoder.encode(password));
        }
        userRepository.save(user);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/user/delete/{id}")
    public String deleteUser(@PathVariable Long id) {
        userRepository.deleteById(id);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/course/delete/{id}")
    public String adminDeleteCourse(@PathVariable Long id) {
        courseRepository.deleteById(id);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/payment/verify/{id}")
    public String verifyPayment(@PathVariable Long id) {
        Payment payment = paymentRepository.findById(id).orElseThrow(() -> new RuntimeException("Payment not found"));
        payment.setStatus("VERIFIED");
        paymentRepository.save(payment);
        return "redirect:/admin/dashboard";
    }

    @PostMapping("/admin/contact/reply/{id}")
    public String replyContact(@PathVariable Long id, @RequestParam String adminReply) {
        Contact contact = contactRepository.findById(id).orElseThrow(() -> new RuntimeException("Contact not found"));
        contact.setAdminReply(adminReply);
        contactRepository.save(contact);
        return "redirect:/admin/dashboard";
    }
}