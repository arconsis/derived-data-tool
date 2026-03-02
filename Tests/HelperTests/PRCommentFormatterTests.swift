//
//  PRCommentFormatterTests.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class PRCommentFormatterTests: XCTestCase {
    var formatter: PRCommentFormatter!

    override func setUp() {
        super.setUp()
        formatter = PRCommentFormatter()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    // MARK: - Marker Tests

    func testMarker_ReturnsExpectedValue() throws {
        let marker = formatter.marker()

        XCTAssertEqual(marker, "<!-- xcrtool-coverage-comment -->")
    }

    // MARK: - Basic Formatting Tests

    func testFormat_WithCurrentOnly() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("<!-- xcrtool-coverage-comment -->"))
        XCTAssertTrue(output.contains("## 📊 Coverage Report"))
        XCTAssertTrue(output.contains("**Overall Coverage:** `75.00%`"))
        XCTAssertTrue(output.contains("| Executable Lines | 100 |"))
        XCTAssertTrue(output.contains("| Covered Lines | 75 |"))
    }

    func testFormat_WithCurrentAndPrevious() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 70
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("75.00%"))
        XCTAssertTrue(output.contains("+5.00%"))
        XCTAssertTrue(output.contains("| Lines Changed | +5 |"))
    }

    func testFormat_ContainsMarkerAtStart() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.hasPrefix("<!-- xcrtool-coverage-comment -->"))
    }

    // MARK: - Coverage Summary Tests

    func testFormat_ShowsCorrectCoveragePercentage() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 67
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("67.00%"))
    }

    func testFormat_ShowsZeroCoverage() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 0
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("0.00%"))
    }

    func testFormat_ShowsFullCoverage() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 100
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("100.00%"))
    }

    func testFormat_FormatsPercentageWithTwoDecimals() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 123,
            coveredLines: 82
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("66.67%"))
    }

    // MARK: - Coverage Comparison Tests

    func testFormat_ShowsPositiveCoverageChange() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 65
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("+10.00%"))
        XCTAssertTrue(output.contains("🎉") || output.contains("✅"))
    }

    func testFormat_ShowsNegativeCoverageChange() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 65
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("-10.00%"))
        XCTAssertTrue(output.contains("⚠️") || output.contains("📉"))
    }

    func testFormat_ShowsNoCoverageChange() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("±0.00%"))
        XCTAssertTrue(output.contains("➡️"))
    }

    func testFormat_ShowsCelebrationEmojiForLargeIncrease() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 60
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("🎉"))
    }

    func testFormat_ShowsWarningEmojiForLargeDecrease() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 60
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("⚠️"))
    }

    func testFormat_ShowsSmallPositiveChangeEmoji() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 1000,
            coveredLines: 740
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 1000,
            coveredLines: 743
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("✅"))
    }

    func testFormat_ShowsSmallNegativeChangeEmoji() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 1000,
            coveredLines: 750
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 1000,
            coveredLines: 747
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("📉"))
    }

    // MARK: - Top Changed Files Tests

    func testFormat_ShowsTopChangedFiles() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50),
            ("File2.swift", "path/File2.swift", 100, 60),
            ("File3.swift", "path/File3.swift", 100, 70)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 80),
            ("File2.swift", "path/File2.swift", 100, 65),
            ("File3.swift", "path/File3.swift", 100, 65)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("## 📈 Top Changed Files"))
        XCTAssertTrue(output.contains("`File1.swift`"))
        XCTAssertTrue(output.contains("80.00%"))
        XCTAssertTrue(output.contains("+30.00%"))
    }

    func testFormat_SortsChangedFilesByAbsoluteDifference() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50),
            ("File2.swift", "path/File2.swift", 100, 60),
            ("File3.swift", "path/File3.swift", 100, 70)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 55), // +5%
            ("File2.swift", "path/File2.swift", 100, 80), // +20%
            ("File3.swift", "path/File3.swift", 100, 60)  // -10%
        ])

        let output = formatter.format(current: current, previous: previous)
        let lines = output.components(separatedBy: "\n")

        // File2 should appear before File3 and File1 (20% > 10% > 5%)
        let file2Index = lines.firstIndex { $0.contains("File2.swift") } ?? 0
        let file3Index = lines.firstIndex { $0.contains("File3.swift") } ?? 0
        let file1Index = lines.firstIndex { $0.contains("File1.swift") } ?? 0

        XCTAssertLessThan(file2Index, file3Index)
        XCTAssertLessThan(file3Index, file1Index)
    }

    func testFormat_LimitsTopChangedFiles() throws {
        let previousFiles = (0..<10).map { index in
            ("File\(index).swift", "path/File\(index).swift", 100, 50)
        }
        let currentFiles = (0..<10).map { index in
            ("File\(index).swift", "path/File\(index).swift", 100, 50 + index + 1)
        }

        let previous = Self.makeCoverageMetaReportWithFiles(previousFiles)
        let current = Self.makeCoverageMetaReportWithFiles(currentFiles)

        let output = formatter.format(current: current, previous: previous, topFiles: 3)

        let changedFilesSection = output.components(separatedBy: "## 📈 Top Changed Files").last ?? ""
        let fileMatches = changedFilesSection.components(separatedBy: "`File").count - 1

        XCTAssertEqual(fileMatches, 3)
    }

    func testFormat_OmitsTopChangedFilesWhenNoPrevious() throws {
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50)
        ])

        let output = formatter.format(current: current)

        XCTAssertFalse(output.contains("## 📈 Top Changed Files"))
    }

    func testFormat_OmitsTopChangedFilesWhenNoChanges() throws {
        let files = [
            ("File1.swift", "path/File1.swift", 100, 50),
            ("File2.swift", "path/File2.swift", 100, 60)
        ]
        let previous = Self.makeCoverageMetaReportWithFiles(files)
        let current = Self.makeCoverageMetaReportWithFiles(files)

        let output = formatter.format(current: current, previous: previous)

        XCTAssertFalse(output.contains("## 📈 Top Changed Files"))
    }

    // MARK: - New Untested Files Tests

    func testFormat_ShowsNewUntestedFiles() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50),
            ("NewFile.swift", "path/NewFile.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("## ⚠️ New Untested Files"))
        XCTAssertTrue(output.contains("`NewFile.swift`"))
        XCTAssertTrue(output.contains("50"))
    }

    func testFormat_OmitsNewUntestedFilesWhenParameterIsFalse() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50),
            ("NewFile.swift", "path/NewFile.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous, includeUntested: false)

        XCTAssertFalse(output.contains("## ⚠️ New Untested Files"))
        XCTAssertFalse(output.contains("NewFile.swift"))
    }

    func testFormat_OmitsNewUntestedFilesWhenNoPrevious() throws {
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 0)
        ])

        let output = formatter.format(current: current)

        XCTAssertFalse(output.contains("## ⚠️ New Untested Files"))
    }

    func testFormat_OmitsNewUntestedFilesWhenAllNewFilesAreTested() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50),
            ("NewFile.swift", "path/NewFile.swift", 50, 25)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertFalse(output.contains("## ⚠️ New Untested Files"))
    }

    func testFormat_OnlyIncludesNewUntestedFiles() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("OldFile.swift", "path/OldFile.swift", 100, 0)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("OldFile.swift", "path/OldFile.swift", 100, 0),
            ("NewFile.swift", "path/NewFile.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("`NewFile.swift`"))
        XCTAssertFalse(output.contains("`OldFile.swift`"))
    }

    func testFormat_SortsUntestedFilesByExecutableLines() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("Small.swift", "path/Small.swift", 10, 0),
            ("Large.swift", "path/Large.swift", 100, 0),
            ("Medium.swift", "path/Medium.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous)
        let lines = output.components(separatedBy: "\n")

        // Large should appear before Medium and Medium before Small
        let largeIndex = lines.firstIndex { $0.contains("Large.swift") } ?? 0
        let mediumIndex = lines.firstIndex { $0.contains("Medium.swift") } ?? 0
        let smallIndex = lines.firstIndex { $0.contains("Small.swift") } ?? 0

        XCTAssertLessThan(largeIndex, mediumIndex)
        XCTAssertLessThan(mediumIndex, smallIndex)
    }

    func testFormat_ExcludesNewFilesWithNoExecutableLines() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("EmptyFile.swift", "path/EmptyFile.swift", 0, 0),
            ("UntestedFile.swift", "path/UntestedFile.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("`UntestedFile.swift`"))
        XCTAssertFalse(output.contains("`EmptyFile.swift`"))
    }

    // MARK: - Table Formatting Tests

    func testFormat_ContainsCoverageTable() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("| Metric | Value |"))
        XCTAssertTrue(output.contains("| :--- | :---: |"))
    }

    func testFormat_ContainsTopChangedFilesTable() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 50)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 75)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("| File | Coverage | Change |"))
    }

    func testFormat_ContainsNewUntestedFilesTable() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("NewFile.swift", "path/NewFile.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("| File | Executable Lines |"))
    }

    // MARK: - Edge Cases

    func testFormat_EmptyReport() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 0,
            coveredLines: 0
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("0.00%"))
        XCTAssertTrue(output.contains("| Executable Lines | 0 |"))
        XCTAssertTrue(output.contains("| Covered Lines | 0 |"))
    }

    func testFormat_VeryLargeCoverageValues() throws {
        let current = Self.makeCoverageMetaReport(
            executableLines: 1000000,
            coveredLines: 750000
        )

        let output = formatter.format(current: current)

        XCTAssertTrue(output.contains("75.00%"))
        XCTAssertTrue(output.contains("1000000"))
        XCTAssertTrue(output.contains("750000"))
    }

    func testFormat_SmallCoverageChange() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 76
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("+1.00%"))
        XCTAssertTrue(output.contains("| Lines Changed | +1 |"))
    }

    func testFormat_NegativeLineChange() throws {
        let previous = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 75
        )
        let current = Self.makeCoverageMetaReport(
            executableLines: 100,
            coveredLines: 70
        )

        let output = formatter.format(current: current, previous: previous)

        XCTAssertTrue(output.contains("| Lines Changed | -5 |"))
    }

    // MARK: - Integration Tests

    func testFormat_CompleteScenario() throws {
        let previous = Self.makeCoverageMetaReportWithFiles([
            ("OldFile.swift", "path/OldFile.swift", 100, 50),
            ("UpdatedFile.swift", "path/UpdatedFile.swift", 100, 60)
        ])
        let current = Self.makeCoverageMetaReportWithFiles([
            ("OldFile.swift", "path/OldFile.swift", 100, 50),
            ("UpdatedFile.swift", "path/UpdatedFile.swift", 100, 80),
            ("NewFile.swift", "path/NewFile.swift", 50, 0)
        ])

        let output = formatter.format(current: current, previous: previous)

        // Should contain all sections
        XCTAssertTrue(output.contains("## 📊 Coverage Report"))
        XCTAssertTrue(output.contains("## 📈 Top Changed Files"))
        XCTAssertTrue(output.contains("## ⚠️ New Untested Files"))

        // Should show updated file in changes
        XCTAssertTrue(output.contains("`UpdatedFile.swift`"))
        XCTAssertTrue(output.contains("80.00%"))
        XCTAssertTrue(output.contains("+20.00%"))

        // Should show new untested file
        XCTAssertTrue(output.contains("`NewFile.swift`"))
    }

    func testFormat_OnlyCurrentReport() throws {
        let current = Self.makeCoverageMetaReportWithFiles([
            ("File1.swift", "path/File1.swift", 100, 75),
            ("File2.swift", "path/File2.swift", 100, 80)
        ])

        let output = formatter.format(current: current)

        // Should only contain coverage summary
        XCTAssertTrue(output.contains("## 📊 Coverage Report"))
        XCTAssertFalse(output.contains("## 📈 Top Changed Files"))
        XCTAssertFalse(output.contains("## ⚠️ New Untested Files"))

        // Should not show comparison data
        XCTAssertFalse(output.contains("Lines Changed"))
    }
}

