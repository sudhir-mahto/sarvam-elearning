package com.Sarvam.Professional.Education.dto;

import java.util.Map;

public class QuizSubmitRequest {
    public Long studentId;
    public Long courseId;
    public Map<Long, String> answers;
}
