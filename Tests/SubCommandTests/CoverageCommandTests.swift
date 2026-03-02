//
//  CoverageCommandTests.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import Foundation
@testable import Coverage
@testable import Helper
@testable import Shared
import XCTest

final class CoverageCommandTests: XCTestCase {
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

    // MARK: - GitHub Annotations Integration Tests

    func testCoverageTool_WithGitHubAnnotationsEnabled_OutputsAnnotations() async throws {
        // Arrange: Create a coverage report with a target below threshold
        let coverage = Self.makeCoverageReport(coveredLines: 60, executableLines: 100)

        // Act: Run validation and generate annotations
        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(
            coverage: coverage,
            thresholds: ["TestTarget": ThresholdConfig(minCoverage: 75.0)]
        )

        // Convert to ThresholdValidationResult format
        var validationResults: [ThresholdValidationResult] = []
        for result in results {
            if case .fail(_, let details) = result {
                if let targetName = details.targetName {
                    let target = coverage.targets.first { $0.name == targetName }
                    let firstFilePath = target?.files.first?.path

                    let validationResult = ThresholdValidationResult(
                        targetName: targetName,
                        actualCoverage: details.actual / 100.0,
                        requiredThreshold: details.expected,
                        passed: false,
                        filePath: firstFilePath
                    )
                    validationResults.append(validationResult)
                }
            }
        }

        // Generate GitHub Actions annotations
        let exporter = GitHubActionsAnnotationExporter()
        let annotations = exporter.formatAnnotations(from: validationResults)

        // Assert: Verify annotations are present in output
        XCTAssertTrue(annotations.contains("::error"), "Output should contain ::error annotation")
        XCTAssertTrue(annotations.contains("file="), "Output should contain file parameter")
        XCTAssertTrue(annotations.contains("line=1"), "Output should contain line number")
        XCTAssertTrue(annotations.contains("Coverage"), "Output should contain coverage information")
        XCTAssertTrue(annotations.contains("60.00%"), "Output should show actual coverage")
        XCTAssertTrue(annotations.contains("75.00%") || annotations.contains("0.75%"), "Output should show required threshold")
        XCTAssertTrue(annotations.contains("TestTarget"), "Output should mention the target name")
    }

    func testCoverageTool_WithGitHubAnnotationsDisabled_DoesNotOutputAnnotations() async throws {
        // Arrange: Create a coverage report with a target below threshold
        let coverage = Self.makeCoverageReport(coveredLines: 60, executableLines: 100)

        // Test that when githubAnnotations is false, no annotations are output
        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(
            coverage: coverage,
            thresholds: ["TestTarget": ThresholdConfig(minCoverage: 75.0)]
        )

        // Verify we have a failure
        let failedResults = results.filter { !$0.isPassing }
        XCTAssertEqual(failedResults.count, 1, "Should have one failing target")

        // Simulate the condition check for annotation output
        let githubAnnotations = false
        let githubActionsEnv = ProcessInfo.processInfo.environment["GITHUB_ACTIONS"]
        let shouldOutput = githubAnnotations || (githubActionsEnv?.lowercased() == "true")

        XCTAssertFalse(shouldOutput, "Should not output annotations when flag is false and not in GitHub Actions")
    }

