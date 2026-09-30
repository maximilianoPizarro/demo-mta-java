package com.example.demo;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * Cloud-ready: write under /tmp (or MARKER_DIR) instead of a fixed absolute host path.
 */
public final class LocalFilesystem {

    private LocalFilesystem() {
    }

    public static void writeStartupMarker() {
        String base = System.getenv().getOrDefault("MARKER_DIR", "/tmp/mta-demo");
        try {
            File marker = new File(base, "startup.marker");
            File parent = marker.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            try (FileWriter writer = new FileWriter(marker)) {
                writer.write("started");
            }
        } catch (IOException ignored) {
            FileLogger.log("startup marker skipped: " + ignored.getMessage());
        }
    }
}
