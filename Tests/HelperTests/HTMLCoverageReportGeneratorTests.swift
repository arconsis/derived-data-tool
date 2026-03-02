//
//  HTMLCoverageReportGeneratorTests.swift
//
//
//  Created by auto-claude on 02.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class HTMLCoverageReportGeneratorTests: XCTestCase {
    // MARK: - Static Generation Method Tests

    func testStaticGenerateHTMLMethod() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 75, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertFalse(html.isEmpty, "Generated HTML should not be empty")
        XCTAssertTrue(html.contains("<!DOCTYPE html>"), "HTML should contain DOCTYPE declaration")
        XCTAssertTrue(html.contains("<html>"), "HTML should contain html tag")
        XCTAssertTrue(html.contains("</html>"), "HTML should contain closing html tag")
    }

    func testGenerateBasicHTML() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("Code Coverage Report"), "HTML should contain report title")
        XCTAssertTrue(html.contains("Overall Coverage"), "HTML should contain overall coverage section")
        XCTAssertTrue(html.contains("Targets"), "HTML should contain targets section")
    }

    func testHTMLContainsMetadata() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 75, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("utf-8"), "HTML should contain UTF-8 charset")
        XCTAssertTrue(html.contains("viewport"), "HTML should contain viewport meta tag")
        XCTAssertTrue(html.contains("Coverage Report"), "HTML should contain coverage report title")
    }

    // MARK: - Coverage Display Tests

    func testHTMLContainsCoveragePercentage() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 75, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("75.00%"), "HTML should display 75.00% coverage")
    }

    func testHTMLContainsZeroCoverage() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 0, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("0.00%"), "HTML should display 0.00% coverage")
    }

    func testHTMLContainsFullCoverage() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 100, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("100.00%"), "HTML should display 100.00% coverage")
    }

    func testHTMLContainsHighPrecisionCoverage() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 876, executableLines: 1000)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("87.60%"), "HTML should display 87.60% coverage with two decimal places")
    }

    // MARK: - Coverage Metrics Tests

    func testHTMLContainsCoveredLines() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("80"), "HTML should display covered lines count")
        XCTAssertTrue(html.contains("Covered Lines"), "HTML should label covered lines")
    }

    func testHTMLContainsExecutableLines() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("100"), "HTML should display executable lines count")
        XCTAssertTrue(html.contains("Executable Lines"), "HTML should label executable lines")
    }

    func testHTMLContainsTargetCount() throws {
        let report = Self.makeCoverageMetaReportWithMultipleTargets(
            targetCount: 3,
            coveredLines: 80,
            executableLines: 100
        )
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("3"), "HTML should display target count")
    }

    // MARK: - Target Display Tests

    func testHTMLContainsTargetNames() throws {
        let report = Self.makeCoverageMetaReportWithNamedTargets([
            ("AppTarget", 80, 100),
            ("TestTarget", 90, 100),
            ("FrameworkTarget", 70, 100)
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("AppTarget"), "HTML should contain AppTarget name")
        XCTAssertTrue(html.contains("TestTarget"), "HTML should contain TestTarget name")
        XCTAssertTrue(html.contains("FrameworkTarget"), "HTML should contain FrameworkTarget name")
    }

    func testHTMLContainsTargetCoverage() throws {
        let report = Self.makeCoverageMetaReportWithNamedTargets([
            ("Target1", 90, 100)
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("90.00%"), "HTML should contain target coverage percentage")
    }

    func testHTMLContainsExpandableTargetRows() throws {
        let report = Self.makeCoverageMetaReportWithNamedTargets([
            ("Target1", 80, 100)
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("expandable"), "HTML should contain expandable class for target rows")
        XCTAssertTrue(html.contains("▶"), "HTML should contain expand icon")
    }

    // MARK: - Coverage Color Classes Tests

    func testHighCoverageColorClass() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 85, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("high_coverage"), "HTML should apply high_coverage class for >= 80% coverage")
    }

    func testNormalCoverageColorClass() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 50, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("normal_coverage"), "HTML should apply normal_coverage class for 30-79% coverage")
    }

    func testLowerCoverageColorClass() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 20, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("lower_coverage"), "HTML should apply lower_coverage class for 15-29% coverage")
    }

    func testLowCoverageColorClass() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 10, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("low_coverage"), "HTML should apply low_coverage class for < 15% coverage")
    }

    // MARK: - JavaScript Tests

    func testHTMLContainsJavaScript() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("<script>"), "HTML should contain script tag")
        XCTAssertTrue(html.contains("sortTable"), "HTML should contain sortTable function")
        XCTAssertTrue(html.contains("toggleExpandable"), "HTML should contain toggleExpandable function")
        XCTAssertTrue(html.contains("DOMContentLoaded"), "HTML should contain DOMContentLoaded event listener")
    }

    func testHTMLContainsSortingFunctionality() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("sortable"), "HTML should contain sortable class")
        XCTAssertTrue(html.contains("sorted-asc"), "HTML should reference sorted-asc class")
        XCTAssertTrue(html.contains("sorted-desc"), "HTML should reference sorted-desc class")
    }

    // MARK: - Table Structure Tests

    func testHTMLContainsTargetsTable() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("<table"), "HTML should contain table tag")
        XCTAssertTrue(html.contains("coverage-table"), "HTML should contain coverage-table class")
        XCTAssertTrue(html.contains("targets-table"), "HTML should contain targets-table id")
    }

    func testHTMLContainsTableHeaders() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("Target"), "HTML should contain Target header")
        XCTAssertTrue(html.contains("Coverage"), "HTML should contain Coverage header")
        XCTAssertTrue(html.contains("Covered"), "HTML should contain Covered header")
        XCTAssertTrue(html.contains("Executable"), "HTML should contain Executable header")
        XCTAssertTrue(html.contains("Visual"), "HTML should contain Visual header")
    }

    func testHTMLContainsDataAttributes() throws {
        let report = Self.makeCoverageMetaReportWithNamedTargets([
            ("Target1", 80, 100)
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("data-target-id"), "HTML should contain data-target-id attributes")
        XCTAssertTrue(html.contains("data-value"), "HTML should contain data-value attributes for sorting")
    }

    // MARK: - File Display Tests

    func testHTMLContainsFileInformation() throws {
        let report = Self.makeCoverageMetaReportWithFiles([
            ("Target1", [("File1.swift", 80, 100), ("File2.swift", 90, 100)])
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("File1.swift"), "HTML should contain file name")
        XCTAssertTrue(html.contains("File2.swift"), "HTML should contain file name")
    }

    func testHTMLContainsFileTableHeaders() throws {
        let report = Self.makeCoverageMetaReportWithFiles([
            ("Target1", [("File1.swift", 80, 100)])
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("Files in"), "HTML should contain 'Files in' header")
    }

    func testHTMLContainsEmptyFilesMessage() throws {
        let report = Self.makeCoverageMetaReportWithEmptyTarget()
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("No files found"), "HTML should contain message for empty target")
    }

    // MARK: - Function Display Tests

    func testHTMLContainsFunctionInformation() throws {
        let report = Self.makeCoverageMetaReportWithFunctions()
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("Functions in"), "HTML should contain 'Functions in' header")
        XCTAssertTrue(html.contains("Function"), "HTML should contain Function header")
        XCTAssertTrue(html.contains("Line"), "HTML should contain Line header")
        XCTAssertTrue(html.contains("Execution Count"), "HTML should contain Execution Count header")
    }

    func testHTMLContainsFunctionDetails() throws {
        let report = Self.makeCoverageMetaReportWithFunctions()
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("testFunction"), "HTML should contain function name")
    }

    func testHTMLContainsEmptyFunctionsMessage() throws {
        let report = Self.makeCoverageMetaReportWithEmptyFile()
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("No function coverage data available"), "HTML should contain message for empty functions")
    }

    // MARK: - CSS Styles Tests

    func testHTMLContainsStyles() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("<style>"), "HTML should contain style tag")
        XCTAssertTrue(html.contains("</style>"), "HTML should contain closing style tag")
    }

    // MARK: - Edge Cases Tests

    func testEmptyReport() throws {
        let coverage = CoverageReport(targets: [])
        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try XCResultFile(with: url)
        let report = CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)

        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("0.00%"), "HTML should handle empty report with 0% coverage")
        XCTAssertTrue(html.contains("Code Coverage Report"), "HTML should still contain basic structure")
    }

    func testSingleTargetReport() throws {
        let report = Self.makeCoverageMetaReportWithMultipleTargets(
            targetCount: 1,
            coveredLines: 80,
            executableLines: 100
        )
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertFalse(html.isEmpty, "HTML should be generated for single target")
        XCTAssertTrue(html.contains("80.00%"), "HTML should contain correct coverage")
    }

    func testManyTargetsReport() throws {
        let report = Self.makeCoverageMetaReportWithMultipleTargets(
            targetCount: 10,
            coveredLines: 80,
            executableLines: 100
        )
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertFalse(html.isEmpty, "HTML should be generated for many targets")
        XCTAssertTrue(html.contains("10"), "HTML should contain correct target count")
    }

    func testVeryLowCoverage() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 1, executableLines: 1000)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("0.10%"), "HTML should display very low coverage correctly")
        XCTAssertTrue(html.contains("low_coverage"), "HTML should apply low_coverage class")
    }

    func testIDSanitization() throws {
        let report = Self.makeCoverageMetaReportWithNamedTargets([
            ("Target With Spaces", 80, 100),
            ("Target.With.Dots", 80, 100),
            ("Target/With/Slashes", 80, 100)
        ])
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("target-with-spaces"), "HTML should sanitize spaces to hyphens in IDs")
        XCTAssertTrue(html.contains("target-with-dots"), "HTML should sanitize dots to hyphens in IDs")
        XCTAssertTrue(html.contains("target-with-slashes"), "HTML should sanitize slashes to hyphens in IDs")
    }

    // MARK: - Format Validation Tests

    func testHTMLIsWellFormed() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        let htmlTagCount = html.components(separatedBy: "<html>").count - 1
        let htmlClosingTagCount = html.components(separatedBy: "</html>").count - 1

        XCTAssertEqual(htmlTagCount, 1, "HTML should have exactly one opening html tag")
        XCTAssertEqual(htmlClosingTagCount, 1, "HTML should have exactly one closing html tag")
    }

    func testHTMLContainsHeadAndBody() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("<head>"), "HTML should contain head tag")
        XCTAssertTrue(html.contains("</head>"), "HTML should contain closing head tag")
        XCTAssertTrue(html.contains("<body>"), "HTML should contain body tag")
        XCTAssertTrue(html.contains("</body>"), "HTML should contain closing body tag")
    }

    func testHTMLContainerClass() throws {
        let report = Self.makeCoverageMetaReport(appName: "TestApp", coveredLines: 80, executableLines: 100)
        let html = HTMLCoverageReportGenerator.generateHTML(from: report)

        XCTAssertTrue(html.contains("container"), "HTML should contain container class")
    }
}

