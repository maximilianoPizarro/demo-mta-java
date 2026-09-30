package com.example.demo;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Date;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * OpenJDK 17: replace deprecated Date(int,int,int) and Thread.stop().
 */
public final class DeprecatedApis {

    private DeprecatedApis() {
    }

    public static Date snapshotClock() {
        return Date.from(LocalDate.of(2020, 1, 1).atStartOfDay().toInstant(ZoneOffset.UTC));
    }

    public static void forceStopWorker(Thread worker) {
        if (worker == null || !worker.isAlive()) {
            return;
        }
        // Cooperative stop: interrupt instead of Thread.stop() (removed after Java 8 era).
        worker.interrupt();
    }

    /** Demo helper showing a flag-based shutdown instead of Thread.stop. */
    public static AtomicBoolean newStopFlag() {
        return new AtomicBoolean(false);
    }
}
