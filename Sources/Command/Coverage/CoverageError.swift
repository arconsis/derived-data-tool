//
//  CoverageError.swift
//
//
//  Created by Moritz Ellerbrock on 28.11.23.
//

import Foundation

enum CoverageError: LocalizedError, CustomStringConvertible {
    case jsonContentMissing
    case noXCResultFilesFound(location: String)
    case noFilteredResults(filter: String)
    case noConfigFileFound
    case currentReportLocationMissing
    case archiveLocationMissing
    case missingDatabasePath
    case noResultsToWorkWith
    case noResultFilesToConvert
    case internalError
    case thresholdValidationFailed(failures: [(target: String, actual: Double, required: Double)])

    /// Retrieve the localized description for this error.
    var localizedDescription: String {
        switch self {
        case .jsonContentMissing:
            return "No Input provided"
        case let .noXCResultFilesFound(location: location):
            return "Could not find any .xcresult files at \(location)"
        case let .noFilteredResults(filter: filter):
            return "After filtering the found xcresult file, there are none left to process(\(filter))"
        case .noConfigFileFound:
            return "No Config file was found"
        case .currentReportLocationMissing:
            return "Add a `current_report` entry to locations in your config file!"
        case .archiveLocationMissing:
            return "Add a `archive` entry to locations in your config file!"
        case .noResultsToWorkWith:
            return "The filters and configurations set"
        case .internalError:
            return "This should not happen but it did, wait for an update, please"
        case .noResultFilesToConvert:
            return "There are no xcresult files to work with"
        case .missingDatabasePath:
            return "No database path provided"
        case let .thresholdValidationFailed(failures: failures):
            let failureDescriptions = failures.map { failure in
                "  • \(failure.target): \(String(format: "%.2f", failure.actual))% < \(String(format: "%.2f", failure.required))%"
            }.joined(separator: "\n")
            return "Coverage thresholds not met for \(failures.count) target(s):\n\(failureDescriptions)"
        }
    }

    var description: String { localizedDescription }
}
