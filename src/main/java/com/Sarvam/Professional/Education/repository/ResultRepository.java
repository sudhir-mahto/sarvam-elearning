package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Result;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ResultRepository extends JpaRepository<Result, Long> {
    List<Result> findByStudentId(Long studentId);
}
