//
//  ConnectionManager.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Alamofire

public protocol HubConnectionObservable {
    func addObserver(_ observer: ConnectionManagerDelegate)
    func removeObserver(_ observer: ConnectionManagerDelegate)
}

public protocol ConnectionManager: HubConnectionObservable {
    
    func connect(to hubId: String)
    func connect(with securityCode: String)
    func disconnect()
    func clearHubId()
    
    var delegate: ConnectionManagerDelegate? { get set }
    var config: HubConfiguration? { get }
    var hubId: String? { get }
    var hubName: String? { get }
    var state: ConnectionManagerState { get }

}

@objc
public protocol ConnectionManagerDelegate: class {
    func didUpdateState()
    func didConnectCompleted(error: Error?)
}

public enum ConnectionManagerError {
    public static let ErrorDomain = "ConnectionManagerErrorDomain"
    public enum ErrorCode: Int {
        case timeout = 408
        case unexpectedError = 666
    }
}

public enum ConnectionManagerState {
    case unknown
    case notConnected
    case discovery
    case connected
    case connecting(ConnectionStage)
    case error(NSError)

    public enum ConnectionStage {
        case rest
        case participant
        case webSocket
        case complete
    }

    public static func == (lhs: ConnectionManagerState, rhs: ConnectionManagerState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown): return true
        case (.notConnected, .notConnected): return true
        case (.discovery, .discovery): return true
        case (.connected, .connected): return true
        case (.connecting(let lstage), .connecting(let rstage)): return lstage == rstage
        case (.error(let lerror), .error(let rerror)): return lerror == rerror
        default: return false
        }
    }

    public static func != (lhs: ConnectionManagerState, rhs: ConnectionManagerState) -> Bool {
        return !(lhs == rhs)
    }
}

public class HubConnectionManager: ConnectionManager {

    // MARK: - Injected Dependencies
    
    public var connectivityService: HubConnectivityService?
    public var participantService: ParticipantsService?
    public var keepAliveService: KeepAliveService?
    public var networkConfig: NetworkConfigurable?
    
    // MARK: - Public properties
    
    public var config: HubConfiguration? {
        return connectivityService?.activeConnection?.getConfig()
    }

    // MARK: - Private properties

    private var webSocketTimeoutTimer: Timer? {
        willSet {
            webSocketTimeoutTimer?.invalidate()
        }
    }
    private var observers = NSHashTable<ConnectionManagerDelegate>.weakObjects()
    private var reconnectHubId: String?
    private var reconnectParticipant: Participant?

    // MARK: - Initialization
    
    public init() {
        subscribeToNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }

    // MARK: - Public properties

    public private(set) var state: ConnectionManagerState = .unknown {
        didSet {
            guard state != oldValue else { return }
            Logger.debug("HubConnectionManager state changed to: \(String(describing: state))")
            observers.allObjects.forEach { $0.didUpdateState() }
        }
    }

    public var hubId: String? {
        return connectivityService?.activeConnection?.hubId
    }

    public var hubName: String? {
        return connectivityService?.activeConnection?.hubName
    }

    public weak var delegate: ConnectionManagerDelegate?
    
    // MARK: - Public Methods
    
    public func connect(with securityCode: String) {
        guard let connectivityService = connectivityService else {
            fatalError("Hub connectivity service isn't provided")
        }
        state = .connecting(.rest)
        connectivityService.connect(with: securityCode, completion: httpConnectionCompleted)
    }

    public func connect(to hubId: String) {
        guard let connectivityService = connectivityService else {
            fatalError("Hub connectivity service isn't provided")
        }
        state = .connecting(.rest)
        connectivityService.connect(to: hubId, asMain: true, completion: httpConnectionCompleted)
    }

    public func disconnect() {
        reconnectParticipant = nil
        teardownConnection(error: nil)
    }

    public func clearHubId() {
        reconnectHubId = nil
    }
    
    // MARK: - Private methods

