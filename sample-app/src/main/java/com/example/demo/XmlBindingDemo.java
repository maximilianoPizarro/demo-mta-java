package com.example.demo;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.annotation.XmlRootElement;

/**
 * Uses javax.xml.bind (JAXB), removed from the JDK classpath in Java 11+.
 * Requires an explicit dependency or EE container module when moving to OpenJDK 11/17/21.
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
