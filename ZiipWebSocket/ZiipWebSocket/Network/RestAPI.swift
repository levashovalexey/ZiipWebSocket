//
//  RestAPI.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Alamofire

private struct EmptyDecodable: Decodable {}

// MARK: - Routes namespace

enum Routes {}

// MARK: - Rest API Implementation

public class RestAPI {

    lazy private var manager: SessionManager = createSessionManager()

    static private let defaultTimeout = TimeInterval(30)

    private var additionalHeaders: HTTPHeaders
    private var serverTrustPolicies: [String: ServerTrustPolicy]

    public var tokenProvider: TokenProvider?
    public var endpointProvider: EndpointProvider?

    public init(additionalHeaders: HTTPHeaders = [:],
         policies: [String: ServerTrustPolicy] = [:]) {

        self.additionalHeaders = additionalHeaders
        self.serverTrustPolicies = policies
    }

    // MARK: Private Methods

    private func createSessionManager() -> Alamofire.SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = additionalHeaders
        configuration.timeoutIntervalForRequest = RestAPI.defaultTimeout
        let policyManager = ServerTrustPolicyManager(policies: serverTrustPolicies)
        return Alamofire.SessionManager(configuration: configuration,
                                        serverTrustPolicyManager: policyManager)
    }

}

// MARK: -  NetworkAPI conformance

extension RestAPI: NetworkAPI {

    public func configure(additionalHeaders: HTTPHeaders? = nil,
                          policies: [String: ServerTrustPolicy]? = nil) {

        if let additionalHeaders = additionalHeaders {
            self.additionalHeaders = additionalHeaders
        }
        if let policies = policies {
            self.serverTrustPolicies = policies
        }
    }

    public func performRequest<Response>(_ url: URL,
                                         method: HTTPMethod = .get,
                                         query: Parameters? = nil,
                                         body: Encodable? = nil,
                                         headers: HTTPHeaders? = nil,
                                         completion: @escaping ((Result<Response>) -> Void)) {
        
        let encoding = CodableParameterEncoding()
        var parameters = query ?? [:]
        if let body = body {
            parameters = encoding.mergingParameters(in: parameters, from: body)
        }

        var headers = headers ?? [:]
        if let token = tokenProvider?.token {
            headers[Routes.CloudAPI.tokenHeaderKey] = "Bearer \(token)"
        }

        manager
            .request(url,
                     method: method,
                     parameters: parameters,
                     encoding: encoding,
                     headers: headers)
            .validate()
            .responseData { response in

                if let afError = response.error as? AFError,
                    case .responseValidationFailed(let reason) = afError,
                    case .unacceptableStatusCode(let statusCode) = reason {
                    completion(.failure(NetworkAPIError.invalidStatusCode(statusCode)))
                    return
                } else if let error = response.error {
                    completion(.failure(error))
                    return
                }

                guard let data = response.data, !data.isEmpty else {
                    completion(.failure(NetworkAPIError.responseDataMissing))
                    return
                }

                let decodingResult = Response.safeDecode(from: data)
                completion(decodingResult)
        }
    }


    public func performRequest<Response: Decodable>(_ url: URL,
                                                    method: HTTPMethod = .get,
                                                    query: Parameters? = nil,
                                                    body: Encodable? = nil,
                                                    headers: HTTPHeaders? = nil,
                                                    completion: @escaping ((Result<Response?>) -> Void)) {

        let completionForOptionalResponse: (Result<Response>) -> Void = { result in
            switch result {
            case .failure(let error):
                if case NetworkAPIError.responseDataMissing = error {
                    completion(.success(nil))
                } else {
                    completion(.failure(error))
                }
                
            case .success(let decoded):
                completion(.success(decoded))
            }
        }

        performRequest(url,
                       method: method,
                       query: query,
                       body: body,
                       headers: headers,
                       completion: completionForOptionalResponse)
    }

    public func performRequest(_ url: URL,
                               method: HTTPMethod,
                               query: Parameters? = nil,
                               body: Encodable? = nil,
                               headers: HTTPHeaders? = nil,
                               completion: @escaping ((Error?) -> Void)) {

        let completionWithoutResponse: (Result<EmptyDecodable>) -> Void = { result in
            var responseError: Error?
            if case .failure(let error) = result {
                if error is DecodingError {
                    // Decoding should not be started for request without response data
                    responseError = NetworkAPIError.unexpectedDataReceived
                } else if case NetworkAPIError.responseDataMissing = error {
                    // Missing data is OK, we don't expect it here actually
                    responseError = nil
                } else {
                    responseError = error
                }
            }
            completion(responseError)
        }

        performRequest(url,
                       method: method,
                       query: query,
                       body: body,
                       headers: headers,
                       completion: completionWithoutResponse)
    }

}
