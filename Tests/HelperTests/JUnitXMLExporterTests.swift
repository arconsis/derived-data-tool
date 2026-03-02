//
//  JUnitXMLExporterTests.swift
//
//
//  Created by Moritz Ellerbrock on 02.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class JUnitXMLExporterTests: XCTestCase {
    var exporter: JUnitXMLExporter!
    var fileHandler: FileHandler!
    var outputUrl: URL!

    override func setUp() {
        super.setUp()
        fileHandler = FileHandler()
        outputUrl = FileManager.default.temporaryDirectory.appending(pathComponent: "test-junit-\(UUID().uuidString).xml")
        exporter = JUnitXMLExporter(fileHandler: fileHandler, outputUrl: outputUrl)
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

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(xmlContent.contains("<testsuites"))
        XCTAssertTrue(xmlContent.contains("</testsuites>"))
        XCTAssertTrue(xmlContent.contains("tests=\""))
        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
    }

    func testExportWithZeroCoverage() async throws {
        let report = Self.makeCoverageReport(coverage: 0.0, targetCount: 2)

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("<testsuites"))
        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
        XCTAssertTrue(xmlContent.contains("coverage\" value=\"0.00\""))
    }

    func testExportWithFullCoverage() async throws {
        let report = Self.makeCoverageReport(coverage: 1.0, targetCount: 5)

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("<testsuites"))
        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
        XCTAssertTrue(xmlContent.contains("coverage\" value=\"100.00\""))
    }

    func testExportEmptyReport() async throws {
        let report = CoverageReport(targets: [])

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("<testsuites"))
        XCTAssertTrue(xmlContent.contains("tests=\"0\""))
        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
        XCTAssertTrue(xmlContent.contains("</testsuites>"))
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

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
        XCTAssertFalse(xmlContent.contains("<failure"))
        XCTAssertFalse(xmlContent.contains("threshold-validation"))
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

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("failures=\"2\""))
        XCTAssertTrue(xmlContent.contains("<failure"))
        XCTAssertTrue(xmlContent.contains("threshold-validation"))
        XCTAssertTrue(xmlContent.contains("CoverageThresholdFailure"))
    }

    func testExportWithAllValidationsFailing() async throws {
        let report = Self.makeCoverageReport(coverage: 0.45, targetCount: 2)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.40, requiredThreshold: 0.80, passed: false),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.50, requiredThreshold: 0.75, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("failures=\"2\""))

        // Count failure elements
        let failureCount = xmlContent.components(separatedBy: "<failure").count - 1
        XCTAssertEqual(failureCount, 2)
    }

    func testExportWithEmptyValidationResults() async throws {
        let report = Self.makeCoverageReport(coverage: 0.80, targetCount: 3)
        let validationResults: [ThresholdValidationResult] = []

        await exporter.export(report: report, validationResults: validationResults)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
        XCTAssertFalse(xmlContent.contains("<failure"))
    }

    // MARK: - CoverageMetaReport Tests

    func testExportMetaReportWithoutValidation() async throws {
        let report = Self.makeCoverageReport(coverage: 0.82, targetCount: 4)
        let meta = Self.makeCoverageMetaReport(report: report)

        await exporter.export(meta: meta)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("<testsuites"))
        XCTAssertTrue(xmlContent.contains("failures=\"0\""))

        // Count test suites (one per target) - use space to avoid matching <testsuites>
        let testSuiteCount = xmlContent.components(separatedBy: "<testsuite ").count - 1
        XCTAssertEqual(testSuiteCount, 4)
    }

    func testExportMetaReportWithValidation() async throws {
        let report = Self.makeCoverageReport(coverage: 0.92, targetCount: 2)
        let meta = Self.makeCoverageMetaReport(report: report)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.95, requiredThreshold: 0.90, passed: true),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.89, requiredThreshold: 0.85, passed: true)
        ]

        await exporter.export(meta: meta, validationResults: validationResults)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("failures=\"0\""))
        XCTAssertFalse(xmlContent.contains("<failure"))
    }

    // MARK: - XML Format Tests

    func testXMLIsWellFormed() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 2)

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify XML declaration
        XCTAssertTrue(xmlContent.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))

        // Verify root element
        XCTAssertTrue(xmlContent.contains("<testsuites"))
        XCTAssertTrue(xmlContent.hasSuffix("</testsuites>\n"))

        // Verify required attributes on testsuites
        XCTAssertTrue(xmlContent.contains("id=\""))
        XCTAssertTrue(xmlContent.contains("name=\"Coverage Report\""))
        XCTAssertTrue(xmlContent.contains("tests=\""))
        XCTAssertTrue(xmlContent.contains("failures=\""))
        XCTAssertTrue(xmlContent.contains("time=\""))
        XCTAssertTrue(xmlContent.contains("timestamp=\""))
    }

    func testTestSuiteStructure() async throws {
        let report = Self.makeCoverageReport(coverage: 0.80, targetCount: 3)

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify test suite elements
        XCTAssertTrue(xmlContent.contains("<testsuite"))
        XCTAssertTrue(xmlContent.contains("</testsuite>"))

        // Verify test suite attributes
        XCTAssertTrue(xmlContent.contains("id=\"Target"))
        XCTAssertTrue(xmlContent.contains("name=\"Target"))
        XCTAssertTrue(xmlContent.contains("tests=\""))
        XCTAssertTrue(xmlContent.contains("skipped=\"0\""))
        XCTAssertTrue(xmlContent.contains("errors=\"0\""))

        // Verify properties section
        XCTAssertTrue(xmlContent.contains("<properties>"))
        XCTAssertTrue(xmlContent.contains("</properties>"))
        XCTAssertTrue(xmlContent.contains("<property name=\"coverage\""))
        XCTAssertTrue(xmlContent.contains("<property name=\"coveredLines\""))
        XCTAssertTrue(xmlContent.contains("<property name=\"executableLines\""))
    }

    func testTestCaseStructure() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 1)

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify test case elements
        XCTAssertTrue(xmlContent.contains("<testcase"))
        XCTAssertTrue(xmlContent.contains("</testcase>"))

        // Verify test case attributes
        XCTAssertTrue(xmlContent.contains("name=\"File"))
        XCTAssertTrue(xmlContent.contains("classname=\"Target"))
        XCTAssertTrue(xmlContent.contains("time=\"0.0\""))

        // Verify test case properties
        XCTAssertTrue(xmlContent.contains("<property name=\"coverage\""))
    }

    func testXMLEscaping() async throws {
        // Create report with special characters
        let target = Target(
            name: "Target<>&\"'",
            files: [
                File(
                    name: "File<>&\"'.swift",
                    path: "/path/to/file.swift",
                    functions: [
                        Function(name: "test", executableLines: 100, coveredLines: 75, lineNumber: 1, executionCount: 1)
                    ]
                )
            ]
        )
        let report = CoverageReport(targets: [target])

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify characters are escaped
        XCTAssertTrue(xmlContent.contains("&lt;"))
        XCTAssertTrue(xmlContent.contains("&gt;"))
        XCTAssertTrue(xmlContent.contains("&amp;"))
        XCTAssertTrue(xmlContent.contains("&quot;"))
        XCTAssertTrue(xmlContent.contains("&apos;"))

        // Verify raw characters are not present (except in XML declaration)
        let withoutDeclaration = xmlContent.replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", with: "")
        XCTAssertFalse(withoutDeclaration.contains("<>&\"'"))
    }

    // MARK: - Threshold Failure Tests

    func testThresholdFailureMessage() async throws {
        let report = Self.makeCoverageReport(coverage: 0.60, targetCount: 1)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.60, requiredThreshold: 0.80, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let xmlContent = try readExportedXML()

        // Verify failure element structure
        XCTAssertTrue(xmlContent.contains("<testcase name=\"threshold-validation\""))
        XCTAssertTrue(xmlContent.contains("<failure"))
        XCTAssertTrue(xmlContent.contains("type=\"CoverageThresholdFailure\""))

        // Verify failure message content
        XCTAssertTrue(xmlContent.contains("Coverage threshold not met"))
        XCTAssertTrue(xmlContent.contains("60.00%"))
        XCTAssertTrue(xmlContent.contains("80.00%"))
        XCTAssertTrue(xmlContent.contains("Target: Target1"))
        XCTAssertTrue(xmlContent.contains("Actual Coverage: 60.00%"))
        XCTAssertTrue(xmlContent.contains("Required Threshold: 80.00%"))
    }

    func testMultipleThresholdFailures() async throws {
        let report = Self.makeCoverageReport(coverage: 0.50, targetCount: 3)
        let validationResults = [
            ThresholdValidationResult(targetName: "Target1", actualCoverage: 0.45, requiredThreshold: 0.80, passed: false),
            ThresholdValidationResult(targetName: "Target2", actualCoverage: 0.50, requiredThreshold: 0.75, passed: false),
            ThresholdValidationResult(targetName: "Target3", actualCoverage: 0.55, requiredThreshold: 0.60, passed: false)
        ]

        await exporter.export(report: report, validationResults: validationResults)

        let xmlContent = try readExportedXML()

        // Verify all failures are present
        let failureCount = xmlContent.components(separatedBy: "<failure").count - 1
        XCTAssertEqual(failureCount, 3)

        XCTAssertTrue(xmlContent.contains("Target1"))
        XCTAssertTrue(xmlContent.contains("Target2"))
        XCTAssertTrue(xmlContent.contains("Target3"))
    }

    // MARK: - Edge Cases

    func testSingleTargetSingleFile() async throws {
        let target = Target(
            name: "SingleTarget",
            files: [
                File(
                    name: "SingleFile.swift",
                    path: "/path/to/SingleFile.swift",
                    functions: [
                        Function(name: "test", executableLines: 10, coveredLines: 8, lineNumber: 1, executionCount: 1)
                    ]
                )
            ]
        )
        let report = CoverageReport(targets: [target])

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        XCTAssertTrue(xmlContent.contains("tests=\"1\""))
        XCTAssertTrue(xmlContent.contains("SingleTarget"))
        XCTAssertTrue(xmlContent.contains("SingleFile.swift"))
    }

    func testMultipleFilesPerTarget() async throws {
        let functions = [
            Function(name: "func1", executableLines: 10, coveredLines: 8, lineNumber: 1, executionCount: 1),
            Function(name: "func2", executableLines: 20, coveredLines: 15, lineNumber: 10, executionCount: 1)
        ]

        let files = (1...5).map { i in
            File(
                name: "File\(i).swift",
                path: "/path/to/File\(i).swift",
                functions: functions
            )
        }

        let target = Target(name: "MultiFileTarget", files: files)
        let report = CoverageReport(targets: [target])

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify all files are present
        for i in 1...5 {
            XCTAssertTrue(xmlContent.contains("File\(i).swift"))
        }

        // Count test cases (one per file)
        let testCaseCount = xmlContent.components(separatedBy: "<testcase name=\"File").count - 1
        XCTAssertEqual(testCaseCount, 5)
    }

    func testCoverageStatistics() async throws {
        let target = Target(
            name: "StatsTarget",
            files: [
                File(
                    name: "TestFile.swift",
                    path: "/path/to/TestFile.swift",
                    functions: [
                        Function(name: "test", executableLines: 100, coveredLines: 75, lineNumber: 1, executionCount: 1)
                    ]
                )
            ]
        )
        let report = CoverageReport(targets: [target])

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify statistics are included
        XCTAssertTrue(xmlContent.contains("coveredLines\" value=\"75\""))
        XCTAssertTrue(xmlContent.contains("executableLines\" value=\"100\""))
        XCTAssertTrue(xmlContent.contains("coverage\" value=\"75.00\""))
    }

    func testTimestampFormat() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 1)

        await exporter.export(report: report)

        let xmlContent = try readExportedXML()

        // Verify timestamp is present and appears to be in ISO format
        XCTAssertTrue(xmlContent.contains("timestamp=\""))

        // Extract and validate timestamp format (basic check)
        if let timestampRange = xmlContent.range(of: "timestamp=\"[^\"]+\"", options: .regularExpression) {
            let timestamp = String(xmlContent[timestampRange])
            XCTAssertTrue(timestamp.contains("T") || timestamp.contains("-"))
        } else {
            XCTFail("No timestamp found in XML")
        }
    }

    // MARK: - File Writing Tests

    func testFileIsCreated() async throws {
        let report = Self.makeCoverageReport(coverage: 0.75, targetCount: 2)

        XCTAssertFalse(FileManager.default.fileExists(atPath: outputUrl.path))

        await exporter.export(report: report)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputUrl.path))
    }

    func testFileCanBeOverwritten() async throws {
        let report1 = Self.makeCoverageReport(coverage: 0.50, targetCount: 1)
        let report2 = Self.makeCoverageReport(coverage: 0.75, targetCount: 2)

        await exporter.export(report: report1)
        let content1 = try readExportedXML()

        await exporter.export(report: report2)
        let content2 = try readExportedXML()

        XCTAssertNotEqual(content1, content2)
        XCTAssertTrue(content2.contains("tests=\"2\"")) // 2 targets means 2 files
    }

    // MARK: - Helper Methods

    private func readExportedXML() throws -> String {
        let data = try Data(contentsOf: outputUrl)
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not decode XML as UTF-8"])
        }
        return xmlString
    }

    private static func makeCoverageReport(coverage: Double, targetCount: Int) -> CoverageReport {
        let targets = (1...targetCount).map { i in
            makeTarget(name: "Target\(i)", coverage: coverage, fileCount: 1)
        }
        return CoverageReport(targets: targets)
    }

    private static func makeTarget(name: String, coverage: Double, fileCount: Int) -> Target {
        let files = (1...fileCount).map { i in
            makeFile(name: "File\(i).swift", coverage: coverage)
        }
        return Target(name: name, files: files)
    }

    private static func makeFile(name: String, coverage: Double) -> File {
        let executableLines = 100
        let coveredLines = Int(Double(executableLines) * coverage)
        let function = Function(
            name: "testFunction",
            executableLines: executableLines,
            coveredLines: coveredLines,
            lineNumber: 1,
            executionCount: 1
        )
        return File(name: name, path: "/path/to/\(name)", functions: [function])
    }

    private static func makeCoverageMetaReport(report: CoverageReport) -> CoverageMetaReport {
        let url = URL(fileURLWithPath: "/tmp/Run-TestApp-2023.05.08_15-14-43-+0200.xcresult")
        guard let fileInfo = try? XCResultFile(with: url) else {
            fatalError("Failed to create XCResultFile")
        }
        return CoverageMetaReport(fileInfo: fileInfo, coverage: report)
    }
}