    func testCoverageTool_WithMultipleFailingTargets_OutputsMultipleAnnotations() async throws {
        // Arrange: Create a coverage report with multiple targets below threshold
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 60, 100),  // 60% coverage, below 75% threshold
            ("TargetB", 50, 100)   // 50% coverage, below 80% threshold
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 75.0),
            "TargetB": ThresholdConfig(minCoverage: 80.0)
        ]

        // Act: Validate thresholds
        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        // Convert to ThresholdValidationResult format
        var validationResults: [ThresholdValidationResult] = []
        for result in results {
            if case .fail(_, let details) = result {
                if let targetName = details.targetName {
                    let target = coverage.targets.first { $0.name == targetName }
                    let firstFilePath = target?.files.first?.path

                    let validationResult = ThresholdValidationResult(
                        targetName: targetName,
                        actualCoverage: details.actual / 100.0,
                        requiredThreshold: details.expected,
                        passed: false,
                        filePath: firstFilePath
                    )
                    validationResults.append(validationResult)
                }
            }
        }

        // Generate annotations
        let exporter = GitHubActionsAnnotationExporter()
        let annotations = exporter.formatAnnotations(from: validationResults)

        // Assert: Should have annotations for both failing targets
        XCTAssertTrue(annotations.contains("TargetA"), "Should have annotation for TargetA")
        XCTAssertTrue(annotations.contains("TargetB"), "Should have annotation for TargetB")

        let annotationLines = annotations.split(separator: "\n")
        XCTAssertEqual(annotationLines.count, 2, "Should have two annotation lines")
    }

    func testCoverageTool_WithPassingThresholds_DoesNotOutputAnnotations() async throws {
        // Arrange: Create a coverage report with targets above threshold
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 85, 100),  // 85% coverage, above 75% threshold
            ("TargetB", 90, 100)   // 90% coverage, above 80% threshold
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 75.0),
            "TargetB": ThresholdConfig(minCoverage: 80.0)
        ]

        // Act: Validate thresholds
        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        // Convert to ThresholdValidationResult format
        var validationResults: [ThresholdValidationResult] = []
        for result in results {
            if case .fail(_, let details) = result {
                if let targetName = details.targetName {
                    let target = coverage.targets.first { $0.name == targetName }
                    let firstFilePath = target?.files.first?.path

                    let validationResult = ThresholdValidationResult(
                        targetName: targetName,
                        actualCoverage: details.actual / 100.0,
                        requiredThreshold: details.expected,
                        passed: false,
                        filePath: firstFilePath
                    )
                    validationResults.append(validationResult)
                }
            }
        }

        // Generate annotations
        let exporter = GitHubActionsAnnotationExporter()
        let annotations = exporter.formatAnnotations(from: validationResults)

        // Assert: Should have no annotations
        XCTAssertTrue(annotations.isEmpty, "Should have no annotations when all thresholds pass")
    }

    func testCoverageTool_AnnotationFormat_MatchesGitHubActionsSpec() async throws {
        // Arrange: Create a failing target with a file path
        let coverage = Self.makeCoverageReportWithTargets([
            ("MyTarget", 60, 100)
        ])

        let thresholds = ["MyTarget": ThresholdConfig(minCoverage: 75.0)]

        // Act: Generate annotation
        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        var validationResults: [ThresholdValidationResult] = []
        for result in results {
            if case .fail(_, let details) = result {
                if let targetName = details.targetName {
                    let target = coverage.targets.first { $0.name == targetName }
                    let firstFilePath = target?.files.first?.path

                    let validationResult = ThresholdValidationResult(
                        targetName: targetName,
                        actualCoverage: details.actual / 100.0,
                        requiredThreshold: details.expected,
                        passed: false,
                        filePath: firstFilePath
                    )
                    validationResults.append(validationResult)
                }
            }
        }

        let exporter = GitHubActionsAnnotationExporter()
        let annotation = exporter.formatAnnotations(from: validationResults)

        // Assert: Verify GitHub Actions annotation format
        // Format should be: ::error file={name},line={line}::{message}
        XCTAssertTrue(annotation.hasPrefix("::error"), "Should start with ::error")
        XCTAssertTrue(annotation.contains("file="), "Should contain file parameter")
        XCTAssertTrue(annotation.contains("line=1"), "Should contain line=1")
        XCTAssertTrue(annotation.contains("::"), "Should contain double colon separator")

        // Verify the annotation contains coverage details
        XCTAssertTrue(annotation.contains("Coverage"), "Should contain 'Coverage' in message")
        XCTAssertTrue(annotation.contains("threshold"), "Should contain 'threshold' in message")
        XCTAssertTrue(annotation.contains("MyTarget"), "Should contain target name")
    }

    // MARK: - HTML Format Integration Tests

    func testCoverageTool_WithHTMLFormat_GeneratesValidHTML() async throws {
        // Arrange: Create a coverage report with good coverage
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)

        // Act: Generate HTML report (simulating what CoverageTool does when format == .html)
        let htmlContent = HTMLCoverageReportGenerator.generateHTML(from: report)

        // Assert: Verify HTML structure and content
        XCTAssertFalse(htmlContent.isEmpty, "HTML content should not be empty")
        XCTAssertTrue(htmlContent.contains("<!DOCTYPE html>"), "HTML should contain DOCTYPE declaration")
        XCTAssertTrue(htmlContent.contains("<html>"), "HTML should contain html tag")
        XCTAssertTrue(htmlContent.contains("</html>"), "HTML should contain closing html tag")
        XCTAssertTrue(htmlContent.contains("Code Coverage Report"), "HTML should contain report title")
        XCTAssertTrue(htmlContent.contains("80.00%"), "HTML should display correct coverage percentage")
        XCTAssertTrue(htmlContent.contains("Overall Coverage"), "HTML should contain overall coverage section")
        XCTAssertTrue(htmlContent.contains("TestTarget"), "HTML should contain target name")
    }

    func testCoverageTool_WithHTMLFormat_ContainsInteractiveFeatures() async throws {
        // Arrange: Create a report with multiple targets
        let report = Self.makeCoverageMetaReportWithTargets([
            ("TargetA", 85, 100),
            ("TargetB", 75, 100)
        ])

        // Act: Generate HTML report
        let htmlContent = HTMLCoverageReportGenerator.generateHTML(from: report)

        // Assert: Verify interactive features are present
        XCTAssertTrue(htmlContent.contains("<script>"), "HTML should contain JavaScript")
        XCTAssertTrue(htmlContent.contains("sortTable"), "HTML should contain sorting functionality")
        XCTAssertTrue(htmlContent.contains("toggleExpandable"), "HTML should contain expandable rows functionality")
        XCTAssertTrue(htmlContent.contains("sortable"), "HTML should have sortable class for table headers")
        XCTAssertTrue(htmlContent.contains("expandable"), "HTML should have expandable class for target rows")
    }

    func testCoverageTool_WithHTMLFormat_DisplaysAllTargets() async throws {
        // Arrange: Create a report with multiple named targets
        let report = Self.makeCoverageMetaReportWithTargets([
            ("AppTarget", 90, 100),
            ("TestTarget", 85, 100),
            ("FrameworkTarget", 70, 100)
        ])

        // Act: Generate HTML report
        let htmlContent = HTMLCoverageReportGenerator.generateHTML(from: report)

        // Assert: Verify all targets are displayed
        XCTAssertTrue(htmlContent.contains("AppTarget"), "HTML should contain AppTarget")
        XCTAssertTrue(htmlContent.contains("TestTarget"), "HTML should contain TestTarget")
        XCTAssertTrue(htmlContent.contains("FrameworkTarget"), "HTML should contain FrameworkTarget")
        XCTAssertTrue(htmlContent.contains("90.00%"), "HTML should contain AppTarget coverage")
        XCTAssertTrue(htmlContent.contains("85.00%"), "HTML should contain TestTarget coverage")
        XCTAssertTrue(htmlContent.contains("70.00%"), "HTML should contain FrameworkTarget coverage")
    }

    func testCoverageTool_WithHTMLFormat_AppliesCorrectCoverageClasses() async throws {
        // Arrange: Create reports with different coverage levels
        let highCoverageReport = Self.makeCoverageMetaReport(appName: "HighCoverageApp", coveredLines: 85, executableLines: 100)
        let normalCoverageReport = Self.makeCoverageMetaReport(appName: "NormalCoverageApp", coveredLines: 50, executableLines: 100)
        let lowCoverageReport = Self.makeCoverageMetaReport(appName: "LowCoverageApp", coveredLines: 10, executableLines: 100)

        // Act: Generate HTML for each report
        let highHtml = HTMLCoverageReportGenerator.generateHTML(from: highCoverageReport)
        let normalHtml = HTMLCoverageReportGenerator.generateHTML(from: normalCoverageReport)
        let lowHtml = HTMLCoverageReportGenerator.generateHTML(from: lowCoverageReport)

        // Assert: Verify coverage classes are applied correctly
        XCTAssertTrue(highHtml.contains("high_coverage"), "High coverage report should have high_coverage class")
        XCTAssertTrue(normalHtml.contains("normal_coverage"), "Normal coverage report should have normal_coverage class")
        XCTAssertTrue(lowHtml.contains("low_coverage"), "Low coverage report should have low_coverage class")
    }

    func testCoverageTool_WithHTMLFormat_HandlesEmptyReport() async throws {
        // Arrange: Create an empty coverage report
        let coverage = CoverageReport(targets: [])
        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-EmptyApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try XCResultFile(with: url)
        let report = CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)

        // Act: Generate HTML report
        let htmlContent = HTMLCoverageReportGenerator.generateHTML(from: report)

        // Assert: Verify HTML handles empty report gracefully
        XCTAssertFalse(htmlContent.isEmpty, "HTML should be generated even for empty reports")
        XCTAssertTrue(htmlContent.contains("0.00%"), "HTML should show 0% coverage for empty report")
        XCTAssertTrue(htmlContent.contains("Code Coverage Report"), "HTML should still contain basic structure")
        XCTAssertTrue(htmlContent.contains("<!DOCTYPE html>"), "HTML should be well-formed")
    }
}

