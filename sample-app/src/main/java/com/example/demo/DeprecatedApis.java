package com.example.demo;

import java.util.Date;

/**
 * Deprecated Date constructor and Thread.stop usage that OpenJDK migration rules surface.
 */
public final class DeprecatedApis {

    private DeprecatedApis() {
    }

    @SuppressWarnings("deprecation")
    public static Date snapshotClock() {
        // Deprecated since Java 1.1; still compiles on 8 and is a common MTA finding.
        return new Date(2020 - 1900, 0, 1);
    }

    @SuppressWarnings("deprecation")
    public static void forceStopWorker(Thread worker) {
        // Thread.stop removed in later JDKs; kept here as a deliberate OpenJDK finding.
        if (worker != null && worker.isAlive()) {
            worker.stop();
        }
    }
}
