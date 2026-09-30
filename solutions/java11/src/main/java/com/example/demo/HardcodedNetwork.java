package com.example.demo;

import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Cloud-ready: health URL comes from APP_HEALTH_URL (defaults to this process /health).
 */
public final class HardcodedNetwork {

    private HardcodedNetwork() {
    }

    public static void pingLocalService() {
        String target = System.getenv().getOrDefault(
                "APP_HEALTH_URL",
                "http://127.0.0.1:" + System.getenv().getOrDefault("PORT", "8080") + "/health");
        try {
            URL url = new URL(target);
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
