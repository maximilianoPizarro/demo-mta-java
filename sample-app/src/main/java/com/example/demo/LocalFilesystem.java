package com.example.demo;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * Writes to a fixed absolute path — a classic cloud-readiness finding for containers.
 */
public final class LocalFilesystem {

    private static final String MARKER_PATH = "/var/local/mta-demo/startup.marker";

    private LocalFilesystem() {
    }

    public static void writeStartupMarker() {
        try {
            File marker = new File(MARKER_PATH);
            File parent = marker.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            try (FileWriter writer = new FileWriter(marker)) {
                writer.write("started");
            }
        } catch (IOException ignored) {
            // Demo only: failure is expected in containers without that path.
        }
    }
}
