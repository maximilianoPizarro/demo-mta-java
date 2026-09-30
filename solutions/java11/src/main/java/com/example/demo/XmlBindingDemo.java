package com.example.demo;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.annotation.XmlRootElement;

/**
 * JAXB is no longer on the JDK classpath in Java 11+.
 * The pom ships jaxb-api + jaxb-runtime so this still compiles and runs.
 */
public final class XmlBindingDemo {

    private XmlBindingDemo() {
    }

    public static String describeCustomer() throws JAXBException {
        JAXBContext context = JAXBContext.newInstance(Customer.class);
        return "JAXB context ready: " + context.getClass().getName();
    }

    @XmlRootElement
    public static class Customer {
        public String name;
        public String accountId;
    }
}
