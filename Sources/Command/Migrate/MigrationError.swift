//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 19.11.24.
//

import Foundation

enum MigrationError: LocalizedError, CustomStringConvertible {
    case missingDatabasePath
    case jsonContentMissing
    case noFilteredResults(filter: String)
    case noConfigFileFound
    case currentReportLocationMissing
    case archiveLocationMissing
    case internalError

    /// Retrieve the localized description for this error.
    var localizedDescription: String {
        switch self {
        case .jsonContentMissing:
            return "No Input provided"
        case let .noFilteredResults(filter: filter):
            return "After filtering the found xcresult file, there are none left to process(\(filter))"
        case .noConfigFileFound:
            return "No Config file was found"
        case .currentReportLocationMissing:
            return "Add a `current_report` entry to locations in your config file!"
        case .archiveLocationMissing:
            return "Add a `archive` entry to locations in your config file!"
        case .internalError:
            return "This should not happen but it did, wait for an update, please"
        case .missingDatabasePath:
            return "The database path is missing"
        }
    }

    var description: String { localizedDescription }
}
