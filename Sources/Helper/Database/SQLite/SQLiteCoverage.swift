//
//  File 2.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import Shared

struct SQLiteCoverage: Identifiable, Codable {
    struct Target: Identifiable, Codable {
        let id: Int?
        let coverageReportID: Int?
        let name: String
        let executableLines: Int
        let coveredLines: Int
    }

    let id: Int?
    let date: String
    var targets: [Target]
}


extension SQLiteCoverage {
    init(with coverageReport: CoverageMetaReport) {
        self.id = nil
        self.date = DateFormat.yearMontDay.string(from: coverageReport.fileInfo.date)
        self.targets = coverageReport.coverage.targets.map { .init(with: $0) }
    }

    func toDTO() -> CoverageReport {
        .init(id: id!, date: date, targets: targets.map { $0.toDTO() })
    }
}

extension SQLiteCoverage.Target {
    init(with target: Shared.Target) {
        self.id = nil
        self.coverageReportID = nil
        self.name = target.name
        self.executableLines = target.executableLines
        self.coveredLines = target.coveredLines
    }
    func toDTO() -> CoverageReport.Target {
        .init(id: id!, coverageReportID: coverageReportID!, name: name, executableLines: executableLines, coveredLines: coveredLines)
    }
}
