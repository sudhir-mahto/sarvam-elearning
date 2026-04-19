package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Lecture;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface LectureRepository extends JpaRepository<Lecture, Long> {
    List<Lecture> findByCourseId(Long courseId);
}
