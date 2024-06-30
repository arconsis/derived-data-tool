//
//  GithubExportSettings.swift
//
//
//  Created by Moritz Ellerbrock on 10.07.23.
//

import Foundation

public struct GithubExportSettings: SettingsObjectify {
    private static let top: String = "top"
    private static let last: String = "last"
    private static let uncovered: String = "uncovered"

    public let top: Int
    public let last: Int
    public let areUncoveredTargetsIncluded: Bool

    public init(values: [String: String]) throws {
        if let topString = values[Self.top], let top = Int(topString) {
            self.top = top
        } else {
            top = 5
        }

        if let lastString = values[Self.last], let last = Int(lastString) {
            self.last = last
        } else {
            last = 5
        }

        let isUncoveredString = values[Self.uncovered]
        areUncoveredTargetsIncluded = !(isUncoveredString?.isEmpty ?? true)
    }

    public func toDict() throws -> [String: String] {
        var dict = [String: String]()
        dict[Self.top] = "\(top)"
        dict[Self.last] = "\(last)"
        dict[Self.uncovered] = areUncoveredTargetsIncluded.description
        return dict
    }
}

public extension GithubExportSettings {
    enum GithubExportSettingsError: LocalizedError {
        case missing(key: String)

        public var errorDescription: String? {
            switch self {
            case let .missing(key):
                return "GithubExporter settings is missing \(key) key with value"
            }
        }
    }
}
