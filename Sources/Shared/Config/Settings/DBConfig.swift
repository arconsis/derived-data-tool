//
//  DBConfig.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

struct DBConfig: SettingsObjectify {
    init(values: [String: String]) throws {
        self = try Self.fromDict(values)
    }

    func toDict() throws -> [String: String] {
        toDictionary()
    }

    let hostname: String
    let port: Int
    let name: String
    let username: String
    let password: String?
}
