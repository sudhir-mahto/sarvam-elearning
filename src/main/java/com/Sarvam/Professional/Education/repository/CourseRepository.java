package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Course;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseRepository extends JpaRepository<Course, Long> {
}