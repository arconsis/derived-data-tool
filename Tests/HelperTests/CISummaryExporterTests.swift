//
//  CISummaryExporterTests.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class CISummaryExporterTests: XCTestCase {
    var exporter: CISummaryExporter!
    var fileHandler: FileHandler!
    var outputUrl: URL!

    override func setUp() {
        super.setUp()
        fileHandler = FileHandler()
        outputUrl = FileManager.default.temporaryDirectory.appending(pathComponent: "test-ci-summary-\(UUID().uuidString).json")
        exporter = CISummaryExporter(fileHandler: fileHandler, outputUrl: outputUrl)
    }

    override func tearDown() {
        // Clean up temp file
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try? fileHandler.deleteFile(at: outputUrl)
        }
        exporter = nil
        fileHandler = nil
        outputUrl = nil
        super.tearDown()
    }

    // MARK: - Basic Export Tests

    func testExportBasicCoverageReport() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 3)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 75.0, accuracy: 0.01)
        XCTAssertEqual(summary.thresholdStatus, "n/a")
        XCTAssertEqual(summary.targets.count, 3)
        XCTAssertEqual(summary.failures.count, 0)
    }

    func testExportWithZeroCoverage() async throws {
        let report = Self.makeCoverageReport(coverage: 0.0, targetCount: 2)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 0.0, accuracy: 0.01)
        XCTAssertEqual(summary.targets.count, 2)
        XCTAssertTrue(summary.targets.allSatisfy { $0.coverage == 0.0 })
    }

    func testExportWithFullCoverage() async throws {
        let report = Self.makeCoverageReport(coverage: 1.0, targetCount: 5)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 100.0, accuracy: 0.01)
        XCTAssertEqual(summary.targets.count, 5)
        XCTAssertTrue(summary.targets.allSatisfy { $0.coverage == 100.0 })
    }

    func testExportEmptyReport() async throws {
        let report = CoverageReport(targets: [])

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 0.0, accuracy: 0.01)
        XCTAssertEqual(summary.targets.count, 0)
        XCTAssertEqual(summary.failures.count, 0)
    }

    // MARK: - Validation Results Tests

    func testExportWithAllValidationsPassing() async throws {
        let report = Self.makeCoverageReport(coverage: 0.85, targetCount: 3)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.90, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.85, requiredThreshold: 0.75, passed: true),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.80, requiredThreshold: 0.70, passed: true)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.thresholdStatus, "pass")
        XCTAssertEqual(summary.failures.count, 0)
        XCTAssertTrue(summary.targets.allSatisfy { $0.passed == true })
    }

    func testExportWithSomeValidationsFailing() async throws {
        let report = Self.makeCoverageReport(coverage: 0.70, targetCount: 4)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.90, requiredThreshold: 0.80, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.65, requiredThreshold: 0.75, passed: false),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.80, requiredThreshold: 0.70, passed: true),
            ThresholdValidationResult(targetName: "Target4", actualCoverage: 0.55, requiredThreshold: 0.60, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.thresholdStatus, "fail")
        XCTAssertEqual(summary.failures.count, 2)

        let failedTargets = summary.failures.map { $0.targetName }
        XCTAssertTrue(failedTargets.contains("Target2"))
        XCTAssertTrue(failedTargets.contains("Target4"))

        let target2Failure = try XCTUnwrap(summary.failures.first { $0.targetName == "Target2" })
        XCTAssertEqual(target2Failure.actualCoverage, 65.0, accuracy: 0.01)
        XCTAssertEqual(target2Failure.requiredThreshold, 75.0, accuracy: 0.01)
    }

    func testExportWithAllValidationsFailing() async throws {
        let report = Self.makeCoverageReport(coverage: 0.45, targetCount: 2)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.40, requiredThreshold: 0.80, passed: false),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.50, requiredThreshold: 0.75, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.thresholdStatus, "fail")
        XCTAssertEqual(summary.failures.count, 2)
        XCTAssertTrue(summary.targets.allSatisfy { $0.passed == false })
    }

    func testExportWithEmptyValidationResults() async throws {
        let report = Self.makeCoverageReport(coverage: 0.80, targetCount: 3)
        let validationResults: [ThresholdValidationResult] = []

        await exporter.export(report: report, validationResults: validationResults)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.thresholdStatus, "pass")
        XCTAssertEqual(summary.failures.count, 0)
        XCTAssertTrue(summary.targets.allSatisfy { $0.passed == nil })
    }

    // MARK: - CoverageMetaReport Tests

    func testExportMetaReportWithoutValidation() async throws {
        let report = Self.makeCoverageReport(coverage: 0.82, targetCount: 4)
        let meta = Self.makeCoverageMetaReport(report: report)

        await exporter.export(meta: meta)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 82.0, accuracy: 0.01)
        XCTAssertEqual(summary.thresholdStatus, "n/a")
        XCTAssertEqual(summary.targets.count, 4)
    }

    func testExportMetaReportWithValidation() async throws {
        let report = Self.makeCoverageReport(coverage: 0.92, targetCount: 2)
        let meta = Self.makeCoverageMetaReport(report: report)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.95, requiredThreshold: 0.90, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.89, requiredThreshold: 0.85, passed: true)
        ]

        await exporter.export(meta: meta, validationResults: validationResults)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 92.0, accuracy: 0.01)
        XCTAssertEqual(summary.thresholdStatus, "pass")
    }

    // MARK: - JSON Format Tests

    func testJSONIsWellFormatted() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 2)

        await exporter.export(report: report)

        let json = try readExportedJSON()

        // Verify it's valid JSON
        XCTAssertNoThrow(try decodeSummary(from: json))

        // Verify it's pretty printed (contains newlines and indentation)
        XCTAssertTrue(json.contains("\n"))
        XCTAssertTrue(json.contains("  "))
    }

    func testJSONContainsExpectedKeys() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 2)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.70, requiredThreshold: 0.80, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let json = try readExportedJSON()

        XCTAssertTrue(json.contains("\"overallCoverage\""))
        XCTAssertTrue(json.contains("\"thresholdStatus\""))
        XCTAssertTrue(json.contains("\"targets\""))
        XCTAssertTrue(json.contains("\"failures\""))
    }

    func testTargetSummaryFormat() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 1)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        let target = try XCTUnwrap(summary.targets.first)
        XCTAssertEqual(target.name, "Target1")
        XCTAssertEqual(target.coverage, 75.0, accuracy: 0.01)
        XCTAssertEqual(target.coveredLines, 750)
        XCTAssertEqual(target.executableLines, 1000)
        XCTAssertNil(target.passed)
    }

    func testFailureSummaryFormat() async throws {
        let report = Self.makeCoverageReport(coverage: 0.60, targetCount: 1)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.60, requiredThreshold: 0.80, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let summary = try readExportedSummary()

        let failure = try XCTUnwrap(summary.failures.first)
        XCTAssertEqual(failure.targetName, "Target1")
        XCTAssertEqual(failure.actualCoverage, 60.0, accuracy: 0.01)
        XCTAssertEqual(failure.requiredThreshold, 80.0, accuracy: 0.01)
    }

    // MARK: - Edge Cases

    func testExportWithVeryLowCoverage() async throws {
        let report = Self.makeCoverageReport(coverage: 0.01, targetCount: 1)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 1.0, accuracy: 0.01)
    }

    func testExportWithHighPrecisionCoverage() async throws {
        let report = Self.makeCoverageReport(coverage: 0.876543, targetCount: 1)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.overallCoverage, 87.60, accuracy: 0.1)
    }

    func testExportWithSingleTarget() async throws {
        let report = Self.makeCoverageReport(coverage: 0.50, targetCount: 1)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.targets.count, 1)
    }

    func testExportWithManyTargets() async throws {
        let report = Self.makeCoverageReport(coverage: 0.88, targetCount: 25)

        await exporter.export(report: report)

        let summary = try readExportedSummary()

        XCTAssertEqual(summary.targets.count, 25)
    }

    func testExportOverwritesFile() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 1)

        // Export twice to verify overwrite works
        await exporter.export(report: report)
        await exporter.export(report: report)

        let summary = try readExportedSummary()
        XCTAssertEqual(summary.overallCoverage, 75.0, accuracy: 0.01)
    }
}

// MARK: - Test Helpers

extension CISummaryExporterTests {
    /// Reads the exported JSON file and returns the CISummary
    private func readExportedSummary() throws -> CISummary {
        let json = try readExportedJSON()
        return try decodeSummary(from: json)
    }

    /// Reads the exported JSON file as a string
    private func readExportedJSON() throws -> String {
        let data = try Data(contentsOf: outputUrl)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    /// Decodes a CISummary from JSON string
    private func decodeSummary(from json: String) throws -> CISummary {
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder().decode(CISummary.self, from: data)
    }

    /// Creates a mock CoverageReport with specified coverage percentage and target count
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
    static func makeCoverageMetaReport(report: CoverageReport) -> CoverageMetaReport {
        let url = URL(fileURLWithPath: "/tmp/Run-TestApp-2023.05.08_15-14-43-+0200.xcresult")
        guard let fileInfo = try? XCResultFile(with: url) else {
            fatalError("Failed to create XCResultFile")
        }

        return CoverageMetaReport(fileInfo: fileInfo, coverage: report)
    }
}

