package com.example.demo;

/**
 * Cloud-ready: log to stdout so OpenShift captures the stream.
 */
public final class FileLogger {

    private FileLogger() {
    }

    public static void log(String message) {
        System.out.println(message);
    }
}
