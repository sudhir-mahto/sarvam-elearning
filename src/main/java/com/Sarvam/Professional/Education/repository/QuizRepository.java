package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Quiz;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface QuizRepository extends JpaRepository<Quiz, Long> {
    List<Quiz> findByCourseId(Long courseId);
}
