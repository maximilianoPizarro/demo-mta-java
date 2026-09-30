package com.example.demo;

import java.rmi.Remote;

/**
 * RMI is a cloud-readiness finding. No registry is started; the type reference is enough.
 */
public interface LegacyRemoteProbe extends Remote {

    String ping() throws java.rmi.RemoteException;
}
