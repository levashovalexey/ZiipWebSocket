//
//  KeepAliveService.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Alamofire

public protocol KeepAliveService {
    
    func setupConnection()
    func stopPolling()
    func disconnect(error: Error?)
    func setParticipantId(with participantId: String)
    
}

extension KeepAliveService {
    public func disconnect() {
        disconnect(error: nil)
    }
}

public enum KeepAliveServiceError {
    case responseTimeout
    case errorMessageReceived(String)

    static public let ErrorDomain = "KeepAliveServiceErrorDomain"

    public enum ErrorCode: Int {
        case responseTimeout
        case errorMessageReceived
    }
}

public class KeepAliveHubService: KeepAliveService {

    // MARK: - Dependencies
    
    public var webSocket: WebSocketServiceProtocol?
    
    // MARK: - Private properties

    private var lastError: Error?
    private var responseTimeoutTimer: Timer? {
        willSet {
            responseTimeoutTimer?.invalidate()
        }
    }
    private var timer: Timer?
    private var isConnectionSetup: Bool = false {
        didSet {
            startPolling()
        }
    }
    private var participantId: String? {
        didSet {
            startPolling()
        }
    }
    
    // MARK: - KeepAliveService

    public init() {}
    
    public func setupConnection() {
        guard let webSocket = webSocket else {
            fatalError("Web Socket Service is not given for KeepAlive.")
        }
        webSocket.delegate = self
        webSocket.connect()

    }
    
    public func disconnect(error: Error?) {
        lastError = error
        responseTimeoutTimer = nil
        stopPolling()
        webSocket?.disconnect()
    }
    
    public func stopPolling() {
        participantId = nil
        timer?.invalidate()
        timer = nil
    }
    
    public func setParticipantId(with participantId: String) {
        self.participantId = participantId
    }
    
    // MARK: - Private functons
    
    private func startPolling() {
        guard let participantId = participantId, isConnectionSetup else {
            return
        }
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: {_ in
            self.sendKeepAlive(with: participantId)
        })
        sendKeepAlive(with: participantId)
        NotificationCenter.default.post(name: Notification.Name.KeepAliveScenarios.keepAliveUp, object: nil)
    }

    private func sendKeepAlive(with participantId: String) {
        guard let webSocket = webSocket else {
            timer?.invalidate()
            timer = nil
            return
        }
        let keepAlive = WebSoketMessage.keepAlive(participantId: participantId)
        if let data = try? JSONEncoder().encode(keepAlive) {
            webSocket.sendMessage(data: data, as: .text)
        }
    }

    private func createKeepAliveError(for errorCode: KeepAliveServiceError.ErrorCode) -> NSError {
        return NSError(domain: KeepAliveServiceError.ErrorDomain,
                       code: errorCode.rawValue,
                       userInfo: nil)
    }
}

extension KeepAliveHubService: WebSocketServiceDelegate {

    public func webSocketDidDisconnect(socket: WebSocketService) {
        self.analyticService?.send(AnalyticEvent(type: AnalyticEventType.disconnect))
        Logger.debug("WebSocket did disconnect")
        isConnectionSetup = false
        var userInfo: [String: Any]?
        if let lastError = lastError {
            userInfo = [Notification.Name.KeepAliveScenarios.UserInfo.errorKey: lastError]
        }
        NotificationCenter.default.post(name: Notification.Name.KeepAliveScenarios.keepAliveDown,
                                        object: nil,
                                        userInfo: userInfo)
        webSocket?.delegate = nil
    }
    
    public func didReceiveData(socket: WebSocketService, data: Data) {
        if let message = try? JSONDecoder().decode(WebSoketMessage.self, from: data) {
            responseTimeoutTimer = nil
            switch message {
            
            case .error(let error):
                Logger.warning(error)
                let errorMessageReceived = createKeepAliveError(for: .errorMessageReceived)
                disconnect(error: errorMessageReceived)
                
            default:
                Logger.verbose("Unexpected message type is received: \(message)")
            }
        }
    }
    
    public func didErrorOccured(socket: WebSocketService, error: NSError) {
        Logger.error(error)
        isConnectionSetup = false
        disconnect(error: error)
    }
    
    public func httpUpgrade(socket: WebSocketService, request: String) {
        Logger.verbose("request = \(request)")
    }
    
    public func httpUpgrade(socket: WebSocketService, response: String) {
        Logger.verbose("response = \(response)")
        isConnectionSetup = true
    }
}

// MARK: - Notifications

extension Notification.Name {
    
    public enum KeepAliveScenarios {

        public enum UserInfo {
            public static let errorKey = "keepAliveService.error"
        }
        
        /// User is connected to HUB, in the Room
        public static var keepAliveUp: Notification.Name {
            return Notification.Name("keepAliveUp")
        }
        
        /// User has left the Room
        public static var keepAliveDown: Notification.Name {
            return Notification.Name("keepAliveDown")
        }
        
        /// A meeting will be starting
        public static var meetingStarting: Notification.Name {
            return Notification.Name("meetingStarting")
        }
        
        /// A meeting has been started
        public static var meetingStarted: Notification.Name {
            return Notification.Name("meetingStarted")
        }

        /// host Waiting
        public static var hostWaiting: Notification.Name {
            return Notification.Name("hostWaiting")
        }
        
        /// A meeting has been released
        public static var meetingReleased: Notification.Name {
            return Notification.Name("meetingReleased")
        }

        /// Audio settings has been changed
        public static var audioSettingsChanged: Notification.Name {
            return Notification.Name("audioSettingsChanged")
        }
        
        /// Stop presenting
        public static var stopPresenting: Notification.Name {
            return Notification.Name("stopPresenting")
        }
        
    }
    
}
