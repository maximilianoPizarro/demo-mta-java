package com.example.demo;

import java.util.Date;

/**
 * Still uses deprecated Date constructor and Thread.stop — those are addressed in the Java 17 solution.
 */
public final class DeprecatedApis {

    private DeprecatedApis() {
    }

    @SuppressWarnings("deprecation")
    public static Date snapshotClock() {
        return new Date(2020 - 1900, 0, 1);
    }

    @SuppressWarnings("deprecation")
    public static void forceStopWorker(Thread worker) {
        if (worker != null && worker.isAlive()) {
            worker.stop();
        }
    }
}
