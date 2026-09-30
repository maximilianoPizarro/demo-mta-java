package com.example.demo;

/**
 * OpenJDK 17 conversion: Security Manager APIs are deprecated for removal.
 * This solution does not call System.getSecurityManager, AccessController, or Thread.checkAccess.
 */
public final class SecurityManagerDemo {

    private SecurityManagerDemo() {
    }

    public static String probe() {
        return "security-manager-not-used";
    }
}
