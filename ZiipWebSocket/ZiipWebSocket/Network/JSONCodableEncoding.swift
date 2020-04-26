//
//  JSONCodableEncoding.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Alamofire

public struct CodableParameterEncoding: ParameterEncoding {

    private static var jsonDataKey = "_jsonData"
    
    public func encode(_ urlRequest: URLRequestConvertible,
                       with parameters: Parameters?) throws -> URLRequest {

        var urlRequest = try urlRequest.asURLRequest()

        guard var parameters = parameters else {
            return urlRequest
        }

        let body = parameters.removeValue(forKey: CodableParameterEncoding.jsonDataKey)
        if !parameters.isEmpty {
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        }

        if let body = body, let encodable = body as? Encodable {
            let encodingResult = encodable.safeEncode()
            switch encodingResult {
            case .failure(let error):
                throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))

            case .success(let data):
                if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    urlRequest.setValue("application/json",
                                        forHTTPHeaderField: "Content-Type")
                }
                urlRequest.httpBody = data
            }
        }

        return urlRequest
    }

    public func mergingParameters(in parameters: Parameters,
                                  from encodable: Encodable) -> Parameters {

        let bodyParameters = [CodableParameterEncoding.jsonDataKey: encodable as Any]
        return parameters.merging(bodyParameters) { _, new in new }
    }

}

