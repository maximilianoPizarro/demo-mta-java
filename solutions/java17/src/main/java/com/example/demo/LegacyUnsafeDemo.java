package com.example.demo;

import java.lang.invoke.MethodHandles;
import java.lang.invoke.VarHandle;

/**
 * OpenJDK 11+ conversion: do not call the removed sun.misc.Unsafe offset/monitor methods.
 * VarHandle is the supported replacement when low-level access is still required.
 */
public final class LegacyUnsafeDemo {

    private static final VarHandle VALUE;

    static {
        try {
            VALUE = MethodHandles.lookup().findVarHandle(Box.class, "value", int.class);
        } catch (Exception e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    private LegacyUnsafeDemo() {
    }

    public static void touchRemovedOps() {
        Box box = new Box();
        VALUE.set(box, 1);
        VALUE.get(box);
    }

    static final class Box {
        int value;
    }
}
