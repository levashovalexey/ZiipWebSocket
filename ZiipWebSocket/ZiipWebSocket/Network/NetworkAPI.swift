//
//  NetworkAPI.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Errors

public enum NetworkAPIError: Error {
    case basePathUndefined
    case invalidBaseUrl(String)
    case responseDataMissing
    case unexpectedDataReceived
    case invalidStatusCode(Int)
}

// MARK: - Endpoint Provider

public protocol EndpointProvider: class {
    var endpointBasePath: String? { get }
    var webSocketEndpointBasePath: String? { get }
    func shouldRetry(for endpoint: String, with error: Error) -> Bool
}

public class StaticEndpoint: EndpointProvider {
    
    var configurationService: NetworkConfigurable?
    
    public private(set) var endpointBasePath: String?
    public private(set) var webSocketEndpointBasePath: String?

    public init(with service: NetworkConfigurable) {
        configurationService = service
        endpointBasePath = service.basePath
    }

    public func shouldRetry(for endpoint: String, with error: Error) -> Bool {
        return false
    }
}

// MARK: - NetworkAPI Protocol

public protocol NetworkAPI {

    var tokenProvider: TokenProvider? { get set }
    var endpointProvider: EndpointProvider? { get set }

    func configure(additionalHeaders: HTTPHeaders?, policies: [String: ServerTrustPolicy]?)

    func performRequest<Response>(_ url: URL,
                                  method: HTTPMethod,
                                  query: Parameters?,
                                  body: Encodable?,
                                  headers: HTTPHeaders?,
                                  completion: @escaping ((Result<Response>) -> Void))

    // Request optional data - allow to return nil on empty response
    func performRequest<Response: Decodable>(_ url: URL,
                                             method: HTTPMethod,
                                             query: Parameters?,
                                             body: Encodable?,
                                             headers: HTTPHeaders?,
                                             completion: @escaping ((Result<Response?>) -> Void))

    func performRequest(_ url: URL,
                        method: HTTPMethod,
                        query: Parameters?,
                        body: Encodable?,
                        headers: HTTPHeaders?,
                        completion: @escaping ((Error?) -> Void))

}

extension NetworkAPI {

    func performRequest<Response>(_ path: String,
                                  method: HTTPMethod,
                                  query: Parameters? = nil,
                                  body: Encodable? = nil,
                                  headers: HTTPHeaders? = nil,
                                  completion: @escaping ((Result<Response>) -> Void)) {

        guard let basePath = endpointProvider?.endpointBasePath else {
            completion(.failure(NetworkAPIError.basePathUndefined))
            return
        }
        guard let baseUrl = URL(string: basePath) else {
            completion(.failure(NetworkAPIError.invalidBaseUrl(basePath)))
            return
        }
        let url = baseUrl.appendingPathComponent(path)

        let retriableCompletion: (Result<Response>) -> Void = { result in
            if case .failure(let error) = result,
                self.endpointProvider?.shouldRetry(for: basePath, with: error) == true {
                self.performRequest(path, method: method, query: query, body: body, headers: headers, completion: completion)
            } else {
                completion(result)
            }
        }

        performRequest(url, method: method, query: query, body: body, headers: headers, completion: retriableCompletion)
    }

    func performRequest<Response>(_ path: String,
                                  method: HTTPMethod,
                                  query: Parameters? = nil,
                                  body: Encodable? = nil,
                                  headers: HTTPHeaders? = nil,
                                  completion: @escaping ((Result<Response?>) -> Void)) where Response: Decodable {

        guard let basePath = endpointProvider?.endpointBasePath else {
            completion(.failure(NetworkAPIError.basePathUndefined))
            return
        }
        guard let baseUrl = URL(string: basePath) else {
            completion(.failure(NetworkAPIError.invalidBaseUrl(basePath)))
            return
        }
        let url = baseUrl.appendingPathComponent(path)

        let retriableCompletion: (Result<Response?>) -> Void = { result in
            if case .failure(let error) = result,
                self.endpointProvider?.shouldRetry(for: basePath, with: error) == true {
                self.performRequest(path, method: method, query: query, body: body, headers: headers, completion: completion)
            } else {
                completion(result)
            }
        }

        performRequest(url, method: method, query: query, body: body, headers: headers, completion: retriableCompletion)
    }

    func performRequest(_ path: String,
                        method: HTTPMethod,
                        query: Parameters? = nil,
                        body: Encodable? = nil,
                        headers: HTTPHeaders? = nil,
                        completion: @escaping ((Error?) -> Void)) {

        guard let basePath = endpointProvider?.endpointBasePath else {
            completion(NetworkAPIError.basePathUndefined)
            return
        }
        guard let baseUrl = URL(string: basePath) else {
            completion(NetworkAPIError.invalidBaseUrl(basePath))
            return
        }
        let url = baseUrl.appendingPathComponent(path)

        let retriableCompletion: (Error?) -> Void = { error in
            if let error = error,
                self.endpointProvider?.shouldRetry(for: basePath, with: error) == true {
                self.performRequest(path, method: method, query: query, body: body, headers: headers,
                                    completion: completion)
            } else {
                completion(error)
            }
        }

        performRequest(url, method: method, query: query, body: body, headers: headers, completion: retriableCompletion)
    }

}

// MARK: - Token Container

public protocol TokenProvider: class {
    var token: String? { get }
}

public protocol TokenBearer {
    var token: String? { get set }
    var expires: Date? { get set }
}

public class TokenContainer: TokenProvider, TokenBearer {
    public var token: String?
    public var expires: Date?
    public init() { }
}

