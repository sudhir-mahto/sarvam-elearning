package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);
}