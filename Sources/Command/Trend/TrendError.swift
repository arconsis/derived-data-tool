//
//  TrendError.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation

enum TrendError: LocalizedError, CustomStringConvertible {
    case noReportsInDatabase
    case insufficientDataPoints(minimum: Int)
    case invalidDateRange(start: Date, end: Date)
    case targetNotFound(name: String)
    case chartGenerationFailed(reason: String)

    /// Retrieve the localized description for this error.
    var localizedDescription: String {
        switch self {
        case .noReportsInDatabase:
            return "No coverage reports found in database. Run the coverage command first to generate reports."
        case let .insufficientDataPoints(minimum: minimum):
            return "Insufficient data points to generate trend chart. Need at least \(minimum) reports."
        case let .invalidDateRange(start: start, end: end):
            return "Invalid date range: start date (\(start)) must be before end date (\(end))"
        case let .targetNotFound(name: name):
            return "Target '\(name)' not found in coverage reports"
        case let .chartGenerationFailed(reason: reason):
            return "Failed to generate chart: \(reason)"
        }
    }

    var description: String { localizedDescription }
}
