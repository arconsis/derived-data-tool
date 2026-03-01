//
//  CIOutputFormatterTests.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class CIOutputFormatterTests: XCTestCase {
    var formatter: CIOutputFormatter!

    override func setUp() {
        super.setUp()
        formatter = CIOutputFormatter()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    // MARK: - Basic Formatting Tests

    func testFormatBasicCoverageReport() throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 3)
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 75.00%"))
        XCTAssertTrue(output.contains("TARGETS: 3/3"))
        XCTAssertTrue(output.contains("THRESHOLD: N/A"))
    }

    func testFormatZeroCoverage() throws {
        let report = Self.makeCoverageReport(coverage: 0.0, targetCount: 2)
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 0.00%"))
        XCTAssertTrue(output.contains("TARGETS: 2/2"))
        XCTAssertTrue(output.contains("THRESHOLD: N/A"))
    }

    func testFormatFullCoverage() throws {
        let report = Self.makeCoverageReport(coverage: 1.0, targetCount: 5)
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 100.00%"))
        XCTAssertTrue(output.contains("TARGETS: 5/5"))
        XCTAssertTrue(output.contains("THRESHOLD: N/A"))
    }

    func testFormatEmptyReport() throws {
        let report = CoverageReport(targets: [])
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 0.00%"))
        XCTAssertTrue(output.contains("TARGETS: 0/0"))
        XCTAssertTrue(output.contains("THRESHOLD: N/A"))
    }

    // MARK: - Validation Results Tests

    func testFormatWithAllValidationsPassing() throws {
        let report = Self.makeCoverageReport(coverage: 0.85, targetCount: 3)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.90, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.85, requiredThreshold: 0.75, passed: true),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.80, requiredThreshold: 0.70, passed: true)
        ]

        let output = formatter.format(report: report, validationResults: validationResults)

        XCTAssertTrue(output.contains("COVERAGE: 85.00%"))
        XCTAssertTrue(output.contains("TARGETS: 3/3"))
        XCTAssertTrue(output.contains("THRESHOLD: PASS"))
    }

    func testFormatWithSomeValidationsFailing() throws {
        let report = Self.makeCoverageReport(coverage: 0.70, targetCount: 4)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.90, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.65, requiredThreshold: 0.75, passed: false),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.80, requiredThreshold: 0.70, passed: true),
            ThresholdValidationResult(targetName: "Target4", actualCoverage: 0.55, requiredThreshold: 0.60, passed: false)
        ]

        let output = formatter.format(report: report, validationResults: validationResults)

        XCTAssertTrue(output.contains("COVERAGE: 70.00%"))
        XCTAssertTrue(output.contains("TARGETS: 2/4"))
        XCTAssertTrue(output.contains("THRESHOLD: FAIL"))
    }

    func testFormatWithAllValidationsFailing() throws {
        let report = Self.makeCoverageReport(coverage: 0.45, targetCount: 2)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.40, requiredThreshold: 0.80, passed: false),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.50, requiredThreshold: 0.75, passed: false)
        ]

        let output = formatter.format(report: report, validationResults: validationResults)

        XCTAssertTrue(output.contains("COVERAGE: 45.00%"))
        XCTAssertTrue(output.contains("TARGETS: 0/2"))
        XCTAssertTrue(output.contains("THRESHOLD: FAIL"))
    }

    func testFormatWithEmptyValidationResults() throws {
        let report = Self.makeCoverageReport(coverage: 0.80, targetCount: 3)
        let validationResults: [ThresholdValidationResult] = []

        let output = formatter.format(report: report, validationResults: validationResults)

        XCTAssertTrue(output.contains("COVERAGE: 80.00%"))
        XCTAssertTrue(output.contains("TARGETS: 0/0"))
        XCTAssertTrue(output.contains("THRESHOLD: PASS"))
    }

    // MARK: - CoverageMetaReport Tests

    func testFormatMetaReportWithoutValidation() throws {
        let report = Self.makeCoverageReport(coverage: 0.82, targetCount: 4)
        let meta = Self.makeCoverageMetaReport(report: report)

        let output = formatter.format(meta: meta)

        XCTAssertTrue(output.contains("COVERAGE: 82.00%"))
        XCTAssertTrue(output.contains("TARGETS: 4/4"))
        XCTAssertTrue(output.contains("THRESHOLD: N/A"))
    }

    func testFormatMetaReportWithValidation() throws {
        let report = Self.makeCoverageReport(coverage: 0.92, targetCount: 2)
        let meta = Self.makeCoverageMetaReport(report: report)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.95, requiredThreshold: 0.90, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.89, requiredThreshold: 0.85, passed: true)
        ]

        let output = formatter.format(meta: meta, validationResults: validationResults)

        XCTAssertTrue(output.contains("COVERAGE: 92.00%"))
        XCTAssertTrue(output.contains("TARGETS: 2/2"))
        XCTAssertTrue(output.contains("THRESHOLD: PASS"))
    }

    // MARK: - Format Verification Tests

    func testOutputFormatIsSingleLine() throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 3)
        let output = formatter.format(report: report)

        XCTAssertFalse(output.contains("\n"), "Output should be a single line")
    }

    func testOutputContainsPipe() throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 3)
        let output = formatter.format(report: report)

        let pipeCount = output.filter { $0 == "|" }.count
        XCTAssertEqual(pipeCount, 2, "Output should contain exactly 2 pipe separators")
    }

    func testOutputComponentsInCorrectOrder() throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 3)
        let output = formatter.format(report: report)

        guard let coverageRange = output.range(of: "COVERAGE:"),
              let targetsRange = output.range(of: "TARGETS:"),
              let thresholdRange = output.range(of: "THRESHOLD:") else {
            XCTFail("Output missing required components")
            return
        }

        XCTAssertTrue(coverageRange.lowerBound < targetsRange.lowerBound)
        XCTAssertTrue(targetsRange.lowerBound < thresholdRange.lowerBound)
    }

    // MARK: - Edge Cases

    func testFormatWithVeryLowCoverage() throws {
        let report = Self.makeCoverageReport(coverage: 0.01, targetCount: 1)
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 1.00%"))
    }

    func testFormatWithHighPrecisionCoverage() throws {
        let report = Self.makeCoverageReport(coverage: 0.876543, targetCount: 1)
        let output = formatter.format(report: report)

        // Due to integer truncation in the helper, 0.876543 * 1000 = 876 covered lines
        // This results in 876/1000 = 0.876 = 87.60%
        XCTAssertTrue(output.contains("COVERAGE: 87.60%"))
    }

    func testFormatWithSingleTarget() throws {
        let report = Self.makeCoverageReport(coverage: 0.50, targetCount: 1)
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("TARGETS: 1/1"))
    }

    func testFormatWithManyTargets() throws {
        let report = Self.makeCoverageReport(coverage: 0.88, targetCount: 25)
        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("TARGETS: 25/25"))
    }
}

