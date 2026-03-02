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
    private static let prCommentTopFiles: String = "pr_comment_top_files"
    private static let prCommentIncludeUntested: String = "pr_comment_include_untested"

    public let top: Int
    public let last: Int
    public let areUncoveredTargetsIncluded: Bool
    public let prCommentTopFiles: Int
    public let prCommentIncludeUntested: Bool

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

        if let topFilesString = values[Self.prCommentTopFiles], let topFiles = Int(topFilesString) {
            prCommentTopFiles = topFiles
        } else {
            prCommentTopFiles = 5
        }

        let includeUntestedString = values[Self.prCommentIncludeUntested]
        prCommentIncludeUntested = !(includeUntestedString?.isEmpty ?? true)
    }

    public func toDict() throws -> [String: String] {
        var dict = [String: String]()
        dict[Self.top] = "\(top)"
        dict[Self.last] = "\(last)"
        dict[Self.uncovered] = areUncoveredTargetsIncluded.description
        dict[Self.prCommentTopFiles] = "\(prCommentTopFiles)"
        dict[Self.prCommentIncludeUntested] = prCommentIncludeUntested.description
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
