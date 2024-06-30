//
//  JSONReport.swift
//
//
//  Created by Moritz Ellerbrock on 29.04.23.
//

import Foundation

public typealias DetailedReport = JSONReport

public struct JSONReport: Codable, Hashable {
    public init(name: String, reports: TargetReports, creationDate: Date) {
        self.name = name
        self.creationDate = creationDate
        self.reports = reports

        coverage = {
            var coveredLines: Int = 0
            var executableLines: Int = 0
            for target in reports {
                coveredLines += target.coveredLines
                executableLines += target.executableLines
            }

            return Double(coveredLines) / Double(executableLines)
        }()

        calendarWeek = {
            let calendar = Calendar(identifier: .gregorian)
            let cw = calendar.component(.weekOfYear, from: creationDate)
            return "CW \(cw)"
        }()
    }

    public let name: String
    public let reports: TargetReports
    public let creationDate: Date
    public let coverage: Double
    public var calendarWeek: String
}

public extension JSONReport {
    func filename() -> String {
        let dateString = DateFormat.yearMontDay.string(from: creationDate)
        return "\(dateString)_\(name).json"
    }
}
