//
//  HubConnection.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

// MARK: - Hub Connection Notifications

extension Notification.Name {

    public enum HubConnectionScenarios {

        public static var connectionError: Notification.Name {
            return Notification.Name("hubConnectionError")
        }

        public static var connectionInProgress: Notification.Name {
            return Notification.Name("connectionInProgress")
        }

        public static var connectionEstablished: Notification.Name {
            return Notification.Name("hubConnectionEstablished")
        }

        public enum UserInfoKey {
            static let connectionError = "error"
        }

    }

}

// MARK: - Hub Connection State

public enum ConnectionType {
    case cloud
    case local

    static let all = [local, cloud]
}

public enum ConnectionState {
    case notConnected
    case connecting
    case error(Error)
    case connected(ConnectionType)
}

// MARK: - Hub Connection

public class HubConnection {

    // MARK: - Private Properties

    private let connectionSyncQueue = DispatchQueue(label: "HubConnection.syncQueue", qos: .userInitiated)
    private var connectErrors: [ConnectionType: Error] = [:]
    private var configurations: [ConnectionType: HubConfiguration] = [:]
    private var bestAvailableConnection: ConnectionType? {
        let preferredConnectionAvailable = availableConnections.contains(HubConnection.preferredConnection)
        return preferredConnectionAvailable ? HubConnection.preferredConnection : availableConnections.first
    }

    // MARK: - Dependencies
    
    var configurationService: NetworkConfigurable?

    // MARK: - Public Properties
    
    static var preferredConnection: ConnectionType = .local

    public private(set) var hubId: String?
    public private(set) var availableConnections: Set<ConnectionType> = []
    public private(set) var state: ConnectionState = .notConnected {
        didSet {
            switch state {
            case .connecting:
                NotificationCenter.default.post(name: Notification.Name.HubConnectionScenarios.connectionInProgress,
                                                object: self)

            case .error(let error):
                let errorUserInfoKey = Notification.Name.HubConnectionScenarios.UserInfoKey.connectionError
                NotificationCenter.default.post(name: Notification.Name.HubConnectionScenarios.connectionError,
                                                object: self,
                                                userInfo: [errorUserInfoKey: error])

            case .connected(let type):
                if case .connected(let oldType) = oldValue, oldType == type {
                    return
                }
                NotificationCenter.default.post(name: Notification.Name.HubConnectionScenarios.connectionEstablished,
                                                object: self)

            case .notConnected: break
            }
        }
    }

    var hubName: String? {
        guard case .connected(let connectionType) = state else {
            return nil
        }
        return configurations[connectionType]?.hubName
    }


    var endpointAddress: String? {
        guard case .connected(let connectionType) = state else {
            return nil
        }
        return endpointAddress(for: connectionType)
    }
    
    var webSoketAddress: String? {
        guard case .connected(let connectionType) = state else {
            return nil
        }
        return configurations[connectionType]?.keepAliveAddress
    }

    var presentingAddress: String? {
        guard case .connected(let connectionType) = state else {
            return nil
        }
        return configurations[connectionType]?.presentingAddress
    }

    // MARK: - Public methods

    func startConnecting(to hubId: String) {
        connectionSyncQueue.sync {
            self.hubId = hubId
            availableConnections = []
            connectErrors = [:]
            configurations = [:]
            state = .connecting
        }
    }

    func discoveryHubFailed(with error: Error) {
        connectionSyncQueue.sync {
            if (error as NSError).code == HubConnectivityResult.ErrorCode.hubNotFound.rawValue {
                state = .error(error)
            } else {
                let err = NSError(domain: HubConnectivityResult.ErrorDomain,
                                  code: HubConnectivityResult.ErrorCode.hubIDError.rawValue,
                                  userInfo: nil)
                state = .error(err)
            }
        }
    }

    func discoveryCodeFailed(with error: Error) {
        connectionSyncQueue.sync {
            if (error as NSError).code == HubConnectivityResult.ErrorCode.hubNotFound.rawValue {
                state = .error(error)
            } else {
                let err = NSError(domain: HubConnectivityResult.ErrorDomain,
                                  code: HubConnectivityResult.ErrorCode.codeError.rawValue,
                                  userInfo: nil)
                state = .error(err)
            }
        }
    }

    func connectFailed(_ type: ConnectionType, with error: Error) {
        connectionSyncQueue.sync {
            connectErrors[type] = error
            if connectErrors.count == ConnectionType.all.count {
                state = .error(error)
            }
        }
    }

    func addAvailableConnection(_ type: ConnectionType, with configuration: HubConfiguration) {
        connectionSyncQueue.sync {
            availableConnections.insert(type)
            configurations[type] = configuration
            state = .connected(bestAvailableConnection ?? type)
        }
    }

    func removeAvailableConnection(_ type: ConnectionType) {
        connectionSyncQueue.sync {
            availableConnections.remove(type)
            configurations.removeValue(forKey: type)
            if case .connected(let currentType) = state, currentType == type {
                if let bestAvailableType = bestAvailableConnection {
                    state = .connected(bestAvailableType)
                } else {
                    state = .notConnected
                }
            }
        }
    }

    func isServing(endpoint: String) -> ConnectionType? {
        return availableConnections.filter { endpointAddress(for: $0) == endpoint }.first
    }
    
    public func getConfig() -> HubConfiguration? {
        guard case .connected(let connectionType) = state else {
            return nil
        }
        return configurations[connectionType]
    }

    // MARK: - Private Methods

    private func endpointAddress(for connectionType: ConnectionType) -> String? {
        switch connectionType {
        case .local:
            return configurations[.local]?.hubAddress

        case .cloud:
            guard let hubId = hubId else {
                return nil
            }
            return tunnelApiBasePath(for: hubId)
        }
    }
    
    private func tunnelApiBasePath(for hubId: String) -> String {
        guard let basePath = configurationService?.basePath else {
            fatalError("Base path not provide!")
        }
        return basePath + "hubs/\(hubId)/"
    }

}

