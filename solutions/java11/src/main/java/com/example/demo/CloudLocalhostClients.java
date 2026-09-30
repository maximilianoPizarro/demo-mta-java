package com.example.demo;

import java.io.File;
import java.io.RandomAccessFile;
import java.nio.file.Paths;
import java.util.logging.FileHandler;

/**
 * Cloud-readiness findings left on purpose: localhost, local files, child processes, file logs.
 * The JDK solutions do not "fix" these; they stay as container-readiness debt.
 */
public final class CloudLocalhostClients {

    private CloudLocalhostClients() {
    }

    public static void probe() {
        String console = "http://127.0.0.1:7001/console";
        String database = "jdbc:postgresql://localhost:5432/mta";
        String localFile = "file:///var/local/mta-demo/data";
        try {
            File homeCache = new File(System.getProperty("user.home"), "mta-demo-cache.dat");
            try (RandomAccessFile raf = new RandomAccessFile(homeCache, "rw")) {
                raf.writeBytes("x");
            }
            Paths.get(System.getProperty("user.home"), "mta-demo", "cache.dat");
            new ProcessBuilder("hostname");
            new FileHandler("/tmp/mta-demo-juli.log");
        } catch (Exception ignored) {
            // Expected when the path or process is unavailable.
        }
        FileLogger.log(console + " " + database + " " + localFile);
    }
}
