//
//  ArchiverSettings.swift
//
//
//  Created by Moritz Ellerbrock on 10.07.23.
//

import Foundation

struct ArchiverSettings: SettingsObjectify {
    private static let limit: String = "limit"

    let limit: Int

    init(values: [String: String]) throws {
        guard
            let limitString = values[Self.limit],
            let limit = Int(limitString)
        else {
            throw ArchiverSettingsError.missing(key: Self.limit)
        }
        self.limit = limit
    }

    func toDict() throws -> [String: String] {
        [Self.limit: "\(limit)"]
    }
}

extension ArchiverSettings {
    enum ArchiverSettingsError: LocalizedError {
        case missing(key: String)
    }
}
