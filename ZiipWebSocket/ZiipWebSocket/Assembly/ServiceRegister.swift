//
//  ServiceRegister.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

//
//  ServiceRegister.swift
//  Workspaces
//
//  Created by Alexey Levashov on 11/29/19.
//  Copyright © 2019 Alexey Levashov. All rights reserved.
//

import Foundation
import Swinject

class ServiceRegister {

    class func register(for container: Container) {
        
        // MARK: - Logger

        container.register(Logger.self) { _ in
            return Logger()
        }.inObjectScope(.container)
        
        // MARK: - Connection Manager
        
        container.register(ConnectionManager.self) { container in
            let manager = HubConnectionManager()
            manager.connectivityService = container.resolve(HubConnectivityService.self)
            manager.participantService = container.resolve(ParticipantsService.self)
            manager.networkConfig = container.resolve(ConfigurationService.self)
            manager.keepAliveService = container.resolve(KeepAliveService.self)
            return manager
        }.inObjectScope(.container)
        
        // MARK: - Preferences
        
        container.register(PreferencesService.self) { _ in
            return UserPreferencesService()
        }.inObjectScope(.container)
        
        // MARK: - Hub Connectivity
        
        container.register(HubConnectivityService.self) { container in
            return HubConnectivityServiceWithTunneling()
        }.initCompleted() { container, service in
            guard let service = service as? HubConnectivityServiceWithTunneling else {
                return
            }
            service.cloudHubInfoApi = container.resolve(HubInfoAPI.self)
            service.hubConfigurationApi = container.resolve(HubConfigurationAPI.self)
            service.tokenProvider = container.resolve(TokenContainer.self)
            service.configurationService = container.resolve(ConfigurationService.self)
        }.inObjectScope(.container)

        // MARK: - PlistServices
        container.register(ConfigurationService.self) { _ in
            return ConfigurationService()
        }.inObjectScope(.container)


        // MARK: - RestAPI

        container.register(HubRestAPI.self) { resolver in
            let api = HubRestAPI()
            return api
        }.inObjectScope(.container)

        container.register(ParticipantAPI.self) { resolver in
            return resolver.resolve(HubRestAPI.self)!
        }.inObjectScope(.container)

        // MARK: - KeepAlive
        
        container.register(KeepAliveService.self) { container in
            let service = KeepAliveHubService()
            service.webSocket = container.resolve(WebSocketServiceProtocol.self)
            service.configurationService = container.resolve(ConfigurationService.self)
            return service
        }

        // MARK: - WebSocketService

        container.register(WebSocketServiceProtocol.self) { _ in
            return WebSocketService()
        }.inObjectScope(.container)
    }

}