// MARK: - Test Helpers

extension PRCommentFormatterTests {
    static func makeCoverageMetaReport(
        executableLines: Int,
        coveredLines: Int
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
            path: "path/TestFile.swift",
            functions: [function]
        )

        let target = Target(
            name: "TestTarget",
            files: [file]
        )

        let coverage = CoverageReport(targets: [target])

        return CoverageMetaReport(
            fileInfo: makeXCResultFile(),
            coverage: coverage
        )
    }

    static func makeCoverageMetaReportWithFiles(
        _ files: [(name: String, path: String, executableLines: Int, coveredLines: Int)]
    ) -> CoverageMetaReport {
        let coverageFiles = files.map { file in
            let function = Function(
                name: "testFunction",
                executableLines: file.executableLines,
                coveredLines: file.coveredLines,
                lineNumber: 1,
                executionCount: file.coveredLines > 0 ? 1 : 0
            )

            return File(
                name: file.name,
                path: file.path,
                functions: [function]
            )
        }

        let target = Target(
            name: "TestTarget",
            files: coverageFiles
        )

        let coverage = CoverageReport(targets: [target])

        return CoverageMetaReport(
            fileInfo: makeXCResultFile(),
            coverage: coverage
        )
    }

    static func makeXCResultFile() -> XCResultFile {
        // Create a properly formatted filename for XCResultFile
        // Format: "Run-ApplicationName-2023.05.08_15-14-43-+0200.xcresult"
        let url = URL(fileURLWithPath: "Run-TestApp-2023.05.08_15-14-43-+0200.xcresult")
        return try! XCResultFile(with: url)
    }
}
