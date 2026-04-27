package com.Sarvam.Professional.Education.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class PasswordPrefixUtilTest {

    @Test
    void plainTextPasswordGetsNoopPrefix() {
        assertEquals("{noop}password123", PasswordPrefixUtil.normalize("password123"));
    }

    @Test
    void bcryptHashGetsBcryptPrefix() {
        String hash = "$2a$10$abcdefghijklmnopqrstuvabcdefghijklmnopqrstuvwxyz0123456";
        assertEquals("{bcrypt}" + hash, PasswordPrefixUtil.normalize(hash));
    }

    @Test
    void alreadyPrefixedPasswordIsLeftAlone() {
        assertEquals("{noop}secret", PasswordPrefixUtil.normalize("{noop}secret"));
        assertEquals("{bcrypt}$2a$10$xyz", PasswordPrefixUtil.normalize("{bcrypt}$2a$10$xyz"));
    }

    @Test
    void nullInputReturnsNull() {
        assertNull(PasswordPrefixUtil.normalize(null));
    }
}
