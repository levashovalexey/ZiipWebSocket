//
//  ConfigService.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

public enum PlistName: String {
    case debug     = "Config-Debug"
    case release   = "Config-Release"
}

public protocol NetworkConfigurable {
    var basePath: String { get }
    var pollingInterval: TimeInterval { get }
    var connectionTimeout: TimeInterval { get }
}

public class ConfigurationService: NetworkConfigurable {

    private struct Config: Decodable {

        let network: NetworkConfig

        struct NetworkConfig: Decodable {
            let basePath: String
            let pollingInterval: Double
            let connectionTimeout: Double
        }

    }

    // MARK: - NetworkConfigurable constants
    
    public var basePath: String {
        return config.network.basePath
    }
    
    public var pollingInterval: TimeInterval {
        return config.network.pollingInterval
    }
    
    public var connectionTimeout: TimeInterval {
        return config.network.connectionTimeout
    }

    // MARK: - Service variables

    private var config: Config

    public init() {
        #if DEBUG
        guard let path = Bundle.main.path(forResource: PlistName.debug.rawValue, ofType: "plist") else {
            fatalError("Plist not found!")
        }
        #else
        guard let path = Bundle.main.path(forResource: PlistName.release.rawValue, ofType: "plist") else {
            fatalError("Plist not found!")
        }
        #endif

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = PropertyListDecoder()
            config = try decoder.decode(Config.self, from: data)
        }
        catch {
            fatalError("Cannot decode Config. error - \(error)")
        }
    }
}

