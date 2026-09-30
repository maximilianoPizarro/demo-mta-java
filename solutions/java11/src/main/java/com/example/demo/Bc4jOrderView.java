package com.example.demo;

/**
 * Java-side BC4J view marker. Certification effort only; WebLogic stays.
 */
public final class Bc4jOrderView {

    public static final String VIEW_BASE = "oracle.jbo.server.ViewObjectImpl";

    private Bc4jOrderView() {
    }

    public static String describe() {
        return "OrderVO extends " + VIEW_BASE;
    }
}