// MARK: - Test Helpers

extension CIOutputFormatterTests {
    /// Creates a mock CoverageReport with specified coverage percentage and target count
    /// - Parameters:
    ///   - coverage: The overall coverage percentage (0.0 to 1.0)
    ///   - targetCount: Number of targets to create
    /// - Returns: A CoverageReport with the specified characteristics
    static func makeCoverageReport(coverage: Double, targetCount: Int) -> CoverageReport {
        let executableLines = 1000
        let totalCoveredLines = Int(coverage * Double(executableLines * targetCount))
        let coveredLinesPerTarget = totalCoveredLines / max(targetCount, 1)

        let targets = (0 ..< targetCount).map { index in
            makeTarget(
                name: "Target\(index + 1)",
                executableLines: executableLines,
                coveredLines: coveredLinesPerTarget
            )
        }

        return CoverageReport(targets: targets)
    }

    /// Creates a mock Target with specified coverage
    /// - Parameters:
    ///   - name: Name of the target
    ///   - executableLines: Number of executable lines
    ///   - coveredLines: Number of covered lines
    /// - Returns: A Target with the specified characteristics
    static func makeTarget(name: String, executableLines: Int, coveredLines: Int) -> Target {
        let function = Function(
            name: "testFunction",
            executableLines: executableLines,
            coveredLines: coveredLines,
            lineNumber: 1,
            executionCount: coveredLines
        )

        let file = File(
            name: "\(name).swift",
            path: "/path/to/\(name).swift",
            functions: [function]
        )

        return Target(name: name, files: [file])
    }

    /// Creates a mock CoverageMetaReport
    /// - Parameter report: The CoverageReport to wrap
    /// - Returns: A CoverageMetaReport containing the report
    static func makeCoverageMetaReport(report: CoverageReport) -> CoverageMetaReport {
        let url = URL(fileURLWithPath: "/tmp/Run-TestApp-2023.05.08_15-14-43-+0200.xcresult")
        guard let fileInfo = try? XCResultFile(with: url) else {
            fatalError("Failed to create XCResultFile")
        }

        return CoverageMetaReport(fileInfo: fileInfo, coverage: report)
    }
}
