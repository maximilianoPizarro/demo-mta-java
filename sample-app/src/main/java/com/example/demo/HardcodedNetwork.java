package com.example.demo;

import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Hard-coded localhost URL — cloud-readiness finding for containerized deployments.
 */
public final class HardcodedNetwork {

    private static final String LOCAL_SERVICE = "http://localhost:7001/health";

    private HardcodedNetwork() {
    }

    public static void pingLocalService() {
        try {
            URL url = new URL(LOCAL_SERVICE);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(200);
            connection.setReadTimeout(200);
            connection.setRequestMethod("GET");
            connection.getResponseCode();
            connection.disconnect();
        } catch (Exception ignored) {
            // Demo only: WebLogic admin port is not present in the sample container.
        }
    }
}
