//
//  CIOutputModeTests.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
@testable import Coverage
@testable import Helper
@testable import Shared
import XCTest

final class CIOutputModeTests: XCTestCase {
    var dbConnector: DatabaseConnector!
    var repository: ReportModelRepository!

    override func setUp() async throws {
        try await super.setUp()
        dbConnector = DatabaseConnector()
        try await dbConnector.connect()
        repository = ReportModelRepositoryImpl(db: dbConnector.db, connector: dbConnector)
    }

    override func tearDown() async throws {
        try await dbConnector.disconnect()
        try await super.tearDown()
    }

    // MARK: - CI Mode Output Tests

    func testCIMode_WithNoThresholds_OutputsBasicSummary() throws {
        let report = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 80.00%"))
        XCTAssertTrue(output.contains("THRESHOLD: N/A"))
        XCTAssertFalse(output.contains("\n"), "Output should be a single line")
    }

    func testCIMode_WithPassingThreshold_OutputsSummaryWithPass() throws {
        let report = Self.makeCoverageReport(coveredLines: 85, executableLines: 100)
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.85,
            requiredThreshold: 0.80,
            passed: true
        )
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report, validationResults: [result])

        XCTAssertTrue(output.contains("COVERAGE: 85.00%"))
        XCTAssertTrue(output.contains("THRESHOLD: PASS"))
        XCTAssertTrue(output.contains("TARGETS: 1/1"))
    }

    func testCIMode_WithFailingThreshold_OutputsSummaryWithFail() throws {
        let report = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.70,
            requiredThreshold: 0.80,
            passed: false
        )
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report, validationResults: [result])

        XCTAssertTrue(output.contains("COVERAGE: 70.00%"))
        XCTAssertTrue(output.contains("THRESHOLD: FAIL"))
        XCTAssertTrue(output.contains("TARGETS: 0/1"))
    }

    // MARK: - GitHub Actions Annotations Tests

    func testCIMode_WithFailingThreshold_GeneratesGitHubAnnotations() throws {
        let result = ThresholdValidationResult(
            targetName: "MyTarget",
            actualCoverage: 0.70,
            requiredThreshold: 0.80,
            passed: false
        )

        let annotationsFormatter = GitHubActionsAnnotations()
        let annotations = annotationsFormatter.format(results: [result])

        XCTAssertFalse(annotations.isEmpty)
        XCTAssertTrue(annotations.contains("::error"))
        XCTAssertTrue(annotations.contains("file=MyTarget"))
        XCTAssertTrue(annotations.contains("70.00"))
        XCTAssertTrue(annotations.contains("0.80"))
    }

    func testCIMode_WithPassingThreshold_GeneratesNoAnnotations() throws {
        let result = ThresholdValidationResult(
            targetName: "MyTarget",
            actualCoverage: 0.85,
            requiredThreshold: 0.80,
            passed: true
        )

        let annotationsFormatter = GitHubActionsAnnotations()
        let annotations = annotationsFormatter.format(results: [result])

        XCTAssertTrue(annotations.isEmpty)
    }

    func testCIMode_WithMultipleFailures_GeneratesMultipleAnnotations() throws {
        let results = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.70, requiredThreshold: 0.80, passed: false),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.60, requiredThreshold: 0.75, passed: false),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.90, requiredThreshold: 0.85, passed: true)
        ]

        let annotationsFormatter = GitHubActionsAnnotations()
        let annotations = annotationsFormatter.format(results: results)

        let lines = annotations.split(separator: "\n")
        XCTAssertEqual(lines.count, 2, "Should generate 2 annotations for 2 failures")
        XCTAssertTrue(annotations.contains("Target1"))
        XCTAssertTrue(annotations.contains("Target2"))
        XCTAssertFalse(annotations.contains("Target3"))
    }

    // MARK: - CI JSON Summary Export Tests

    func testCIMode_JSONExport_CreatesValidJSON() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outputUrl = tempDir.appendingPathComponent("ci-summary-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: outputUrl)
        }

        let report = Self.makeCoverageReport(coveredLines: 85, executableLines: 100)
        let results = [
            ThresholdValidationResult(targetName: "TestTarget", actualCoverage: 0.85, requiredThreshold: 0.80, passed: true)
        ]

        let fileHandler = FileHandler()
        let exporter = CISummaryExporter(fileHandler: fileHandler, outputUrl: outputUrl)
        await exporter.export(report: report, validationResults: results)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputUrl.path))

        let jsonData = try Data(contentsOf: outputUrl)
        let summary = try JSONDecoder().decode(CISummary.self, from: jsonData)

        XCTAssertEqual(summary.overallCoverage, 85.0, accuracy: 0.01)
        XCTAssertEqual(summary.thresholdStatus, "pass")
        XCTAssertEqual(summary.targets.count, 1)
        XCTAssertEqual(summary.targets.first?.name, "TestTarget")
        XCTAssertEqual(summary.failures.count, 0)
    }

    func testCIMode_JSONExport_WithFailures_IncludesFailureDetails() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outputUrl = tempDir.appendingPathComponent("ci-summary-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: outputUrl)
        }

        let report = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let results = [
            ThresholdValidationResult(targetName: "FailingTarget", actualCoverage: 0.70, requiredThreshold: 0.80, passed: false)
        ]

        let fileHandler = FileHandler()
        let exporter = CISummaryExporter(fileHandler: fileHandler, outputUrl: outputUrl)
        await exporter.export(report: report, validationResults: results)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputUrl.path))

        let jsonData = try Data(contentsOf: outputUrl)
        let summary = try JSONDecoder().decode(CISummary.self, from: jsonData)

        XCTAssertEqual(summary.overallCoverage, 70.0, accuracy: 0.01)
        XCTAssertEqual(summary.thresholdStatus, "fail")
        XCTAssertEqual(summary.failures.count, 1)

        guard let failure = summary.failures.first else {
            XCTFail("Expected at least one failure")
            return
        }

        XCTAssertEqual(failure.targetName, "FailingTarget")
        XCTAssertEqual(failure.actualCoverage, 70.0, accuracy: 0.01)
        XCTAssertEqual(failure.requiredThreshold, 80.0, accuracy: 0.01)
    }

    func testCIMode_JSONExport_WithoutValidation_ShowsNA() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outputUrl = tempDir.appendingPathComponent("ci-summary-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: outputUrl)
        }

        let report = Self.makeCoverageReport(coveredLines: 75, executableLines: 100)

        let fileHandler = FileHandler()
        let exporter = CISummaryExporter(fileHandler: fileHandler, outputUrl: outputUrl)
        await exporter.export(report: report, validationResults: nil)

        let jsonData = try Data(contentsOf: outputUrl)
        let summary = try JSONDecoder().decode(CISummary.self, from: jsonData)

        XCTAssertEqual(summary.thresholdStatus, "n/a")
        XCTAssertTrue(summary.failures.isEmpty)
    }

    // MARK: - Integration Tests with Multiple Targets

    func testCIMode_WithMultipleTargets_OutputsCorrectSummary() throws {
        let targets = [
            Self.makeTarget(name: "Target1", executableLines: 100, coveredLines: 85),
            Self.makeTarget(name: "Target2", executableLines: 100, coveredLines: 90),
            Self.makeTarget(name: "Target3", executableLines: 100, coveredLines: 75)
        ]
        let report = CoverageReport(targets: targets)

        let results = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.85, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.90, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.75, requiredThreshold: 0.80, passed: false)
        ]

        let formatter = CIOutputFormatter()
        let output = formatter.format(report: report, validationResults: results)

        XCTAssertTrue(output.contains("TARGETS: 2/3"))
        XCTAssertTrue(output.contains("THRESHOLD: FAIL"))
    }

    func testCIMode_WithMultipleTargets_GeneratesCorrectAnnotations() throws {
        let results = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.85, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.70, requiredThreshold: 0.80, passed: false),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.65, requiredThreshold: 0.80, passed: false)
        ]

        let annotationsFormatter = GitHubActionsAnnotations()
        let annotations = annotationsFormatter.format(results: results)

        let lines = annotations.split(separator: "\n")
        XCTAssertEqual(lines.count, 2)

        // Verify both failing targets are in the annotations
        XCTAssertTrue(annotations.contains("Target2"))
        XCTAssertTrue(annotations.contains("Target3"))
        XCTAssertFalse(annotations.contains("Target1"))
    }

    // MARK: - Edge Cases

    func testCIMode_WithZeroCoverage_FormatsCorrectly() throws {
        let report = Self.makeCoverageReport(coveredLines: 0, executableLines: 100)
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 0.00%"))
    }

    func testCIMode_WithFullCoverage_FormatsCorrectly() throws {
        let report = Self.makeCoverageReport(coveredLines: 100, executableLines: 100)
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 100.00%"))
    }

    func testCIMode_WithEmptyReport_FormatsCorrectly() throws {
        let report = CoverageReport(targets: [])
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report)

        XCTAssertTrue(output.contains("COVERAGE: 0.00%"))
        XCTAssertTrue(output.contains("TARGETS: 0/0"))
    }

    func testCIMode_WithEmptyValidationResults_OutputsPass() throws {
        let report = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let formatter = CIOutputFormatter()

        let output = formatter.format(report: report, validationResults: [])

        XCTAssertTrue(output.contains("THRESHOLD: PASS"))
        XCTAssertTrue(output.contains("TARGETS: 0/0"))
    }

    // MARK: - Relative Threshold Tests

    func testCIMode_WithRelativeThreshold_PassesWhenWithinLimit() throws {
        let current = Self.makeCoverageReport(coveredLines: 77, executableLines: 100)

        // Simulate a relative threshold validation that passes (within 5% drop from 80%)
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.77,
            requiredThreshold: 0.75, // (80% - 5% = 75%)
            passed: true
        )

        let formatter = CIOutputFormatter()
        let output = formatter.format(report: current, validationResults: [result])

        XCTAssertTrue(output.contains("THRESHOLD: PASS"))
    }

    func testCIMode_WithRelativeThreshold_FailsWhenExceedsLimit() throws {
        let current = Self.makeCoverageReport(coveredLines: 65, executableLines: 100)

        // Simulate a relative threshold validation that fails (more than 5% drop from 80%)
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.65,
            requiredThreshold: 0.75, // (80% - 5% = 75%)
            passed: false
        )

        let formatter = CIOutputFormatter()
        let output = formatter.format(report: current, validationResults: [result])

        XCTAssertTrue(output.contains("THRESHOLD: FAIL"))
    }

    // MARK: - Per-Target Threshold Tests

    func testCIMode_WithPerTargetThresholds_ValidatesIndividually() throws {
        let targets = [
            Self.makeTarget(name: "HighCoverageTarget", executableLines: 100, coveredLines: 95),
            Self.makeTarget(name: "MediumCoverageTarget", executableLines: 100, coveredLines: 75),
            Self.makeTarget(name: "LowCoverageTarget", executableLines: 100, coveredLines: 60)
        ]
        let report = CoverageReport(targets: targets)

        // Different thresholds for different targets
        let results = [
            ThresholdValidationResult(targetName: "HighCoverageTarget", actualCoverage: 0.95, requiredThreshold: 0.90, passed: true),
            ThresholdValidationResult(targetName: "MediumCoverageTarget", actualCoverage: 0.75, requiredThreshold: 0.70, passed: true),
            ThresholdValidationResult(targetName: "LowCoverageTarget", actualCoverage: 0.60, requiredThreshold: 0.80, passed: false)
        ]

        let formatter = CIOutputFormatter()
        let output = formatter.format(report: report, validationResults: results)

        XCTAssertTrue(output.contains("TARGETS: 2/3"))
        XCTAssertTrue(output.contains("THRESHOLD: FAIL"))

        let annotationsFormatter = GitHubActionsAnnotations()
        let annotations = annotationsFormatter.format(results: results)

        XCTAssertTrue(annotations.contains("LowCoverageTarget"))
        XCTAssertFalse(annotations.contains("HighCoverageTarget"))
        XCTAssertFalse(annotations.contains("MediumCoverageTarget"))
    }

    // MARK: - Format Validation Tests

    func testCIMode_OutputFormat_IsMachineParseable() throws {
        let report = Self.makeCoverageReport(coveredLines: 75, executableLines: 100)
        let results = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.75, requiredThreshold: 0.70, passed: true)
        ]

        let formatter = CIOutputFormatter()
        let output = formatter.format(report: report, validationResults: results)

        // Verify format: COVERAGE: XX.XX% | TARGETS: X/X | THRESHOLD: STATUS
        let components = output.split(separator: "|")
        XCTAssertEqual(components.count, 3)

        XCTAssertTrue(components[0].contains("COVERAGE:"))
        XCTAssertTrue(components[0].contains("%"))
        XCTAssertTrue(components[1].contains("TARGETS:"))
        XCTAssertTrue(components[1].contains("/"))
        XCTAssertTrue(components[2].contains("THRESHOLD:"))
    }

    func testCIMode_AnnotationFormat_IsGitHubActionsCompliant() throws {
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.65,
            requiredThreshold: 0.80,
            passed: false
        )

        let annotationsFormatter = GitHubActionsAnnotations()
        let annotation = annotationsFormatter.format(results: [result])

        // Verify GitHub Actions annotation format: ::error file={name},line={line}::{message}
        XCTAssertTrue(annotation.hasPrefix("::error"))
        XCTAssertTrue(annotation.contains("file="))
        XCTAssertTrue(annotation.contains("line="))
        XCTAssertTrue(annotation.contains("::"))
    }
}

// MARK: - Test Helpers

extension CIOutputModeTests {
    /// Creates a mock CoverageReport with a single target
    /// - Parameters:
    ///   - coveredLines: Number of covered lines
    ///   - executableLines: Number of executable lines
    /// - Returns: A CoverageReport with the specified coverage
    static func makeCoverageReport(coveredLines: Int, executableLines: Int) -> CoverageReport {
        let target = makeTarget(
            name: "TestTarget",
            executableLines: executableLines,
            coveredLines: coveredLines
        )
        return CoverageReport(targets: [target])
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
}
