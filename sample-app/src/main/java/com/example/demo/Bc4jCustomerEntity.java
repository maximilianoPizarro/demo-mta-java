package com.example.demo;

/**
 * Java-side BC4J entity marker. Compiles without Oracle jars; custom rules match the FQCN.
 */
public final class Bc4jCustomerEntity {

    public static final String ENTITY_BASE = "oracle.jbo.server.EntityImpl";

    private Bc4jCustomerEntity() {
    }

    public static String describe() {
        return "CustomerEO extends " + ENTITY_BASE;
    }
}