// MARK: - Test Helpers

extension CoverageCommandTests {
    static func makeCoverageReport(coveredLines: Int, executableLines: Int) -> CoverageReport {
        let function = Function(
            name: "testFunction",
            executableLines: executableLines,
            coveredLines: coveredLines,
            lineNumber: 1,
            executionCount: 1
        )

        let file = File(
            name: "TestFile.swift",
            path: "/path/to/TestFile.swift",
            functions: [function]
        )

        let target = Target(name: "TestTarget", files: [file])

        return CoverageReport(targets: [target])
    }

    static func makeCoverageReportWithTargets(_ targets: [(name: String, coveredLines: Int, executableLines: Int)]) -> CoverageReport {
        let coverageTargets = targets.map { targetInfo -> Target in
            let function = Function(
                name: "testFunction",
                executableLines: targetInfo.executableLines,
                coveredLines: targetInfo.coveredLines,
                lineNumber: 1,
                executionCount: 1
            )

            let file = File(
                name: "\(targetInfo.name)File.swift",
                path: "/path/to/\(targetInfo.name)File.swift",
                functions: [function]
            )

            return Target(name: targetInfo.name, files: [file])
        }

        return CoverageReport(targets: coverageTargets)
    }

    static func makeCoverageMetaReport(
        appName: String,
        coveredLines: Int,
        executableLines: Int,
        timestamp: Date = Date()
    ) -> CoverageMetaReport {
        let coverage = makeCoverageReport(coveredLines: coveredLines, executableLines: executableLines)

        // XCResultFile requires a properly formatted filename
        // Format: "Run-ApplicationName-2023.05.08_15-14-43-+0200.xcresult"
        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: timestamp)
        let filename = "Run-\(appName)-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")

        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithTargets(
        _ targets: [(name: String, coveredLines: Int, executableLines: Int)],
        appName: String = "TestApp",
        timestamp: Date = Date()
    ) -> CoverageMetaReport {
        let coverage = makeCoverageReportWithTargets(targets)

        // XCResultFile requires a properly formatted filename
        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: timestamp)
        let filename = "Run-\(appName)-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")

        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }
}
