package com.example.demo;

import java.applet.Applet;

/**
 * Applet API deprecated for removal in OpenJDK 17 (JEP 398).
 */
public final class AppletLegacyDemo {

    private AppletLegacyDemo() {
    }

    @SuppressWarnings({"deprecation", "removal"})
    public static String marker() {
        Applet applet = new Applet();
        return applet.getClass().getName();
    }
}
