//
//  CoverageMetaReport.swift
//
//
//  Created by Moritz Ellerbrock on 13.06.23.
//

import Foundation

public struct CoverageMetaReport: Codable, Equatable {
    public let fileInfo: XCResultFile
    public let coverage: CoverageReport
    public let checksum: String?

    public init(fileInfo: XCResultFile, coverage: CoverageReport, checksum: String? = nil) {
        self.fileInfo = fileInfo
        self.coverage = coverage
        self.checksum = checksum
    }
}
