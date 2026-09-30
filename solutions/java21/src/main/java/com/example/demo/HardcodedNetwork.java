package com.example.demo;

import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;

/**
 * Cloud-ready health URL from env, and URI instead of deprecated new URL(String) (Java 20+).
 */
public final class HardcodedNetwork {

    private HardcodedNetwork() {
    }

    public static void pingLocalService() {
        String target = System.getenv().getOrDefault(
                "APP_HEALTH_URL",
                "http://127.0.0.1:" + System.getenv().getOrDefault("PORT", "8080") + "/health");
        try {
            URL url = URI.create(target).toURL();
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(200);
            connection.setReadTimeout(200);
            connection.setRequestMethod("GET");
            connection.getResponseCode();
            connection.disconnect();
        } catch (Exception ignored) {
            FileLogger.log("health ping skipped: " + ignored.getMessage());
        }
    }
}
