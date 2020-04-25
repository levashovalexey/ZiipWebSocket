//
//  Codable+Safe.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

// MARK: - Decoding

public enum Result<Decoded: Decodable> {
    case success(Decoded)
    case failure(Error)
}

enum DateError: String, Error {
    case invalidDate
}

extension DateFormatter {
    static let restApiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        return formatter
    }()
}

extension Decodable {

    static func safeFragmentDecode(from data: Data) -> Result<Self> {
        guard let fragmentType = Self.self as? JSONFragmentCodable.Type else {
            let context = DecodingError.Context(codingPath: [],
                                                debugDescription: "Top level \(Self.self) is not JSONFragmentCodable.")
            return .failure(DecodingError.dataCorrupted(context))
        }
        if let object = fragmentType.fragmentDecoded(from: data) as? Self {
            return .success(object)
        } else {
            let context = DecodingError.Context(codingPath: [],
                                                debugDescription: "Top level \(Self.self) encoding failed.")
            return .failure(DecodingError.dataCorrupted(context))
        }
    }

    static func safeDecode(from data: Data) -> Result<Self> {
        // Allow fragment JSON decoding as top-level objects (non-dict/object)
        if Self.self is JSONFragmentCodable.Type {
            return safeFragmentDecode(from: data)
        }

        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = DateFormatter.restApiDateFormatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })
        
        do {
            let decoded = try decoder.decode(Self.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }

}

// MARK: - Encoding

protocol JSONFragmentCodable {
    func fragmentEncoded() -> EncodingResult
    static func fragmentDecoded(from data: Data) -> Self?
}

extension String: JSONFragmentCodable {
    func fragmentEncoded() -> EncodingResult {
        if let data = self.data(using: .utf8) {
            return .success(data)
        } else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Top level string encoding failed.")
            return .failure(EncodingError.invalidValue(self, context))
        }
    }

    static func fragmentDecoded(from data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        return jsonObject as? String
    }
}

extension Bool: JSONFragmentCodable {
    func fragmentEncoded() -> EncodingResult {
        return String(self).fragmentEncoded()
    }

    static func fragmentDecoded(from data: Data) -> Bool? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        return jsonObject as? Bool
    }
}

extension Float: JSONFragmentCodable {
    func fragmentEncoded() -> EncodingResult {
        return String(self).fragmentEncoded()
    }

    static func fragmentDecoded(from data: Data) -> Float? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        return (jsonObject as? NSNumber)?.floatValue
    }
}

extension Int: JSONFragmentCodable {
    func fragmentEncoded() -> EncodingResult {
        return String(self).fragmentEncoded()
    }

    static func fragmentDecoded(from data: Data) -> Int? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        return (jsonObject as? NSNumber)?.intValue
    }
}

public enum EncodingResult {
    case success(Data)
    case failure(Error)
}

extension Encodable {

    func safeEncode(prettyPrint: Bool = false) -> EncodingResult {
        if let encodable = self as? JSONFragmentCodable {
            return encodable.fragmentEncoded()
        }

        var formatting = JSONEncoder.OutputFormatting()
        if prettyPrint {
            formatting.insert(.prettyPrinted)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = formatting
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .custom({ (date, encoder) -> Void in
            var container = encoder.singleValueContainer()
            let dateStr = DateFormatter.restApiDateFormatter.string(from: date)
            try container.encode(dateStr)
        })

        do {
            let data = try encoder.encode(self)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

}

