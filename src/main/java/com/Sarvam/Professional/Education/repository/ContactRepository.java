package com.Sarvam.Professional.Education.repository;

import com.Sarvam.Professional.Education.model.Contact;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContactRepository extends JpaRepository<Contact, Long> {
}
