//
//  ParticipantsService.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

public protocol ParticipantsService {
    var currentParticipant: Participant? { get }

    func registerParticipant(_ existing: Participant?, completion: @escaping (Result<Participant>) -> Void)
    func unregisterParticipant()
}

public class ParticipantsServiceImpl: ParticipantsService {

    // MARK: - Injected Dependencies

    public var participantsAPI: ParticipantAPI?
    public var preferencesService:PreferencesService?

    // MARK: - Initialization

    public init() {}
    
    // MARK: - ParticipantsService

    public private(set) var currentParticipant: Participant?

    public func registerParticipant(_ existing: Participant?, completion: @escaping (Result<Participant>) -> Void) {
        guard let api = participantsAPI else {
            fatalError("API implementation to register participants is not provided")
        }

        guard let preferencesService = preferencesService else {
            fatalError("preferencesService implementation is not provided")
        }

        guard let userName = preferencesService.userName  else {
            Logger.verbose("User is not logged in, Guest not implemented currently.")
            return
        }
        if let existing = existing {
            Logger.verbose("Participant \(existing) is already registered.")
            currentParticipant = existing
            completion(.success(existing))
            return
        }
        api.createParticipant(userName) { result in
            if case .success(let participant) = result {
                self.currentParticipant = participant
            }
            completion(result)
        }
    }

    public func unregisterParticipant() {
        guard let api = participantsAPI else {
            fatalError("API implementation to unregister participants is not provided")
        }
        guard let participant = currentParticipant else {
            Logger.verbose("There is no participant to unregister.")
            return
        }
        api.deleteParticipant(with: participant.id) { _ in }
        currentParticipant = nil
    }

}

