//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import Shared

public struct DuckDBCoverage: Codable, Hashable {
    public let application: String
    public let date: String
    public let coverage: FullCoverageReport

    public init(application: String, date: Date, coverage: FullCoverageReport) {
        self.application = application
        self.date = DateFormat.yearMontDay.string(from: date)
        self.coverage = coverage
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.application = try container.decode(String.self, forKey: .application)
        self.date = try container.decode(String.self, forKey: .date)
        self.coverage = try container.decode(FullCoverageReport.self, forKey: .coverage)
    }
}
