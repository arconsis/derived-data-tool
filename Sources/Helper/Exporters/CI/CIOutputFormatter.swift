//
//  CIOutputFormatter.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
import Shared

/// Formats coverage results as a single-line machine-parseable summary for CI environments
/// Output format: COVERAGE: {overall}% | TARGETS: {passed}/{total} | THRESHOLD: {PASS|FAIL}
public struct CIOutputFormatter {
    public init() {}

    /// Formats coverage report and validation results as a machine-parseable summary line
    /// - Parameters:
    ///   - report: The coverage report containing all targets
    ///   - validationResults: Array of threshold validation results (optional)
    /// - Returns: Single-line machine-parseable summary string
    public func format(report: CoverageReport, validationResults: [ThresholdValidationResult]? = nil) -> String {
        let overallCoverage = String(format: "%.2f", report.coverage * 100.0)

        if let results = validationResults {
            let passed = results.filter(\.passed).count
            let total = results.count
            let thresholdStatus = results.allSatisfy(\.passed) ? "PASS" : "FAIL"

            return "COVERAGE: \(overallCoverage)% | TARGETS: \(passed)/\(total) | THRESHOLD: \(thresholdStatus)"
        } else {
            // If no validation results provided, just show coverage without threshold info
            let totalTargets = report.targets.count
            return "COVERAGE: \(overallCoverage)% | TARGETS: \(totalTargets)/\(totalTargets) | THRESHOLD: N/A"
        }
    }

    /// Formats coverage metadata report and validation results as a machine-parseable summary line
    /// - Parameters:
    ///   - meta: The coverage metadata report
    ///   - validationResults: Array of threshold validation results (optional)
    /// - Returns: Single-line machine-parseable summary string
    public func format(meta: CoverageMetaReport, validationResults: [ThresholdValidationResult]? = nil) -> String {
        return format(report: meta.coverage, validationResults: validationResults)
    }
}
