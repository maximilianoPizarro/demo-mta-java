package com.example.demo;

import sun.misc.BASE64Encoder;

/**
 * Uses sun.misc.BASE64Encoder removed from the public JDK API after Java 8.
 * MTA OpenJDK rules flag this for migration to java.util.Base64.
 */
public final class LegacyEncoding {

    private LegacyEncoding() {
    }

    public static String encodeDemoPayload(String value) {
        BASE64Encoder encoder = new BASE64Encoder();
        return encoder.encode(value.getBytes());
    }
}
