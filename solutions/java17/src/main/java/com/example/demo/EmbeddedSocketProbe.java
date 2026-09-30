package com.example.demo;

import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * Direct sockets are a cloud-readiness finding (no Service/Route in front).
 */
public final class EmbeddedSocketProbe {

    private EmbeddedSocketProbe() {
    }

    public static void bindAndClose() {
        try (ServerSocket server = new ServerSocket()) {
            server.bind(new InetSocketAddress("127.0.0.1", 0));
            try (Socket client = new Socket()) {
                client.connect(new InetSocketAddress("127.0.0.1", server.getLocalPort()), 200);
            }
        } catch (Exception ignored) {
            FileLogger.log("socket probe skipped");
        }
    }
}
