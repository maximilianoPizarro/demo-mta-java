package com.example.demo;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

/**
 * OpenJDK 11 conversion of the Java 8 sample. Serves a page that lists what changed.
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
            String body = "<!DOCTYPE html><html><head><title>MTA Java 11 Solution</title></head>"
                    + "<body><h1>OpenJDK 11 conversion</h1>"
                    + "<p>Operational fix of the Java 8 sample for OpenJDK 11. WebLogic stays the application server.</p>"
                    + "<h2>What changed from Java 8</h2>"
                    + "<ul>"
                    + "<li><code>sun.misc.BASE64Encoder</code> → <code>java.util.Base64</code></li>"
                    + "<li><code>sun.misc.Unsafe</code> offset/monitor calls → <code>VarHandle</code></li>"
                    + "<li><code>javax.xml.bind</code>, <code>javax.activation</code> and <code>javax.annotation</code> shipped as explicit Maven dependencies</li>"
                    + "<li>Cloud readiness: marker under <code>/tmp</code>, health URL from env, logs to stdout</li>"
                    + "<li>BC4J metadata kept for JDK / container certification (no app-server migration)</li>"
                    + "</ul>"
                    + "<h2>Still pending (see Java 17 / 21)</h2>"
                    + "<ul>"
                    + "<li>Deprecated <code>Date(int,int,int)</code> and <code>Thread.stop()</code></li>"
                    + "<li><code>new URL(String)</code> deprecation addressed in Java 21</li>"
                    + "</ul>"
                    + "<p>Also running: <a href=\"/\">Java 8 sample</a> · "
                    + "<a href=\"/\">this app</a> · Java 17 · Java 21 (sibling Routes on the cluster)</p>"
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
