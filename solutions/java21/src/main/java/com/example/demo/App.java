package com.example.demo;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

/**
 * OpenJDK 21 conversion: cumulative 11+17 fixes plus URI.create().toURL().
 */
public class App {

    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));

        LegacyEncoding.encodeDemoPayload("mta-demo");
        XmlBindingDemo.describeCustomer();
        DeprecatedApis.snapshotClock();
        LocalFilesystem.writeStartupMarker();
        HardcodedNetwork.pingLocalService();
        FileLogger.log("App starting on port " + port);
        Bc4jApplicationModule.describeModel();
        DemoFindings.exercise();

        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", new RootHandler());
        server.createContext("/health", new HealthHandler());
        server.setExecutor(null);
        server.start();
        FileLogger.log("Listening on port " + port);
    }

    static class RootHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String body = "<!DOCTYPE html><html><head><title>MTA Java 21 Solution</title></head>"
                    + "<body><h1>OpenJDK 21 conversion</h1>"
                    + "<p>Cumulative fix on top of the Java 17 solution. WebLogic stays the application server.</p>"
                    + "<h2>Includes Java 11 and 17 changes</h2>"
                    + "<ul>"
                    + "<li><code>java.util.Base64</code> and explicit JAXB dependencies</li>"
                    + "<li><code>java.time</code> instead of deprecated Date constructor</li>"
                    + "<li><code>Thread.interrupt()</code> instead of <code>Thread.stop()</code></li>"
                    + "<li>Cloud readiness: <code>/tmp</code> marker, env health URL, stdout logs</li>"
                    + "</ul>"
                    + "<h2>New in Java 21</h2>"
                    + "<ul>"
                    + "<li><code>new URL(String)</code> → <code>URI.create(…).toURL()</code></li>"
                    + "<li>Charset constructors and <code>URLEncoder</code>/<code>URLDecoder</code> take <code>UTF-8</code> explicitly; no <code>finalize()</code> or <code>Subject.doAs</code></li>"
                    + "<li><code>compiler.release</code> 21</li>"
                    + "</ul>"
                    + "<p>Sibling Routes: Java 8 sample · Java 11 · Java 17 · this app</p>"
                    + "</body></html>";
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        }
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            byte[] bytes = "ok".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        }
    }
}