    private func teardownConnection(error: NSError?) {
        guard let connectivityService = connectivityService else {
            fatalError("Hub connectivity service isn't provided")
        }
        guard let participantService = participantService else {
            fatalError("participantService not provided")
        }
        guard let keepAliveService = keepAliveService else {
            fatalError("participantService not provided")
        }
        var wasConnecting = false
        var stage: ConnectionManagerState.ConnectionStage
        if case .connected = state {
            stage = .complete
        } else if case .connecting(let connectionStage) = state {
            stage = connectionStage
            wasConnecting = true
        } else {
            state = .notConnected
            return
        }
        if let error = error {
            state = .error(error)
        } else {
            state = .notConnected
        }
        switch stage {
        case .complete:
            keepAliveService.disconnect()
            fallthrough
        case .webSocket:
            participantService.unregisterParticipant()
            fallthrough
        case .participant:
            connectivityService.disconnect()
            fallthrough
        case .rest:
            break
        }
        if wasConnecting {
            observers.allObjects.forEach { $0.didConnectCompleted(error: error) }
        }
    }
    
    private func httpConnectionCompleted(hubConnection: HubConnection) {
        guard let participantService = participantService else {
            fatalError("HubConnectionManager: participantService not provided")
        }
        if case .connected = hubConnection.state, let hubId = hubConnection.hubId {
            state = .connecting(.participant)
            participantService.registerParticipant(reconnectParticipant) { result in
                self.participantRegistrationCompleted(result: result)
            }
        } else if case .error(let error) = hubConnection.state {
            teardownConnection(error: error as NSError)
        } else {
            let error = createConnectionManagerError(for: .unexpectedError)
            teardownConnection(error: error)
            Logger.warning("Unexpected hub connection state: \(hubConnection.state)")
        }
    }

    private func participantRegistrationCompleted(result: Result<Participant>) {
        guard let keepAliveService = keepAliveService else {
            fatalError("HubConnectionManager: keepAliveService not provided")
        }
        switch result {
        case .success(let participant):
            keepAliveService.setParticipantId(with: participant.id)
            keepAliveService.setupConnection()
            startConnectionTimeout()

        case .failure(let error):
            teardownConnection(error: error as NSError)
        }
    }
    
    private func startConnectionTimeout() {
        guard let timeout = networkConfig?.connectionTimeout else {
            fatalError("Network config isn't provided")
        }
        webSocketTimeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { timer in
            let error = self.createConnectionManagerError(for: .timeout)
            self.teardownConnection(error: error)
            self.webSocketTimeoutTimer = nil
        }
    }
    
    private func postConnectionUp() {
        guard let connectivityService = connectivityService else {
            fatalError("Hub connectivity service isn't provided")
        }
        if let hubName = connectivityService.activeConnection?.hubName {
            let userInfo = [Notification.Name.ConnectionManager.UserInfoKey.hubName: hubName]
            let notification = Notification(name: Notification.Name.ConnectionManager.didConnectToHub,
                                            userInfo: userInfo)

            NotificationCenter.default.post(notification)
        }
    }
    
    private func createConnectionManagerError(for errorCode: ConnectionManagerError.ErrorCode) -> NSError {
        return NSError(domain: ConnectionManagerError.ErrorDomain,
                       code: errorCode.rawValue,
                       userInfo: nil)
    }
    
    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keepAliveUpReceived(notification:)), name: Notification.Name.KeepAliveScenarios.keepAliveUp, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keepAliveDownReceived(notification:)), name: Notification.Name.KeepAliveScenarios.keepAliveDown, object: nil)
    }
    
    private func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notifications
    
    @objc private func keepAliveUpReceived(notification: Notification) {
        webSocketTimeoutTimer = nil
        state = .connected
        observers.allObjects.forEach { $0.didConnectCompleted(error: nil) }
        postConnectionUp()
    }
    
    @objc private func keepAliveDownReceived(notification: Notification) {
        if let error = notification.userInfo?[Notification.Name.KeepAliveScenarios.UserInfo.errorKey] as? NSError {
            teardownConnection(error: error)
        } else {
            disconnect()
        }
    }

}

// MARK: - HubConnectionObservable

extension HubConnectionManager: HubConnectionObservable {

    public func addObserver(_ observer: ConnectionManagerDelegate) {
        observers.add(observer)
    }

    public func removeObserver(_ observer: ConnectionManagerDelegate) {
        observers.remove(observer)
    }

}

// MARK: - Notifications

extension Notification.Name {

    public enum ConnectionManager {

        public static var didConnectToHub: Notification.Name {
            return Notification.Name("didConnectToHub")
        }

    }
}

extension Notification.Name.ConnectionManager {

    public enum UserInfoKey {
        public static let hubName = "hubName"
    }

}

