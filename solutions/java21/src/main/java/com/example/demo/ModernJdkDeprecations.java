package com.example.demo;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * OpenJDK 21 conversion: explicit UTF-8, no finalizer, no Subject.doAs.
 */
public final class ModernJdkDeprecations {

    private ModernJdkDeprecations() {
    }

    public static void touch() {
        try {
            String encoded = java.net.URLEncoder.encode("mta demo", StandardCharsets.UTF_8);
            java.net.URLDecoder.decode(encoded, StandardCharsets.UTF_8);
            Path tmp = Files.createTempFile("mta-charset", ".txt");
            Files.write(tmp, "ok".getBytes(StandardCharsets.UTF_8));
            try (ByteArrayInputStream in = new ByteArrayInputStream("a".getBytes(StandardCharsets.UTF_8));
                 ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                out.write(in.read());
            }
            Files.deleteIfExists(tmp);
        } catch (Exception ignored) {
            FileLogger.log("charset probe skipped");
        }
    }
}
