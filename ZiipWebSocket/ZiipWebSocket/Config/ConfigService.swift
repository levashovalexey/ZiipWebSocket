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
    var host: String { get }
    var port: String { get }
    var baseRestPath: String { get }
    var baseRestUrl: String { get }
    var webSocketPath: String { get }
    var webSocketUrl: String { get }
}

public class ConfigurationService: NetworkConfigurable {

    private struct Config: Decodable {

        let network: NetworkConfig


        struct NetworkConfig: Decodable {
            let host: String
            let port: String
            let baseRestPath: String
            let webSocketPath: String
        }

    }

    // MARK: - NetworkConfigurable constants


    public var host: String {
        return config.network.host
    }

    public var port: String {
        return config.network.port
    }

    public var baseRestPath: String {
        return config.network.baseRestPath
    }

    public var baseRestUrl: String {
        return "http://\(config.network.host):\(config.network.port)/\(config.network.baseRestPath)"
    }

    public var webSocketPath: String {
        return config.network.webSocketPath
    }

    public var webSocketUrl: String {
        return "ws://\(config.network.host):\(config.network.port)/\(config.network.webSocketPath)"
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

