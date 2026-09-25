package com.example.demo;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Logs to a local file instead of stdout — cloud-readiness finding for containers.
 */
public final class FileLogger {

    private static final String LOG_PATH = "/tmp/mta-demo-app.log";

    private FileLogger() {
    }

    public static void log(String message) {
        try (PrintWriter out = new PrintWriter(new FileWriter(LOG_PATH, true))) {
            String stamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
            out.println(stamp + " " + message);
        } catch (IOException ignored) {
            System.out.println(message);
        }
    }
}
