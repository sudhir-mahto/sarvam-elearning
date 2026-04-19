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
