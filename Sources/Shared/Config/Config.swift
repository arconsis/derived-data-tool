//
//  Config.swift
//
//
//  Created by Moritz Ellerbrock on 28.04.23.
//

import Foundation

public struct Config: Codable, CustomStringConvertible {
    public let excluded: Excluded?
    public let filterXCResults: [String]?
    public let locations: Locations?
    private let tools: [Tool]?
//    public let workflow: Workflow?

    enum CodingKeys: String, CodingKey {
        case excluded, archiver, locations, tools
        case filterXCResults = "filter_results"
    }

    init(excluded: Config.Excluded? = nil,
         filterXCResults: [String]? = nil,
         locations: Config.Locations? = nil,
         tools: [Tool]? = nil)
    {
        self.excluded = excluded
        self.filterXCResults = filterXCResults
        self.locations = locations
        self.tools = tools
    }

    func tool(_ toolType: Tool.ToolType) -> Tool {
        if let tool = tools?.first(where: { $0.name == toolType.rawValue }) {
            return tool
        } else {
            return Tool(toolType, settingsVault: [:])
        }
    }

    public func settings(_ toolType: Tool.ToolType) throws -> SettingsObjectify {
        guard let settingsObject = tool(toolType).settingsObject else {
            throw ConfigError.settingObjectNotConfigured(toolType.rawValue)
        }

        return settingsObject
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Config.CodingKeys> = try decoder.container(keyedBy: Config.CodingKeys.self)

        excluded = try container.decodeIfPresent(Excluded.self, forKey: .excluded)
        locations = try container.decodeIfPresent(Locations.self, forKey: .locations)
        filterXCResults = try container.decodeIfPresent([String].self, forKey: .filterXCResults)
        tools = try container.decodeIfPresent([Tool].self, forKey: .tools)
    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<Config.CodingKeys> = encoder.container(keyedBy: Config.CodingKeys.self)

        try container.encodeIfPresent(excluded, forKey: .excluded)
        try container.encodeIfPresent(locations, forKey: .locations)
        try container.encodeIfPresent(filterXCResults, forKey: .filterXCResults)
        try container.encodeIfPresent(tools, forKey: .tools)
    }

    public var description: String {
        return """
        Excluded: \(excluded?.description ?? "N/A")
        Locations: \(locations?.description ?? "N/A")
        """
    }

    public static func makeInitial() -> Self {
        let excluded: Excluded = .init(targets: ["Pod_*"],
                                       files: ["*ViewController.swift"],
                                       functions: ["deinit"])

        let filterXCResults = ["ApplicationName"]

        let locations: Locations = .init(currentReport: "Reports/last_report.md",
                                         reportType: .markdown,
                                         archive: "Reports/Archive/")

        let tools: [Tool] = [
            Tool(Tool.ToolType.archiver,
                 settingsVault: ["limit": "5"]),
            Tool(Tool.ToolType.githubExporter,
                 settingsVault: ["top": "5", "last": "5"]),
            Tool(Tool.ToolType.htmlExporter,
                 settingsVault: ["something": "123456"]),
            Tool(Tool.ToolType.slack,
                 settingsVault: ["format": ""]),
        ]
        return .init(excluded: excluded,
                     filterXCResults: filterXCResults,
                     locations: locations,
                     tools: tools)
    }
}

public extension Config {
//    func integerSetting(_ setting:  Config.Settings, for tool: Config.Tool.ToolType) -> Int? {
//        guard let stringValue = self.tool(tool).settings[setting.rawValue],
//              let value = Int(stringValue) else {
//            return nil
//        }
//        return value
//    }
//
//    func integerSetting(_ setting: Config.Settings, for tool: Config.Tool.ToolType, fallback: Int?) -> Int {
//        let defaultValue = fallback ?? 5
//        guard let integerValue = integerSetting(setting, for: tool) else {
//            return defaultValue
//        }
//        return integerValue
//    }
//
//    func stringSetting(_ setting:  Config.Settings, for tool: Config.Tool.ToolType) -> String? {
//        guard let stringValue = self.tool(tool).settings[setting.rawValue] else {
//            return nil
//        }
//        return stringValue
//    }
//
//    func stringSetting(_ setting:  Config.Settings, for tool: Config.Tool.ToolType, fallback: String?) -> String {
//        guard let stringValue = stringSetting(setting, for: tool) else {
//            return fallback ?? ""
//        }
//        return stringValue
//    }
}
