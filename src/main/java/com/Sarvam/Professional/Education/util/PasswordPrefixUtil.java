package com.Sarvam.Professional.Education.util;

import java.util.regex.Pattern;

/**
 * Adds the encoder prefix Spring Security's DelegatingPasswordEncoder needs
 * (e.g. {noop}, {bcrypt}) when a stored password is missing one. Used by both
 * authentication (login) and the change-password flow so they stay in sync.
 */
public final class PasswordPrefixUtil {

    private static final Pattern PREFIX_PATTERN = Pattern.compile("^\\{.+}.*");

    private PasswordPrefixUtil() {
    }

    public static String normalize(String storedPassword) {
        if (storedPassword == null) {
            return null;
        }
        if (PREFIX_PATTERN.matcher(storedPassword).matches()) {
            return storedPassword;
        }
        if (isBcryptHash(storedPassword)) {
            return "{bcrypt}" + storedPassword;
        }
        return "{noop}" + storedPassword;
    }

    private static boolean isBcryptHash(String value) {
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }
}
