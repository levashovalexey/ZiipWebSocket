//
//  FailableDecodable.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

// MARK: - Failable Decodable

public struct FailableDecodable<Model: Decodable> : Decodable {

    public let model: Model?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            model = try container.decode(Model.self)
        } catch {
            Logger.error(error)
            model = nil
        }
    }

}

// MARK: - Array of Failable Decodable

public struct FailableDecodableArray<Element: Decodable>: Decodable {

    public let elements: [Element]

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements = [Element]()
        while !container.isAtEnd {
            if let element = try container.decode(FailableDecodable<Element>.self).model {
                elements.append(element)
            }
        }
        self.elements = elements
    }

}

// MARK: - Result extension

extension Result {

    static func make<T>(from failableArrayResult: Result<FailableDecodableArray<T>>) -> Result<[T]> {
        switch failableArrayResult {
        case .success(let failableArray):
            return Result<[T]>.success(failableArray.elements)
        case .failure(let error):
            return Result<[T]>.failure(error)
        }
    }

}

