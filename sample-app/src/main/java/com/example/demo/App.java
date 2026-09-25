package com.example.demo;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

/**
 * Demo entry point. Serves a simple HTTP page so the OpenShift Route responds.
 * Intentionally uses Java 8 patterns that MTA flags for OpenJDK upgrades and cloud readiness.
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
            String body = "<!DOCTYPE html><html><head><title>MTA Java Demo</title></head>"
                    + "<body><h1>MTA Java Demo</h1>"
                    + "<p>Synthetic Java 8 sample for OpenJDK and cloud-readiness effort analysis.</p>"
                    + "<p>WebLogic remains the application server target; this process only publishes the sample.</p>"
                    + "<p><a href=\"https://devspaces.apps.ocp.wjwzm.sandbox2915.opentlc.com/#https://github.com/maximilianoPizarro/demo-mta-java\">Open in Dev Spaces</a></p>"
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
