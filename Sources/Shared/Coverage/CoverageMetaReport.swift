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

    public init(fileInfo: XCResultFile, coverage: CoverageReport) {
        self.fileInfo = fileInfo
        self.coverage = coverage
    }
}
