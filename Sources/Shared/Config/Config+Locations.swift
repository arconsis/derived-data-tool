//
//  Config+Locations.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public extension Config {
    struct Locations: Codable, CustomStringConvertible {
        public let currentReport: String?
        public let reportType: ReportType?
        public let archive: String?
        public let databasePath: String?

        enum CodingKeys: String, CodingKey {
            case currentReport = "current_report"
            case reportType = "type"
            case archive
            case databasePath = "database_path"
        }

        public init(currentReport: String? = nil,
                    reportType: ReportType? = nil,
                    archive: String? = nil,
                    databasePath: String? = nil)
        {
            self.currentReport = currentReport
            self.reportType = reportType
            self.archive = archive
            self.databasePath = databasePath
        }

        public var description: String {
            return """
            Report: \(currentReport?.description ?? "N/A")
            Type: \(reportType?.rawValue ?? "N/A")
            Archive: \(archive?.description ?? "N/A")
            Database: \(databasePath?.description ?? "N/A")
            """
        }

        public enum ReportType: String, Codable {
            case markdown
        }
    }
}
