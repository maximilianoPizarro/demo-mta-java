package com.example.demo;

/**
 * Simulated ADF/BC4J application module reference.
 * Does not ship Oracle runtime jars. Custom MTA rules detect oracle.jbo usage
 * so the effort report can include BC4J certification cost for JDK and containers.
 */
public class Bc4jApplicationModule /* extends oracle.jbo.server.ApplicationModuleImpl */ {

    /**
     * Fully-qualified BC4J type kept as a string so the project compiles without Oracle jars,
     * while file-content and import-style rules can still match the framework footprint.
     */
    public static final String BC4J_BASE = "oracle.jbo.server.ApplicationModuleImpl";

    public static String describeModel() {
        return "BC4J model based on " + BC4J_BASE
                + " — validate WebLogic + JDK certification; do not migrate the application server in this demo.";
    }

    public void prepareSession() {
        // Placeholder for session setup that would call ApplicationModuleImpl APIs.
        FileLogger.log("prepareSession against " + BC4J_BASE);
    }
}
