//
//  SlackSettings.swift
//
//
//  Created by Moritz Ellerbrock on 10.07.23.
//

import Foundation

public struct SlackSettings: SettingsObjectify {
    private static let webhookKey: String = "webhookVariable"
    private static let format: String = "format"

    let webhookEnvironmentVariable: String
    var format: [String: String]

    public init(values: [String: String]) throws {
        guard let webhookEnvironmentVariable = values[Self.webhookKey] else {
            throw SlackSettingsError.missing(key: Self.webhookKey)
        }
        self.webhookEnvironmentVariable = webhookEnvironmentVariable

        guard
            let format = values[Self.format],
            let data = format.data(using: .utf8)
        else {
            throw SlackSettingsError.missing(key: Self.format)
        }

        guard let jsonObject = try? SingleDecoder.shared.decode([String: String].self, from: data) else {
            throw SlackSettingsError.missing(key: Self.format)
        }

        self.format = jsonObject
    }

    public func toDict() throws -> [String: String] {
        var dict = [String: String]()

        dict[Self.webhookKey] = webhookEnvironmentVariable

        let jsonData = try SingleEncoder.shared.encode(format)
        let json = String(data: jsonData, encoding: .utf8)

        dict[Self.format] = json

        return dict
    }
}

public extension SlackSettings {
    enum SlackSettingsError: LocalizedError {
        case missing(key: String)

        public var errorDescription: String? {
            switch self {
            case let .missing(key):
                return "Slack settings is missing \(key) key with value"
            }
        }
    }
}
