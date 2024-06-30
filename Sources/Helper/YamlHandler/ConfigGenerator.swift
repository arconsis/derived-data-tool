//
//  ConfigGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 28.04.23.
//

import Foundation
import Shared
import Yams

public enum ConfigGenerator {
    public static func encode<T: Swift.Encodable>(_ value: T) throws -> Data {
        let encoded = try YAMLEncoder().encode(value)
        guard let data = encoded.data(using: .utf8) else {
            throw ConfigError.noDataAvailable
        }
        return data
    }

    public static func decode<T: Swift.Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try YAMLDecoder().decode(type.self, from: data)
    }
}

extension ConfigGenerator {
    enum ConfigError: Errorable {
        case noDataAvailable

        var printsHelp: Bool { false }
        var errorDescription: String? { localizedDescription }
    }
}
