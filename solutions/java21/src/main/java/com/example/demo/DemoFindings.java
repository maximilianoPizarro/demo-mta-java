package com.example.demo;

/**
 * Invokes the curated finding matrix so the call sites exist on the startup path.
 * Analysis input stays this Java 8 sample; solutions/ rewrite only the JDK issues.
 */
public final class DemoFindings {

    private DemoFindings() {
    }

    public static void exercise() {
        LegacyUnsafeDemo.touchRemovedOps();
        JavaxEeApisDemo.describePayload();
        SecurityManagerDemo.probe();
        AppletLegacyDemo.marker();
        ModernJdkDeprecations.touch();
        DeprecatedApis.forceStopWorker(new Thread());
        CloudLocalhostClients.probe();
        EmbeddedSocketProbe.bindAndClose();
        Bc4jCustomerEntity.describe();
        Bc4jOrderView.describe();
        new Bc4jApplicationModule().prepareSession();
        LegacyRemoteProbe.class.getName();
    }
}
