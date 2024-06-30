//
//  Config+Tool.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public extension Config {
    struct Tool: Codable {
        let settingsVault: [String: String]
        private let type: ToolType

        public var name: ToolType.RawValue { type.rawValue }

        init(_ type: ToolType, settingsVault: [String: String]) {
            self.type = type
            self.settingsVault = settingsVault
        }

        public var settingsObject: SettingsObjectify? {
            switch type {
            case .archiver:
                return try? ArchiverSettings(values: settingsVault)
            case .githubExporter:
                return try? GithubExportSettings(values: settingsVault)
            case .htmlExporter:
                return nil
            case .slack:
                return try? SlackSettings(values: settingsVault)
            case .archiverDB:
                return try? DBConfig(values: settingsVault)
            }
        }

        enum CodingKeys: String, CodingKey {
            case type
            case settingsVault = "settings"
        }
    }
}

public extension Config.Tool {
    enum ToolType: String, Codable, CaseIterable {
        case archiver
        case archiverDB = "archiver_db"
        case githubExporter = "github_exporter"
        case htmlExporter = "html_exporter"
        case slack = "slack_reporter"

        fileprivate var acceptedKeys: [String] {
            switch self {
            case .archiver:
                return ["limit"]
            case .githubExporter:
                return ["top", "last", "uncovered"]
            case .htmlExporter:
                return []
            case .slack:
                return ["format", "webhookVariable"]
            case .archiverDB:
                return ["hostname", "port", "name", "username", "password"]
            }
        }

        // Not used yet, might be interesting to validate input
        static var allAcceptedKeys: [String] {
            var acceptedKeys: [String] = []
            for keys in ToolType.allCases {
                acceptedKeys.append(contentsOf: keys.acceptedKeys)
            }
            return acceptedKeys
        }
    }
}
