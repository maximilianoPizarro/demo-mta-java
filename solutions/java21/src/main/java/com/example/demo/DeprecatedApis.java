package com.example.demo;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Date;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Same as Java 17 — Date/Thread.stop already fixed.
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
        worker.interrupt();
    }

    public static AtomicBoolean newStopFlag() {
        return new AtomicBoolean(false);
    }
}
