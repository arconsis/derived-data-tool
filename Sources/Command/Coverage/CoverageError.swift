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
    case thresholdFailedAbsolute(expected: Double, actual: Double)
    case thresholdFailedRelative(maxDrop: Double, actualDrop: Double)
    case thresholdFailedPerTarget(target: String, expected: Double, actual: Double)

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
        case let .thresholdFailedAbsolute(expected: expected, actual: actual):
            return "Coverage threshold failed: Expected minimum \(String(format: "%.2f", expected))%, but actual coverage is \(String(format: "%.2f", actual))%"
        case let .thresholdFailedRelative(maxDrop: maxDrop, actualDrop: actualDrop):
            return "Coverage drop threshold exceeded: Maximum allowed drop is \(String(format: "%.2f", maxDrop))%, but coverage dropped by \(String(format: "%.2f", actualDrop))%"
        case let .thresholdFailedPerTarget(target: target, expected: expected, actual: actual):
            return "Target '\(target)' coverage threshold failed: Expected minimum \(String(format: "%.2f", expected))%, but actual coverage is \(String(format: "%.2f", actual))%"
        }
    }

    var description: String { localizedDescription }
}
