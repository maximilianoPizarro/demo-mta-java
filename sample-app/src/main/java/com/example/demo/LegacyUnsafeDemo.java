package com.example.demo;

import sun.misc.Unsafe;

/**
 * sun.misc.Unsafe offset/monitor calls removed from the supported API in OpenJDK 11+.
 */
public final class LegacyUnsafeDemo {

    private LegacyUnsafeDemo() {
    }

    @SuppressWarnings({"deprecation", "removal"})
    public static void touchRemovedOps() {
        try {
            Unsafe unsafe = Unsafe.getUnsafe();
            Object box = new Object();
            unsafe.getInt(box, 0L);
            unsafe.putInt(box, 0L, 1);
            unsafe.getObject(box, 0L);
            unsafe.putObject(box, 0L, box);
            unsafe.getLong(box, 0L);
        } catch (Throwable ignored) {
            // getUnsafe() is denied outside the bootstrap loader; MTA still sees the calls.
        }
    }
}
