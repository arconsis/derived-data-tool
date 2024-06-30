//
//  CompareError.swift
//
//
//  Created by Moritz Ellerbrock on 29.11.23.
//

import Foundation

enum CompareError: Error {
    case archivePathIsMissing
    case currentReportLocationMissing
    case internalError
    case noReportFileToCompareTo
    case noXCResultFilesFound(location: String)
}
