//
//  PRCommentCommandTests.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class PRCommentCommandTests: XCTestCase {
    // MARK: - PRCommentFormatter Tests

    func testPRCommentFormatter_WithCurrentReportOnly_GeneratesBasicComment() throws {
        // Arrange: Create a current coverage report
        let current = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 80,
            executableLines: 100
        )

        // Act: Format the comment without a previous report
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: current, previous: nil)

        // Assert: Verify basic structure and content
        XCTAssertTrue(comment.contains("<!-- xcrtool-coverage-comment -->"), "Should contain comment marker")
        XCTAssertTrue(comment.contains("## 📊 Coverage Report"), "Should contain coverage report header")
        XCTAssertTrue(comment.contains("**Overall Coverage:**"), "Should contain overall coverage label")
        XCTAssertTrue(comment.contains("80.00%"), "Should show 80% coverage")
        XCTAssertTrue(comment.contains("Executable Lines"), "Should contain executable lines metric")
        XCTAssertTrue(comment.contains("Covered Lines"), "Should contain covered lines metric")
        XCTAssertTrue(comment.contains("100"), "Should show 100 executable lines")
        XCTAssertTrue(comment.contains("80"), "Should show 80 covered lines")

        // Should NOT contain comparison sections without previous report
        XCTAssertFalse(comment.contains("## 📈 Top Changed Files"), "Should not show top changed files without previous report")
        XCTAssertFalse(comment.contains("## ⚠️ New Untested Files"), "Should not show new untested files without previous report")
    }

    func testPRCommentFormatter_WithPreviousReport_ShowsCoverageChange() throws {
        // Arrange: Create current and previous reports with different coverage
        let current = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 85,
            executableLines: 100
        )
        let previous = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 75,
            executableLines: 100
        )

        // Act: Format the comment with comparison
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: current, previous: previous)

        // Assert: Verify coverage change is shown
        XCTAssertTrue(comment.contains("85.00%"), "Should show current coverage of 85%")
        XCTAssertTrue(comment.contains("+10.00%"), "Should show +10% improvement")
        XCTAssertTrue(comment.contains("🎉") || comment.contains("✅"), "Should show positive emoji for improvement")
        XCTAssertTrue(comment.contains("Lines Changed"), "Should show lines changed metric")
        XCTAssertTrue(comment.contains("+10"), "Should show +10 lines covered")
    }

    func testPRCommentFormatter_WithCoverageDecrease_ShowsWarningEmoji() throws {
        // Arrange: Create reports with coverage decrease
        let current = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 70,
            executableLines: 100
        )
        let previous = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 85,
            executableLines: 100
        )

        // Act: Format the comment
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: current, previous: previous)

        // Assert: Verify decrease is shown with appropriate emoji
        XCTAssertTrue(comment.contains("70.00%"), "Should show current coverage of 70%")
        XCTAssertTrue(comment.contains("-15.00%"), "Should show -15% decrease")
        XCTAssertTrue(comment.contains("⚠️") || comment.contains("📉"), "Should show warning emoji for decrease")
    }

    func testPRCommentFormatter_WithChangedFiles_ShowsTopChanges() throws {
        // Arrange: Create reports with file-level changes
        let current = Self.makeCoverageReportWithFiles([
            ("FileA.swift", 90, 100),  // 90% coverage
            ("FileB.swift", 60, 100),  // 60% coverage
            ("FileC.swift", 80, 100)   // 80% coverage
        ])
        let previous = Self.makeCoverageReportWithFiles([
            ("FileA.swift", 50, 100),  // Was 50%, now 90% (+40%)
            ("FileB.swift", 70, 100),  // Was 70%, now 60% (-10%)
            ("FileC.swift", 80, 100)   // No change
        ])

        let currentMeta = Self.wrapInMetaReport(current, appName: "TestApp")
        let previousMeta = Self.wrapInMetaReport(previous, appName: "TestApp")

        // Act: Format with top files limit
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: currentMeta, previous: previousMeta, topFiles: 5)

        // Assert: Verify top changed files section exists
        XCTAssertTrue(comment.contains("## 📈 Top Changed Files"), "Should contain top changed files section")
        XCTAssertTrue(comment.contains("FileA.swift"), "Should show FileA with biggest change")
        XCTAssertTrue(comment.contains("90.00%"), "Should show FileA current coverage")
        XCTAssertTrue(comment.contains("+40.00%"), "Should show FileA improvement")
        XCTAssertTrue(comment.contains("FileB.swift"), "Should show FileB")
        XCTAssertTrue(comment.contains("-10.00%"), "Should show FileB decrease")
        // FileC should not appear as it has no change
        XCTAssertFalse(comment.contains("FileC.swift"), "Should not show FileC as it has no change")
    }

    func testPRCommentFormatter_WithNewUntestedFiles_ShowsWarning() throws {
        // Arrange: Create reports with new untested files
        let current = Self.makeCoverageReportWithFiles([
            ("ExistingFile.swift", 80, 100),
            ("NewUntestedFile.swift", 0, 50)  // New file with 0 coverage
        ])
        let previous = Self.makeCoverageReportWithFiles([
            ("ExistingFile.swift", 80, 100)
        ])

        let currentMeta = Self.wrapInMetaReport(current, appName: "TestApp")
        let previousMeta = Self.wrapInMetaReport(previous, appName: "TestApp")

        // Act: Format with untested files enabled
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: currentMeta, previous: previousMeta, includeUntested: true)

        // Assert: Verify untested files section
        XCTAssertTrue(comment.contains("## ⚠️ New Untested Files"), "Should contain new untested files section")
        XCTAssertTrue(comment.contains("NewUntestedFile.swift"), "Should show new untested file")
        XCTAssertTrue(comment.contains("50"), "Should show 50 executable lines")
        XCTAssertFalse(comment.contains("ExistingFile.swift"), "Should not show existing files")
    }

    func testPRCommentFormatter_WithIncludeUntestedFalse_HidesUntestedSection() throws {
        // Arrange: Create reports with new untested files
        let current = Self.makeCoverageReportWithFiles([
            ("ExistingFile.swift", 80, 100),
            ("NewUntestedFile.swift", 0, 50)
        ])
        let previous = Self.makeCoverageReportWithFiles([
            ("ExistingFile.swift", 80, 100)
        ])

        let currentMeta = Self.wrapInMetaReport(current, appName: "TestApp")
        let previousMeta = Self.wrapInMetaReport(previous, appName: "TestApp")

        // Act: Format with untested files disabled
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: currentMeta, previous: previousMeta, includeUntested: false)

        // Assert: Verify untested section is not present
        XCTAssertFalse(comment.contains("## ⚠️ New Untested Files"), "Should not contain new untested files section when disabled")
        XCTAssertFalse(comment.contains("NewUntestedFile.swift"), "Should not show new untested file when disabled")
    }

    func testPRCommentFormatter_MarkerMethod_ReturnsCorrectMarker() throws {
        // Arrange & Act
        let formatter = PRCommentFormatter()
        let marker = formatter.marker()

        // Assert
        XCTAssertEqual(marker, "<!-- xcrtool-coverage-comment -->", "Should return correct comment marker")
    }

    func testPRCommentFormatter_WithTopFilesLimit_RespectsLimit() throws {
        // Arrange: Create reports with many changed files
        let current = Self.makeCoverageReportWithFiles([
            ("File1.swift", 90, 100),
            ("File2.swift", 85, 100),
            ("File3.swift", 80, 100),
            ("File4.swift", 75, 100),
            ("File5.swift", 70, 100),
            ("File6.swift", 65, 100)
        ])
        let previous = Self.makeCoverageReportWithFiles([
            ("File1.swift", 50, 100),  // +40%
            ("File2.swift", 50, 100),  // +35%
            ("File3.swift", 50, 100),  // +30%
            ("File4.swift", 50, 100),  // +25%
            ("File5.swift", 50, 100),  // +20%
            ("File6.swift", 50, 100)   // +15%
        ])

        let currentMeta = Self.wrapInMetaReport(current, appName: "TestApp")
        let previousMeta = Self.wrapInMetaReport(previous, appName: "TestApp")

        // Act: Format with limit of 3 top files
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: currentMeta, previous: previousMeta, topFiles: 3)

        // Assert: Should only show top 3 files
        XCTAssertTrue(comment.contains("File1.swift"), "Should show File1 (biggest change)")
        XCTAssertTrue(comment.contains("File2.swift"), "Should show File2 (second biggest)")
        XCTAssertTrue(comment.contains("File3.swift"), "Should show File3 (third biggest)")

        // Count the number of file entries in the table (look for .swift references)
        let fileCount = comment.components(separatedBy: ".swift").count - 1
        XCTAssertEqual(fileCount, 3, "Should only show 3 files in top changed files")
    }

    func testPRCommentFormatter_WithNoChangedFiles_HidesTopChangedSection() throws {
        // Arrange: Create identical reports (no changes)
        let current = Self.makeCoverageReportWithFiles([
            ("FileA.swift", 80, 100)
        ])
        let previous = Self.makeCoverageReportWithFiles([
            ("FileA.swift", 80, 100)
        ])

        let currentMeta = Self.wrapInMetaReport(current, appName: "TestApp")
        let previousMeta = Self.wrapInMetaReport(previous, appName: "TestApp")

        // Act
        let formatter = PRCommentFormatter()
        let comment = formatter.format(current: currentMeta, previous: previousMeta)

        // Assert: Should not show top changed files section when there are no changes
        XCTAssertFalse(comment.contains("## 📈 Top Changed Files"), "Should not show top changed files when no files changed")
    }
}

// MARK: - Test Helpers

extension PRCommentCommandTests {
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

    static func makeCoverageReportWithFiles(_ files: [(name: String, coveredLines: Int, executableLines: Int)]) -> CoverageReport {
        let coverageFiles = files.map { fileInfo -> File in
            let function = Function(
                name: "testFunction",
                executableLines: fileInfo.executableLines,
                coveredLines: fileInfo.coveredLines,
                lineNumber: 1,
                executionCount: 1
            )

            return File(
                name: fileInfo.name,
                path: "/path/to/\(fileInfo.name)",
                functions: [function]
            )
        }

        let target = Target(name: "TestTarget", files: coverageFiles)

        return CoverageReport(targets: [target])
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

    static func wrapInMetaReport(_ coverage: CoverageReport, appName: String, timestamp: Date = Date()) -> CoverageMetaReport {
        // XCResultFile requires a properly formatted filename
        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: timestamp)
        let filename = "Run-\(appName)-\(dateString).xcresult"
        let url = URL(fileURLWithPath: "/path/to/\(filename)")

        let fileInfo = try! XCResultFile(with: url)

        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }
}
