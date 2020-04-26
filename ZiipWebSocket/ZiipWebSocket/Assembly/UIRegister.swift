//
//  UIRegister.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Swinject

class UIRegister {

    class func register(for container: Container) {

        container.storyboardInitCompleted(MainViewController.self) { resolver, controller in
            controller.connectionManager = resolver.resolve(ConnectionManager.self)
            controller.preferencesService = resolver.resolve(PreferencesService.self)
        }
        
    }

}
