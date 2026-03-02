//
//  JUnitXMLExporter.swift
//
//
//  Created by Moritz Ellerbrock on 02.03.26.
//

import DependencyInjection
import Foundation
import Shared

/// JUnitXMLExporter - Exports coverage data as JUnit XML format for CI consumption
/// Maps coverage targets to test suites and files to test cases
/// Threshold failures become test failures with descriptive messages
public class JUnitXMLExporter {
    private let fileHandler: FileHandler
    private let outputUrl: URL

    @Injected(\.logger) private var logger: Loggerable

    public init(fileHandler: FileHandler, outputUrl: URL) {
        self.fileHandler = fileHandler
        self.outputUrl = outputUrl
    }

    /// Creates and exports a JUnit XML file
    /// - Parameters:
    ///   - report: The coverage report containing all targets
    ///   - validationResults: Optional threshold validation results
    public func export(report: CoverageReport, validationResults: [ThresholdValidationResult]? = nil) async {
        do {
            let xmlContent = generateJUnitXML(from: report, validationResults: validationResults)
            try saveXML(content: xmlContent, at: outputUrl)
            logger.debug("JUnit XML report exported to: \(outputUrl.path)")
        } catch {
            logger.error("Failed to export JUnit XML report: \(error.localizedDescription)")
        }
    }

    /// Creates and exports a JUnit XML file from meta report
    /// - Parameters:
    ///   - meta: The coverage metadata report
    ///   - validationResults: Optional threshold validation results
    public func export(meta: CoverageMetaReport, validationResults: [ThresholdValidationResult]? = nil) async {
        await export(report: meta.coverage, validationResults: validationResults)
    }

    /// Generates JUnit XML from coverage report and validation results
    private func generateJUnitXML(from report: CoverageReport, validationResults: [ThresholdValidationResult]?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let timestamp = formatter.string(from: Date())

        // Calculate overall statistics
        let totalTests = report.targets.reduce(0) { $0 + $1.files.count }
        let totalFailures = calculateTotalFailures(validationResults: validationResults)
        let totalTime = 0.0 // Coverage doesn't have timing information

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <testsuites id="coverage-\(timestamp)" name="Coverage Report" tests="\(totalTests)" failures="\(totalFailures)" time="\(totalTime)" timestamp="\(timestamp)">

        """

        // Generate test suite for each target
        for target in report.targets {
            xml += generateTestSuite(for: target, validationResults: validationResults)
        }

        xml += "</testsuites>\n"

        return xml
    }

    /// Generates a test suite XML for a single target
    private func generateTestSuite(for target: Target, validationResults: [ThresholdValidationResult]?) -> String {
        let testCount = target.files.count
        let coveragePercentage = target.coverage * 100.0
        let timestamp = ISO8601DateFormatter().string(from: Date())

        // Check if this target failed threshold validation
        let validationResult = validationResults?.first { $0.targetName == target.name }
        let failures = (validationResult?.passed == false) ? 1 : 0

        var xml = """
            <testsuite id="\(escapeXML(target.name))" name="\(escapeXML(target.name))" tests="\(testCount)" skipped="0" failures="\(failures)" errors="0" timestamp="\(timestamp)" time="0.0">
                <properties>
                    <property name="coverage" value="\(String(format: "%.2f", coveragePercentage))"/>
                    <property name="coveredLines" value="\(target.coveredLines)"/>
                    <property name="executableLines" value="\(target.executableLines)"/>
                </properties>

        """

        // If target failed threshold, add a test case representing the failure
        if let result = validationResult, !result.passed {
            xml += generateThresholdFailureTestCase(for: result)
        }

        // Generate test case for each file
        for file in target.files {
            xml += generateTestCase(for: file, target: target)
        }

        xml += "    </testsuite>\n"

        return xml
    }

    /// Generates a test case for threshold failure
    private func generateThresholdFailureTestCase(for result: ThresholdValidationResult) -> String {
        let actualCoverage = String(format: "%.2f", result.actualCoveragePercentage)
        let requiredCoverage = String(format: "%.2f", result.requiredThreshold * 100.0)

        let failureMessage = "Coverage threshold not met: \(actualCoverage)% < \(requiredCoverage)%"

        return """
                <testcase name="threshold-validation" classname="\(escapeXML(result.targetName))" time="0.0">
                    <failure message="\(escapeXML(failureMessage))" type="CoverageThresholdFailure">
        Target: \(escapeXML(result.targetName))
        Actual Coverage: \(actualCoverage)%
        Required Threshold: \(requiredCoverage)%
                    </failure>
                </testcase>

        """
    }

    /// Generates a test case XML for a single file
    private func generateTestCase(for file: File, target: Target) -> String {
        let coveragePercentage = file.coverage * 100.0
        let className = escapeXML(target.name)
        let testName = escapeXML(file.name)

        return """
                <testcase name="\(testName)" classname="\(className)" time="0.0">
                    <properties>
                        <property name="coverage" value="\(String(format: "%.2f", coveragePercentage))"/>
                        <property name="coveredLines" value="\(file.coveredLines)"/>
                        <property name="executableLines" value="\(file.executableLines)"/>
                    </properties>
                </testcase>

        """
    }

    /// Calculates total failures from validation results
    private func calculateTotalFailures(validationResults: [ThresholdValidationResult]?) -> Int {
        guard let results = validationResults else { return 0 }
        return results.filter { !$0.passed }.count
    }

    /// Escapes XML special characters
    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    /// Saves XML content to file
    private func saveXML(content: String, at url: URL) throws {
        try fileHandler.writeContent(content, at: url, overwrite: true)
    }
}
