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

    @PutMapping("/users/{id}")
    public User updateUser(@PathVariable Long id, @RequestBody User payload) {
        User user = userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
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

    @PutMapping("/payments/{id}/verify")
    public Payment verifyPayment(@PathVariable Long id) {
        Payment payment = paymentRepository.findById(id).orElseThrow(() -> new RuntimeException("Payment not found"));
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

    @PutMapping("/contacts/{id}/reply")
    public Contact reply(@PathVariable Long id, @RequestBody ContactReplyRequest request) {
        Contact contact = contactRepository.findById(id).orElseThrow(() -> new RuntimeException("Message not found"));
        contact.setAdminReply(request.adminReply);
        return contactRepository.save(contact);
    }
}
