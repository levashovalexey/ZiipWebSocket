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


        // MARK: - WebSocketService
        
        container.register(KeepAliveService.self) { container in
            let service = KeepAliveHubService()
            service.webSocket = container.resolve(WebSocketService.self)
            return service
        }

        container.register(WebSocketService.self) { _ in
            return WebSocketService()
        }.inObjectScope(.container)
    }

}

