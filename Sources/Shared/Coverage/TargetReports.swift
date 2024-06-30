//
//  TargetReports.swift
//
//
//  Created by Moritz Ellerbrock on 27.04.23.
//

import Foundation

public typealias TargetReports = [TargetReportElement]

// MARK: - TargetReportElement

public struct TargetReportElement: Codable, Hashable, Coverage {
    public var coverage: Double { Double(coveredLines) / Double(executableLines) }

    public let coveredLines: Int
    public let executableLines: Int
    public var type: CoverageType { .report }
    public let name: String

    static func += (lhs: Self, rhs: Self) -> Self {
        let name = lhs.name.endIndex > rhs.name.endIndex ? lhs.name : rhs.name
        let coveredLines = lhs.coveredLines + rhs.coveredLines
        let executableLines = lhs.executableLines + rhs.executableLines

        return .init(coveredLines: coveredLines,
                     executableLines: executableLines,
                     name: name)
    }
}
