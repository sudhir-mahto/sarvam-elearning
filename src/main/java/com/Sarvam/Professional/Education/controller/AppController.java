package com.Sarvam.Professional.Education.controller;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AppController {

    @GetMapping("/app")
    public Map<String, Object> home() {
        return Map.of(
            "app", "Sarvam Professional Education",
            "homeScreen", "Login | Sign Up | Change Password | Exit App",
            "status", "running"
        );
    }

    @GetMapping("/exit")
    public Map<String, String> exitApp() {
        return Map.of("message", "Close browser/app window to exit.");
    }
}
