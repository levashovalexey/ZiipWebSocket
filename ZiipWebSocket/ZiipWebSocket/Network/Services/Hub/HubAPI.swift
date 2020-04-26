//
//  HubAPI.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

// MARK: - Hub RestAPI

public class HubRestAPI: RestAPI {
}

// MARK: - Hub Configuration protocol

public protocol HubConfigurationAPI: class {
    func getConfiguration(for endpoint: String?, _ completion: @escaping ((Result<HubConfiguration>) -> Void))
    func stopSharing(hubId: String, completion: @escaping (Error?) -> Void)
}

public extension HubConfigurationAPI {
    func getConfiguration(_ completion: @escaping ((Result<HubConfiguration>) -> Void)) {
        getConfiguration(for: nil, completion)
    }

    func stopSharing(hubId: String, completion: @escaping (Error?) -> Void) {
        stopSharing(hubId: hubId, completion: completion)
    }
}

// MARK: HubConfigurationAPI protocol conformance

extension HubRestAPI: HubConfigurationAPI {

    public func getConfiguration(for endpoint: String?, _ completion: @escaping ((Result<HubConfiguration>) -> Void)) {
        guard let basePath = endpoint ?? endpointProvider?.endpointBasePath else {
            completion(.failure(NetworkAPIError.basePathUndefined))
            return
        }
        guard let baseUrl = URL(string: basePath) else {
            completion(.failure(NetworkAPIError.invalidBaseUrl(basePath)))
            return
        }
        performRequest(baseUrl.appendingPathComponent(Routes.HubAPI.HubConfiguration.configuration),
                       method: .get,
                       completion: completion)
    }

    public func stopSharing(hubId: String, completion: @escaping (Error?) -> Void) {
        performRequest(Routes.HubAPI.ScreenSharing.stopSharing,
                       method: .put,
                       completion: completion)
    }
}

