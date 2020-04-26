//
//  WebSocketMessage.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

enum WebSoketMessage {
    case keepAlive(participantId: String)
    case error(data: String)
    
    enum MessageType: String, Codable {
        case keepAlive = "keepAlive"
        case error
    }
}

extension WebSoketMessage: Codable {
    private enum CodingKeys: String, CodingKey {
        case messageType
        case data
    }
    
    private enum MeetingKeys: String, CodingKey {
        case eventType
        case meetingId
    }

    private enum AudioKeys: String, CodingKey {
        case micMuted
        case speakerMuted
        case volume
    }
    
    private enum CallEventKeys: String, CodingKey {
        case callState
        case callId
        case callInitiator
        case callUri
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let messageType = try values.decode(MessageType.self, forKey: .messageType)
        switch messageType {
        case .keepAlive:
            let participantId = try values.decode(String.self, forKey: .data)
            self = .keepAlive(participantId: participantId)
        case .error:
            let data = try values.decode(String.self, forKey: .data)
            self = .error(data: data)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .keepAlive(let participantId):
            try container.encode(MessageType.keepAlive, forKey: .messageType)
            try container.encode(participantId, forKey: .data)
        case .error(let data):
            try container.encode(MessageType.error, forKey: .messageType)
            try container.encode(data, forKey: .data)
        }
    }
}




