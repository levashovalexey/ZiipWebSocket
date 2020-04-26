//
//  File.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//


import Foundation

// MARK: - Participant protocol

public protocol ParticipantAPI {
    func getParticipant(_ completion: @escaping ((Result<[Participant]>) -> Void))
    func createParticipant(_ name: String, completion: @escaping ((Result<Participant>) -> Void))
    func deleteParticipant(with participantId: String, completion: @escaping ((Error?) -> Void))
}

// MARK: ParticipantAPI protocol conformance

extension HubRestAPI: ParticipantAPI {
    
    public func getParticipant(_ completion: @escaping ((Result<[Participant]>) -> Void)) {
        performRequest(Routes.HubAPI.Participant.participants,
                       method: .get,
                       completion: completion)
    }
    
    public func createParticipant(_ name: String,
                           completion: @escaping ((Result<Participant>) -> Void)) {

        let bodyParams = NewParticipant(userName: name)

        performRequest(Routes.HubAPI.Participant.participants,
                       method: .post,
                       body: bodyParams,
                       completion: completion)
    }
    
    public func deleteParticipant(with participantId: String, completion: @escaping ((Error?) -> Void)) {
        performRequest(Routes.HubAPI.Participant.deleteParticipant(with: participantId),
                       method: .delete,
                       completion: completion)
    }
    
}

