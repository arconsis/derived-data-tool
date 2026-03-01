//
//  CISummaryExporter.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import DependencyInjection
import Foundation
import Shared

/// CI Summary structure for JSON export
/// Contains overall coverage, per-target coverage, and threshold validation results
public struct CISummary: Codable {
    public let overallCoverage: Double
    public let thresholdStatus: String
    public let targets: [TargetSummary]
    public let failures: [FailureSummary]

    public struct TargetSummary: Codable {
        public let name: String
        public let coverage: Double
        public let coveredLines: Int
        public let executableLines: Int
        public let passed: Bool?

        public init(name: String, coverage: Double, coveredLines: Int, executableLines: Int, passed: Bool?) {
            self.name = name
            self.coverage = coverage
            self.coveredLines = coveredLines
            self.executableLines = executableLines
            self.passed = passed
        }
    }

    public struct FailureSummary: Codable {
        public let targetName: String
        public let actualCoverage: Double
        public let requiredThreshold: Double

        public init(targetName: String, actualCoverage: Double, requiredThreshold: Double) {
            self.targetName = targetName
            self.actualCoverage = actualCoverage
            self.requiredThreshold = requiredThreshold
        }
    }

    public init(overallCoverage: Double, thresholdStatus: String, targets: [TargetSummary], failures: [FailureSummary]) {
        self.overallCoverage = overallCoverage
        self.thresholdStatus = thresholdStatus
        self.targets = targets
        self.failures = failures
    }
}

/// CISummaryExporter - Exports coverage data as structured JSON for CI consumption
public class CISummaryExporter {
    private let fileHandler: FileHandler
    private let outputUrl: URL

    @Injected(\.logger) private var logger: Loggerable

    public init(fileHandler: FileHandler, outputUrl: URL) {
        self.fileHandler = fileHandler
        self.outputUrl = outputUrl
    }

    /// Creates and exports a CI summary JSON file
    /// - Parameters:
    ///   - report: The coverage report containing all targets
    ///   - validationResults: Optional threshold validation results
    public func export(report: CoverageReport, validationResults: [ThresholdValidationResult]? = nil) async {
        let summary = createSummary(from: report, validationResults: validationResults)

        do {
            let jsonContent = try encodeToJSON(summary)
            try saveJSON(content: jsonContent, at: outputUrl)
            logger.debug("CI summary exported to: \(outputUrl.path)")
        } catch {
            logger.error("Failed to export CI summary: \(error.localizedDescription)")
        }
    }

    /// Creates and exports a CI summary JSON file from meta report
    /// - Parameters:
    ///   - meta: The coverage metadata report
    ///   - validationResults: Optional threshold validation results
    public func export(meta: CoverageMetaReport, validationResults: [ThresholdValidationResult]? = nil) async {
        await export(report: meta.coverage, validationResults: validationResults)
    }

    /// Creates a CISummary from coverage report and validation results
    private func createSummary(from report: CoverageReport, validationResults: [ThresholdValidationResult]?) -> CISummary {
        let overallCoverage = report.coverage * 100.0

        let thresholdStatus: String
        if let results = validationResults {
            thresholdStatus = results.allSatisfy(\.passed) ? "pass" : "fail"
        } else {
            thresholdStatus = "n/a"
        }

        // Create target summaries
        let targets = report.targets.map { target -> CISummary.TargetSummary in
            let passed = validationResults?.first(where: { $0.targetName == target.name })?.passed
            return CISummary.TargetSummary(
                name: target.name,
                coverage: target.coverage * 100.0,
                coveredLines: target.coveredLines,
                executableLines: target.executableLines,
                passed: passed
            )
        }

        // Create failure summaries
        let failures: [CISummary.FailureSummary]
        if let results = validationResults {
            failures = results.filter { !$0.passed }.map { result in
                CISummary.FailureSummary(
                    targetName: result.targetName,
                    actualCoverage: result.actualCoveragePercentage,
                    requiredThreshold: result.requiredThreshold * 100.0
                )
            }
        } else {
            failures = []
        }

        return CISummary(
            overallCoverage: overallCoverage,
            thresholdStatus: thresholdStatus,
            targets: targets,
            failures: failures
        )
    }

    /// Encodes CISummary to pretty-printed JSON string
    private func encodeToJSON(_ summary: CISummary) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(summary)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw CISummaryExporterError.encodingFailed
        }

        return jsonString
    }

    /// Saves JSON content to file
    private func saveJSON(content: String, at url: URL) throws {
        try fileHandler.writeContent(content, at: url, overwrite: true)
    }
}

// MARK: - Errors

private extension CISummaryExporter {
    enum CISummaryExporterError: Error {
        case encodingFailed
    }
}
