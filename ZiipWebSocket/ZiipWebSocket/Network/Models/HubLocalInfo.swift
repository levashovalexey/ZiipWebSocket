//
//  HubLocalInfo.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

public struct HubLocalInfo: Codable {

    public let hubId: String
    public let hubIp: String
    
}

public struct HubNameInfo: Codable {

    public let id: String
    public let name: String

}
