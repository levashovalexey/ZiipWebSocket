//
//  HubConnectivityService.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Errors

public enum HubConnectivityResult {
    case hubNotFound(Error)
    case discoveryHubFailed(Error)
    case discoveryCodeFailed(Error)
    case connectionFailed([ConnectionType: Error])

    static public let ErrorDomain = "HubConnectivityErrorDomain"

    public enum ErrorCode: Int {
        case hubNotFound = 404
        case hubIDError
        case codeError
    }
}

// MARK: - Hub Connectivity Service Protocol

public typealias HubConnectCompletion = (HubConnection) -> Void

public protocol HubConnectivityService: EndpointProvider {

    func connect(to hubId: String, asMain: Bool, completion: HubConnectCompletion?)
    func connect(with securityCode: String, completion: HubConnectCompletion?)
    func disconnect()

    var activeConnection: HubConnection? { get }
    var endpointBasePath: String? { get }
    var webSocketEndpointBasePath: String? { get }
    var presentingEndpointBasePath: String? { get }

}

extension HubConnectivityService {

    func connect(to hubId: String, asMain: Bool = true, completion: HubConnectCompletion? = nil) {
        connect(to: hubId, asMain: asMain, completion: completion)
    }

}

// MARK: - Hub Connectivity Service (with Cloud tunneling)

// TODO: Error Handling
public class HubConnectivityServiceWithTunneling: HubConnectivityService {

    // MARK: - Injected Dependencies

    public var configurationService: NetworkConfigurable!
    public var cloudHubInfoApi: HubInfoAPI!
    public var preferencesService: PreferencesService?
    public var hubConfigurationApi: HubConfigurationAPI!
    public var tokenProvider: TokenProvider?
    public var reachabilityManager: NetworkReachabilityManager!

    // MARK: - Public API

    public private(set) var activeConnection: HubConnection?
    public var endpointBasePath: String? {
        return activeConnection?.endpointAddress
    }
    public var webSocketEndpointBasePath: String? {
        if let address = activeConnection?.webSoketAddress, let token = tokenProvider?.token {
            return address + "?token=" + token
        } else {
            return nil
        }
    }
    public var presentingEndpointBasePath: String? {
        guard let address = activeConnection?.presentingAddress, let token = tokenProvider?.token else {
            return nil
        }
        return address + "?token=" + token
    }

    public init() {}

    /// Makes connection main (providing endpoint path for Hub Rest API)
    public func setAsMain(_ connection: HubConnection) {
        activeConnection = connection
        let notification = Notification(name: Notification.Name.HubConnectivityServiceScenarios.activeConnectionResolved, object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
    }

    /// Connects to hub using hubId (beacon way) locally or through cloud (if local connection failed)
    public func connect(to hubId: String, asMain: Bool, completion: HubConnectCompletion?) {
        var connection: HubConnection
        if let activeConnection = activeConnection, activeConnection.hubId == hubId {
            connection = activeConnection
        } else {
            connection = HubConnection()
            connection.configurationService = configurationService
        }
        connection.startConnecting(to: hubId)
        cloudHubInfoApi.getConfiguration(hubId: hubId) { configResult in
            switch configResult {
            case .failure(let error):
                connection.discoveryHubFailed(with: error)
                completion?(connection)

            case .success(let hubConfig):
                // We already received success on the cloud "connect" api, so it definitely available
                connection.addAvailableConnection(.cloud, with: hubConfig)
                if asMain {
                    self.setAsMain(connection)
                }
                // Try to connect locally as better option
                if self.reachabilityManager.isReachableOnEthernetOrWiFi {
                    self.connectToHubLocally(localAddress: hubConfig.hubAddress, for: connection)
                }
                completion?(connection)
            }
        }
    }

    /// Connects to hub using security code (ui manual way) locally or through cloud (if local connection failed)
    public func connect(with securityCode: String, completion: HubConnectCompletion?) {
        let newConnection = HubConnection()
        newConnection.configurationService = configurationService
        cloudHubInfoApi.getInfo(securityCode: securityCode) { infoResult in
            switch infoResult {
            case .failure(let error):
                newConnection.discoveryCodeFailed(with: error)
                completion?(newConnection)

            case .success(let hubInfo):
                var anyConnectSucceeded = false
                let connectionsGroup = DispatchGroup()
                let connectCompletion: HubConnectCompletion = { connection in
                    if case .connected = connection.state, !anyConnectSucceeded {
                        anyConnectSucceeded = true
                        self.setAsMain(connection)
                        completion?(connection)
                    }
                    connectionsGroup.leave()
                }
                newConnection.startConnecting(to: hubInfo.hubId)

                if self.reachabilityManager.isReachableOnEthernetOrWiFi {
                    connectionsGroup.enter()
                    self.connectToHubLocally(localAddress: hubInfo.hubIp, for: newConnection, completion: connectCompletion)
                }

                connectionsGroup.enter()
                self.connectToHubViaCloud(hubId: hubInfo.hubId, for: newConnection, completion: connectCompletion)

                connectionsGroup.notify(queue: DispatchQueue.global()) {
                    if !anyConnectSucceeded {
                        completion?(newConnection)
                    }
                }
            }
        }
    }

    public func disconnect() {
        activeConnection = nil
    }

    // MARK: - Private Methods

    private func connectToHubLocally(localAddress: String, for connection: HubConnection, completion: HubConnectCompletion? = nil) {
        hubConfigurationApi.getConfiguration(for: localAddress) { configResult in
            switch configResult {
            case .failure(let error):
                connection.connectFailed(.local, with: error)

            case .success(let hubConfig):
                connection.addAvailableConnection(.local, with: hubConfig)
            }
            completion?(connection)
        }
    }

    private func connectToHubViaCloud(hubId: String, for connection: HubConnection, completion: HubConnectCompletion? = nil) {
        cloudHubInfoApi.getConfiguration(hubId: hubId) { configResult in
            switch configResult {
            case .failure(let error):
                connection.connectFailed(.cloud, with: error)

            case .success(let hubConfig):
                connection.addAvailableConnection(.cloud, with: hubConfig)
            }
            completion?(connection)
        }
    }

}

// MARK: - Hub Connectivity Service Notifications

extension Notification.Name {

    enum HubConnectivityServiceScenarios {

        static var activeConnectionResolved: Notification.Name {
            return Notification.Name("ConnectivityServiceResolvedActiveConnection")
        }

        static var potentialHubFailureDetected: Notification.Name {
            return Notification.Name("ConnectivityServicePotentialHubFailureDetected")
        }

    }

}

// MARK: - EndpointProvider conformance

extension HubConnectivityServiceWithTunneling: EndpointProvider {

    private static let retriableErrorCodes = [
        NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost
    ]

    public func shouldRetry(for endpoint: String, with error: Error) -> Bool {
        guard let activeConnection = activeConnection,
            let connectionType = activeConnection.isServing(endpoint: endpoint) else {
            return false
        }

        let errorCode = (error as NSError).code
        guard HubConnectivityServiceWithTunneling.retriableErrorCodes.contains(errorCode) else {
            return false
        }

        activeConnection.removeAvailableConnection(connectionType)
        return activeConnection.availableConnections.count > 0
    }

}

