//
//  SettingsObjectify.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public protocol SettingsObjectify: Codable {
    init(values: [String: String]) throws

    func toDict() throws -> [String: String]
}

public extension SettingsObjectify {
    init(values: [String: String]) throws {
        self = try Self.fromDict(values)
    }

    func toDict() throws -> [String: String] {
        toDictionary()
    }
}