// MARK: - Test Helpers

extension HTMLCoverageReportGeneratorTests {
    static func makeCoverageMetaReport(
        appName: String,
        coveredLines: Int,
        executableLines: Int,
        timestamp: Date = Date()
    ) -> CoverageMetaReport {
        let function = Function(
            name: "testFunction",
            executableLines: executableLines,
            coveredLines: coveredLines,
            lineNumber: 1,
            executionCount: coveredLines > 0 ? 1 : 0
        )

        let file = File(
            name: "TestFile.swift",
            path: "/path/to/TestFile.swift",
            functions: [function]
        )

        let target = Target(name: "TestTarget", files: [file])
        let coverage = CoverageReport(targets: [target])

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: timestamp)
        let filename = "Run-\(appName)-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithMultipleTargets(
        targetCount: Int,
        coveredLines: Int,
        executableLines: Int
    ) -> CoverageMetaReport {
        let targets = (0..<targetCount).map { index -> Target in
            let function = Function(
                name: "testFunction\(index)",
                executableLines: executableLines,
                coveredLines: coveredLines,
                lineNumber: 1,
                executionCount: coveredLines > 0 ? 1 : 0
            )

            let file = File(
                name: "TestFile\(index).swift",
                path: "/path/to/TestFile\(index).swift",
                functions: [function]
            )

            return Target(name: "TestTarget\(index)", files: [file])
        }

        let coverage = CoverageReport(targets: targets)

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithNamedTargets(
        _ targets: [(name: String, coveredLines: Int, executableLines: Int)]
    ) -> CoverageMetaReport {
        let coverageTargets = targets.map { targetInfo -> Target in
            let function = Function(
                name: "testFunction",
                executableLines: targetInfo.executableLines,
                coveredLines: targetInfo.coveredLines,
                lineNumber: 1,
                executionCount: targetInfo.coveredLines > 0 ? 1 : 0
            )

            let file = File(
                name: "\(targetInfo.name)File.swift",
                path: "/path/to/\(targetInfo.name)File.swift",
                functions: [function]
            )

            return Target(name: targetInfo.name, files: [file])
        }

        let coverage = CoverageReport(targets: coverageTargets)

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithFiles(
        _ targetsWithFiles: [(targetName: String, files: [(fileName: String, coveredLines: Int, executableLines: Int)])]
    ) -> CoverageMetaReport {
        let targets = targetsWithFiles.map { targetInfo -> Target in
            let files = targetInfo.files.map { fileInfo -> File in
                let function = Function(
                    name: "testFunction",
                    executableLines: fileInfo.executableLines,
                    coveredLines: fileInfo.coveredLines,
                    lineNumber: 1,
                    executionCount: fileInfo.coveredLines > 0 ? 1 : 0
                )

                return File(
                    name: fileInfo.fileName,
                    path: "/path/to/\(fileInfo.fileName)",
                    functions: [function]
                )
            }

            return Target(name: targetInfo.targetName, files: files)
        }

        let coverage = CoverageReport(targets: targets)

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithEmptyTarget() -> CoverageMetaReport {
        let target = Target(name: "EmptyTarget", files: [])
        let coverage = CoverageReport(targets: [target])

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithFunctions() -> CoverageMetaReport {
        let functions = [
            Function(
                name: "testFunction",
                executableLines: 10,
                coveredLines: 8,
                lineNumber: 1,
                executionCount: 5
            ),
            Function(
                name: "anotherFunction",
                executableLines: 5,
                coveredLines: 5,
                lineNumber: 15,
                executionCount: 3
            )
        ]

        let file = File(
            name: "TestFile.swift",
            path: "/path/to/TestFile.swift",
            functions: functions
        )

        let target = Target(name: "TestTarget", files: [file])
        let coverage = CoverageReport(targets: [target])

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    static func makeCoverageMetaReportWithEmptyFile() -> CoverageMetaReport {
        let file = File(
            name: "EmptyFile.swift",
            path: "/path/to/EmptyFile.swift",
            functions: []
        )

        let target = Target(name: "TestTarget", files: [file])
        let coverage = CoverageReport(targets: [target])

        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let filename = "Run-TestApp-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")
        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }
}
