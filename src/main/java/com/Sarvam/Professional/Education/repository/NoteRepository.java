package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Note;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoteRepository extends JpaRepository<Note, Long> {
    List<Note> findByCourseId(Long courseId);
}
