//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 09.12.24.
//

import Foundation

public struct CoverageReport: Identifiable, Codable {
    public struct Target: Identifiable, Codable {
        public let id: Int
        public let coverageReportID: Int
        public let name: String
        public let executableLines: Int
        public let coveredLines: Int

        public init(id: Int, coverageReportID: Int, name: String, executableLines: Int, coveredLines: Int) {
            self.id = id
            self.coverageReportID = coverageReportID
            self.name = name
            self.executableLines = executableLines
            self.coveredLines = coveredLines
        }
    }

    public init(id: Int, date: String, targets: [Target]) {
        self.id = id
        self.date = date
        self.targets = targets
    }

    public let id: Int
    public let date: String
    public internal(set) var targets: [Target]
}


