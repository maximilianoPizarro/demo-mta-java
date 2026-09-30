package com.example.demo;

import java.security.AccessController;
import java.security.PrivilegedAction;

/**
 * Security Manager APIs deprecated for removal in OpenJDK 17.
 */
public final class SecurityManagerDemo {

    private SecurityManagerDemo() {
    }

    @SuppressWarnings({"deprecation", "removal"})
    public static String probe() {
        try {
            SecurityManager current = System.getSecurityManager();
            final SecurityManager manager = current == null ? new SecurityManager() : current;
            Thread.currentThread().checkAccess();
            return AccessController.doPrivileged(new PrivilegedAction<String>() {
                @Override
                public String run() {
                    return manager.toString();
                }
            });
        } catch (Throwable ignored) {
            return "security-manager-unavailable";
        }
    }
}
