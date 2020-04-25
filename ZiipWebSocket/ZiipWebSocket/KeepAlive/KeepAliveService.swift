//
//  KeepAliveService.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Network
import Foundation

class KeepAliveService {
    
    let webSocket: WebSocketServiceProtocol?
    
    
    
    init() {
        webSocket = WebSocketService()
    }
    
    func startPooling() {
        webSocket
    }
    
    func stopPooling() {
        
    }
    
}
