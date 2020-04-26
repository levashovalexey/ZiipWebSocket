//
//  HubInfoAPI.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

// MARK: - Cloud Rest API

public class CloudRestAPI: RestAPI {
    
}

// MARK: - HubInfoAPI protocol

public protocol HubInfoAPI {

    func getInfo(securityCode: String, completion: @escaping ((Result<HubLocalInfo>) -> Void))
    func getName(hubId: String, completion: @escaping ((Result<HubNameInfo>) -> Void))
    func getConfiguration(hubId: String, completion: @escaping ((Result<HubConfiguration>) -> Void))
  
    func requestUltrasonicSignal(hubId: String, completion: @escaping (Error?) -> Void)

}

// MARK: - HubConfiguration API Protocol conformance

extension CloudRestAPI: HubInfoAPI {

    public func getInfo(securityCode: String, completion: @escaping ((Result<HubLocalInfo>) -> Void)) {
        performRequest(Routes.CloudAPI.HubInfo.info,
                       method: .get,
                       query: [Routes.CloudAPI.hubSecurityCodeQueryKey: securityCode],
                       completion: completion)
    }

    public func getName(hubId: String, completion: @escaping ((Result<HubNameInfo>) -> Void)) {
        performRequest(Routes.CloudAPI.HubInfo.endpointForName(for: hubId),
                       method: .get,
                       completion: completion)
    }

    public func getConfiguration(hubId: String, completion: @escaping ((Result<HubConfiguration>) -> Void)) {
        performRequest(Routes.CloudAPI.HubInfo.endpointForConfiguration(for: hubId),
                       method: .get,
                       completion: completion)
    }

    public func requestUltrasonicSignal(hubId: String, completion: @escaping (Error?) -> Void) {
        performRequest(Routes.HubAPI.Ultrasonic.playUltasonic(with: hubId),
                       method: .put,
                       completion: completion)
    }

}

