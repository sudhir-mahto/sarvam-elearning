package com.Sarvam.Professional.Education.controller;

import com.Sarvam.Professional.Education.model.*;
import com.Sarvam.Professional.Education.repository.*;
import java.util.List;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/teacher")
public class TeacherController {

    private final CourseRepository courseRepository;
    private final LectureRepository lectureRepository;
    private final NoteRepository noteRepository;
    private final QuizRepository quizRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ResultRepository resultRepository;

    public TeacherController(
        CourseRepository courseRepository,
        LectureRepository lectureRepository,
        NoteRepository noteRepository,
        QuizRepository quizRepository,
        EnrollmentRepository enrollmentRepository,
        ResultRepository resultRepository
    ) {
        this.courseRepository = courseRepository;
        this.lectureRepository = lectureRepository;
        this.noteRepository = noteRepository;
        this.quizRepository = quizRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.resultRepository = resultRepository;
    }

    @GetMapping("/dashboard")
    public String dashboard() {
        return "Teacher Dashboard";
    }

    @PostMapping("/courses")
    public Course addCourse(@RequestBody Course course) {
        return courseRepository.save(course);
    }

    @GetMapping("/courses")
    public List<Course> allCourses() {
        return courseRepository.findAll();
    }

    @PostMapping("/lectures")
    public Lecture addLecture(@RequestBody Lecture lecture) {
        return lectureRepository.save(lecture);
    }

    @PostMapping("/notes")
    public Note addNote(@RequestBody Note note) {
        return noteRepository.save(note);
    }

    @PostMapping("/quiz")
    public Quiz addQuiz(@RequestBody Quiz quiz) {
        return quizRepository.save(quiz);
    }

    @GetMapping("/students")
    public List<Enrollment> enrolledStudents() {
        return enrollmentRepository.findAll();
    }

    @GetMapping("/performance")
    public List<Result> performance() {
        return resultRepository.findAll();
    }
}
