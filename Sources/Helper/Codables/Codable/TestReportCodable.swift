//
//  TestReportCodable.swift
//
//
//  Created by Moritz Ellerbrock on 09.05.23.
//

import Foundation
import Shared

public enum TestReportEncoderError: Error {
    case unknown
}

public enum TestReportDecoderError: Error {
    case unknown
}

public protocol TestReportEncoder {
    func encode(_: CoverageReport) throws -> String
    func encode(_: TargetReports) throws -> String
    func encode(_: File) throws -> String
    func encode(_: Target) throws -> String
}

public protocol TestReportDecoder {
    func decode(_: String) throws -> CoverageReport
    func decode(_: String) throws -> TargetReports
}
