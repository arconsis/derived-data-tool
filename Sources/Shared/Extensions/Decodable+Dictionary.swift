//
//  Decodable+Dictionary.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation
public enum DictionaryDecodableError: Error {
    case dataConversionFailed
    case objectConversionFailed
}

public extension Decodable {
    static func fromDict(_ dictionary: [String: String]) throws -> Self {
        guard let data = dictionary.description.data(using: .utf8) else {
            throw DictionaryDecodableError.dataConversionFailed
        }
        guard let object = try? SingleDecoder.shared.decode(Self.self, from: data) else {
            throw DictionaryDecodableError.objectConversionFailed
        }
        return object
    }
}
