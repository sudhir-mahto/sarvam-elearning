package com.Sarvam.Professional.Education.config;

import com.Sarvam.Professional.Education.repository.UserRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

import java.util.regex.Pattern;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final UserRepository userRepository;

    public SecurityConfig(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        PasswordEncoder delegating = PasswordEncoderFactories.createDelegatingPasswordEncoder();
        if (delegating instanceof org.springframework.security.crypto.password.DelegatingPasswordEncoder dpe) {
            dpe.setDefaultPasswordEncoderForMatches(NoOpPasswordEncoder.getInstance());
        }
        return delegating;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/", "/login", "/signup", "/change-password", "/css/**", "/images/**")
                        .permitAll()
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/student/**").hasRole("STUDENT")
                        .requestMatchers("/teacher/**").hasRole("TEACHER")
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )
                .formLogin(form -> form
                        .loginPage("/login")
                        .loginProcessingUrl("/login")
                        .usernameParameter("email")
                        .passwordParameter("password")
                        .defaultSuccessUrl("/dashboard", true)
                        .failureUrl("/login?error")
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutSuccessUrl("/")
                        .permitAll()
                );

        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> userRepository.findByEmail(username)
                .map(user -> {
                    String storedPassword = user.getPassword();
                    boolean hasPrefix = Pattern.compile("^\\{.+}.*").matcher(storedPassword).matches();
                    if (!hasPrefix && !storedPassword.startsWith("$2a$") && !storedPassword.startsWith("$2b$")
                            && !storedPassword.startsWith("$2y$")) {
                        storedPassword = "{noop}" + storedPassword;
                    } else if (!hasPrefix) {
                        storedPassword = "{bcrypt}" + storedPassword;
                    }
                    UserDetails details = User.withUsername(user.getEmail())
                            .password(storedPassword)
                            .roles(user.getRole().name())
                            .build();
                    return details;
                })
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }
}