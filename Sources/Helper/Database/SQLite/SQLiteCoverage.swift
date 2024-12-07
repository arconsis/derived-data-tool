//
//  File 2.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation

public struct SQLiteCoverage: Identifiable, Codable {
    public struct Target: Identifiable, Codable {
        public let id: Int
        public let coverageReportID: Int
        public let name: String
        public let executableLines: Int
        public let coveredLines: Int
    }

    public let id: Int
    public let date: String
    public internal(set) var targets: [Target]
}


