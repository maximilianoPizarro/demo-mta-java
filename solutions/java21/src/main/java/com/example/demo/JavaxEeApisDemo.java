package com.example.demo;

import javax.activation.DataHandler;
import javax.annotation.PostConstruct;
import javax.annotation.Resource;

/**
 * JAF and Common Annotations left the JDK in Java 11. WebLogic still provides them;
 * OpenJDK 11+ needs explicit dependencies (see solutions/).
 */
public final class JavaxEeApisDemo {

    @Resource
    private String dataSourceJndi = "jdbc/demo";

    private JavaxEeApisDemo() {
    }

    public static String describePayload() {
        DataHandler handler = new DataHandler("mta-demo", "text/plain");
        JavaxEeApisDemo demo = new JavaxEeApisDemo();
        demo.afterInject();
        return handler.getContentType() + " via " + demo.dataSourceJndi;
    }

    @PostConstruct
    public void afterInject() {
        if (dataSourceJndi == null) {
            dataSourceJndi = "jdbc/demo";
        }
    }
}
