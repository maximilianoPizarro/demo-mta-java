package com.example.demo;

import javax.security.auth.Subject;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.security.PrivilegedAction;

/**
 * OpenJDK 18–21 findings: implicit charset, finalization, Subject.doAs.
 */
public final class ModernJdkDeprecations {

    private ModernJdkDeprecations() {
    }

    @SuppressWarnings({"deprecation", "removal"})
    public static void touch() {
        try {
            String encoded = URLEncoder.encode("mta demo");
            URLDecoder.decode(encoded);
            File tmp = File.createTempFile("mta-charset", ".txt");
            try (FileReader reader = new FileReader(tmp)) {
                reader.read();
            }
            try (InputStreamReader ignored = new InputStreamReader(new ByteArrayInputStream(new byte[] {'a'}))) {
                // default charset constructor
            }
            try (PrintStream out = new PrintStream(new ByteArrayOutputStream())) {
                out.print("mta");
            }
            Subject.doAs(new Subject(), new PrivilegedAction<String>() {
                @Override
                public String run() {
                    return "doAs";
                }
            });
            new FinalizerHost().ping();
        } catch (Throwable ignored) {
            // Demo probe only.
        }
    }

    static final class FinalizerHost {
        void ping() {
        }

        @SuppressWarnings({"deprecation", "removal"})
        @Override
        protected void finalize() throws Throwable {
            super.finalize();
        }
    }
}
