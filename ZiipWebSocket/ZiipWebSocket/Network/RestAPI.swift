//
//  RestAPI.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

// MARK: - Routes namespace

enum Routes {}

public protocol NetworkAPI {

    func perform(_ request: URLRequest, completion: @escaping (Data?, Error?) -> Void)

}

public class RestAPI {

    func perform(_ request: URLRequest, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                print(request.url?.description ?? "")
                print("\(response.statusCode)")
            }
            completion(data, error)
        }
        task.resume()
    }

}
