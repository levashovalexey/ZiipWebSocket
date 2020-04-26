//
//  HubConfiguration.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

public struct HubConfiguration: Decodable {
    public let keepAliveAddress: String
    public let presentingAddress: String
    public let voiceDialerAddress: String
    public let webPresentingAddress: String?
    public let hubName: String
    public let sipState: SipState
    public let turnAddress: String?
    public let hubIp: String
    public let hubPort: String
    public let version: String
    public let microphoneMuted: Bool
    public let speakerMuted: Bool
    public let volume: Float
    public let cameraState: CameraState
    public let presentingState: PresentingState


    private enum CodingKeys: String, CodingKey {
        case keepAliveAddress
        case presentingAddress
        case voiceDialerAddress
        case webPresentingAddress
        case hubName
        case sipState
        case turnAddress
        case hubIp
        case hubPort
        case version
        case microphoneMuted = "hubMicMuted"
        case speakerMuted = "hubSpeakerMuted"
        case volume = "hubVolumeState"
        case cameraState
        case presentingState
    }

}

public enum SipState: String, Codable {
    
    case inCall = "InCall"
    case hangUp = "HangUp"
    case outgoing = "Calling"
    case incoming = "Ringing"
    case registered = "Registered"
    case unregistered = "Unregistered"

}


public enum CameraState: String, Codable {

    case inActive = "Inactive"
    case active = "Active"

}

public enum PresentingState: String, Codable {

    case inActive = "Inactive"
    case activeWebRTC = "ActiveWebRTC"
    case activeByBrowserC = "ActiveByBrowser"
}



extension HubConfiguration {
    var hubAddress: String {
        return "http://\(hubIp):\(hubPort)/api/v1/"
    }
}

