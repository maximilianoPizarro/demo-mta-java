package com.example.demo;

import java.util.Base64;

/**
 * Replaces sun.misc.BASE64Encoder (removed from the public JDK API after Java 8)
 * with java.util.Base64, available since Java 8 and required on OpenJDK 11+.
 */
public final class LegacyEncoding {

    private LegacyEncoding() {
    }

    public static String encodeDemoPayload(String value) {
        return Base64.getEncoder().encodeToString(value.getBytes());
    }
}
