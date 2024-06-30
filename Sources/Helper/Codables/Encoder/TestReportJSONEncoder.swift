//
//  TestReportJSONEncoder.swift
//
//
//  Created by Moritz Ellerbrock on 09.05.23.
//

import Foundation
import Shared

struct TestReportJSONEncoder: TestReportEncoder {
    func encode(_ file: File) throws -> String {
        try encodeCoverage(file)
    }

    func encode(_ target: Target) throws -> String {
        try encodeCoverage(target)
    }

    func encode(_ coverageReport: CoverageReport) throws -> String {
        try encodeCoverage(coverageReport)
    }

    func encode(_ targetReports: TargetReports) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(targetReports)
        guard let value = String(data: data, encoding: .utf8) else {
            throw TestReportEncoderError.unknown
        }
        return value
    }

    private func encodeCoverage(_ coverage: any Coverage) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(coverage)
        guard let value = String(data: data, encoding: .utf8) else {
            throw TestReportEncoderError.unknown
        }
        return value
    }
}
