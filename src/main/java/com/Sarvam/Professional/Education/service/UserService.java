package com.Sarvam.Professional.Education.service;

import com.Sarvam.Professional.Education.model.User;
import com.Sarvam.Professional.Education.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.Optional;
import java.util.regex.Pattern;

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
        String stored = normalizeStoredPasswordForMatching(user.getPassword());
        if (!passwordEncoder.matches(currentPassword, stored)) {
            throw new IllegalArgumentException("Current password is incorrect.");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    /** Same rules as {@code SecurityConfig} user loading so verify matches login behavior. */
    private static String normalizeStoredPasswordForMatching(String storedPassword) {
        String stored = storedPassword;
        boolean hasPrefix = Pattern.compile("^\\{.+}.*").matcher(stored).matches();
        if (!hasPrefix && !stored.startsWith("$2a$") && !stored.startsWith("$2b$")
                && !stored.startsWith("$2y$")) {
            stored = "{noop}" + stored;
        } else if (!hasPrefix) {
            stored = "{bcrypt}" + stored;
        }
        return stored;
    }
}