//
//  CSVEncoderTests.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation
@testable import Helper
import Shared
import XCTest

final class CSVEncoderTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeTarget(name: String, executableLines: Int, coveredLines: Int) -> Target {
        let function = Function(
            name: "testFunction",
            executableLines: executableLines,
            coveredLines: coveredLines,
            lineNumber: 1,
            executionCount: 1
        )
        let file = File(name: "TestFile.swift", path: "/path/to/TestFile.swift", functions: [function])
        return Target(name: name, files: [file])
    }

    private func makeCoverageReport(targets: [Target]) -> CoverageReport {
        CoverageReport(targets: targets)
    }

    private func makeCoverageMetaReport(coverage: CoverageReport, date: Date = Date()) -> CoverageMetaReport {
        let url = URL(fileURLWithPath: "/path/to/Run-TestApp-2023.05.08_15-14-43-+0200.xcresult")
        let fileInfo = try! XCResultFile(with: url)
        return CoverageMetaReport(fileInfo: fileInfo, coverage: coverage)
    }

    // MARK: - Header Tests

    func testEncodeHeader() throws {
        let target = makeTarget(name: "TestTarget", executableLines: 100, coveredLines: 75)
        let report = makeCoverageReport(targets: [target])
        let metaReport = makeCoverageMetaReport(coverage: report)

        let encoder = CSVEncoderType.header(meta: metaReport)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Report,Date,Overall Coverage"))
        XCTAssertTrue(result.contains("Coverage Report"))
        XCTAssertTrue(result.contains("75.0"))
    }

    func testEncodeHeaderTitle() throws {
        let target = makeTarget(name: "TestTarget", executableLines: 100, coveredLines: 75)
        let report = makeCoverageReport(targets: [target])
        let metaReport = makeCoverageMetaReport(coverage: report)

        let encoder = CSVEncoderType.header(meta: metaReport)

        XCTAssertEqual(encoder.title, "Coverage Report")
    }

    // MARK: - Detailed Tests

    func testEncodeDetailed() throws {
        let target1 = makeTarget(name: "TargetA", executableLines: 100, coveredLines: 80)
        let target2 = makeTarget(name: "TargetB", executableLines: 100, coveredLines: 60)
        let report = makeCoverageReport(targets: [target1, target2])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Rank,Target,Executable Lines,Covered Lines,Coverage"))
        XCTAssertTrue(result.contains("1,TargetA,100,80,80.00"))
        XCTAssertTrue(result.contains("2,TargetB,100,60,60.00"))
    }

    func testEncodeDetailedSorting() throws {
        let target1 = makeTarget(name: "LowCoverage", executableLines: 100, coveredLines: 30)
        let target2 = makeTarget(name: "HighCoverage", executableLines: 100, coveredLines: 90)
        let target3 = makeTarget(name: "MediumCoverage", executableLines: 100, coveredLines: 50)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        let lines = result.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].contains("HighCoverage"), "First rank should be highest coverage")
        XCTAssertTrue(lines[2].contains("MediumCoverage"), "Second rank should be medium coverage")
        XCTAssertTrue(lines[3].contains("LowCoverage"), "Third rank should be lowest coverage")
    }

    func testEncodeDetailedTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = CSVEncoderType.detailed(report: report)

        XCTAssertEqual(encoder.title, "All Target Ranked")
    }

    // MARK: - Top Ranked Tests

    func testEncodeTopRanked() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 90)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 80)
        let target3 = makeTarget(name: "Target3", executableLines: 100, coveredLines: 70)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = CSVEncoderType.topRanked(amount: 2, report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Rank,Target,Coverage"))
        XCTAssertTrue(result.contains("1,Target1,90.00"))
        XCTAssertTrue(result.contains("2,Target2,80.00"))
        XCTAssertFalse(result.contains("Target3"), "Should only include top 2")
    }

    func testEncodeTopRankedFiltersZeroCoverage() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 0)
        let report = makeCoverageReport(targets: [target1, target2])

        let encoder = CSVEncoderType.topRanked(amount: 10, report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Target1"))
        XCTAssertFalse(result.contains("Target2"), "Should filter targets with 0 covered lines")
    }

    func testEncodeTopRankedTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = CSVEncoderType.topRanked(amount: 5, report: report)

        XCTAssertEqual(encoder.title, "TOP 5")
    }

    // MARK: - Last Ranked Tests

    func testEncodeLastRanked() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 90)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 50)
        let target3 = makeTarget(name: "Target3", executableLines: 100, coveredLines: 20)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = CSVEncoderType.lastRanked(amount: 2, report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Rank,Target,Coverage"))
        // Results should be sorted by coverage DESC after taking last 2
        let lines = result.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].contains("Target2"), "First should be Target2 (50%)")
        XCTAssertTrue(lines[2].contains("Target3"), "Second should be Target3 (20%)")
        XCTAssertFalse(result.contains("Target1"), "Should not include Target1")
    }

    func testEncodeLastRankedFiltersZeroCoverage() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 0)
        let report = makeCoverageReport(targets: [target1, target2])

        let encoder = CSVEncoderType.lastRanked(amount: 10, report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Target1"))
        XCTAssertFalse(result.contains("Target2"), "Should filter targets with 0 covered lines")
    }

    func testEncodeLastRankedTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = CSVEncoderType.lastRanked(amount: 3, report: report)

        XCTAssertEqual(encoder.title, "Last 3")
    }

    // MARK: - Uncovered Tests

    func testEncodeUncovered() throws {
        let target1 = makeTarget(name: "Uncovered1", executableLines: 100, coveredLines: 0)
        let target2 = makeTarget(name: "Uncovered2", executableLines: 50, coveredLines: 0)
        let target3 = makeTarget(name: "HasCoverage", executableLines: 100, coveredLines: 50)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = CSVEncoderType.uncovered(report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Rank,Target,Covered Lines,Executable Lines"))
        XCTAssertTrue(result.contains("Uncovered1"))
        XCTAssertTrue(result.contains("Uncovered2"))
        XCTAssertFalse(result.contains("HasCoverage"), "Should only include uncovered targets")
    }

    func testEncodeUncoveredSortsByExecutableLines() throws {
        let target1 = makeTarget(name: "Small", executableLines: 10, coveredLines: 0)
        let target2 = makeTarget(name: "Large", executableLines: 100, coveredLines: 0)
        let target3 = makeTarget(name: "Medium", executableLines: 50, coveredLines: 0)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = CSVEncoderType.uncovered(report: report)
        let result = encoder.encode()

        let lines = result.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].contains("Large"), "First should be largest")
        XCTAssertTrue(lines[2].contains("Medium"), "Second should be medium")
        XCTAssertTrue(lines[3].contains("Small"), "Third should be smallest")
    }

    func testEncodeUncoveredTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = CSVEncoderType.uncovered(report: report)

        XCTAssertEqual(encoder.title, "UNCOVERED TARGETS")
    }

    // MARK: - Compare Tests

    func testEncodeCompare() throws {
        let currentTarget1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let currentTarget2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 60)
        let currentReport = makeCoverageReport(targets: [currentTarget1, currentTarget2])

        let previousTarget1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 70)
        let previousTarget2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 65)
        let previousReport = makeCoverageReport(targets: [previousTarget1, previousTarget2])

        let encoder = CSVEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("Rank,Target,Previous,Current,Changes"))
        XCTAssertTrue(result.contains("Target1"))
        XCTAssertTrue(result.contains("70.00"))
        XCTAssertTrue(result.contains("80.00"))
        XCTAssertTrue(result.contains("+10.00"))
    }

    func testEncodeCompareWithNoPrevious() throws {
        let currentTarget = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let currentReport = makeCoverageReport(targets: [currentTarget])

        let encoder = CSVEncoderType.compare(current: currentReport, previous: nil)
        let result = encoder.encode()

        // When previous is nil, all targets should show as changes from 0
        XCTAssertTrue(result.contains("Target1"))
        XCTAssertTrue(result.contains("0.00"))
        XCTAssertTrue(result.contains("80.00"))
    }

    func testEncodeCompareFiltersInsignificantChanges() throws {
        let currentTarget1 = makeTarget(name: "BigChange", executableLines: 100, coveredLines: 80)
        // SmallChange: 10001/100000 = 10.001% vs 10000/100000 = 10.000%, diff = 0.001%
        let currentTarget2 = makeTarget(name: "SmallChange", executableLines: 100000, coveredLines: 10001)
        let currentReport = makeCoverageReport(targets: [currentTarget1, currentTarget2])

        let previousTarget1 = makeTarget(name: "BigChange", executableLines: 100, coveredLines: 70)
        let previousTarget2 = makeTarget(name: "SmallChange", executableLines: 100000, coveredLines: 10000)
        let previousReport = makeCoverageReport(targets: [previousTarget1, previousTarget2])

        let encoder = CSVEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("BigChange"), "Should include targets with >0.9% change")
        XCTAssertFalse(result.contains("SmallChange"), "Should filter targets with <0.9% change")
    }

    func testEncodeCompareNoSignificantChanges() throws {
        let currentTarget = makeTarget(name: "Target1", executableLines: 1000, coveredLines: 500)
        let currentReport = makeCoverageReport(targets: [currentTarget])

        let previousTarget = makeTarget(name: "Target1", executableLines: 1000, coveredLines: 500)
        let previousReport = makeCoverageReport(targets: [previousTarget])

        let encoder = CSVEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        XCTAssertEqual(result, "No significant changes since last time\n")
    }

    func testEncodeCompareSortsByChange() throws {
        let currentTarget1 = makeTarget(name: "SmallIncrease", executableLines: 100, coveredLines: 55)
        let currentTarget2 = makeTarget(name: "LargeIncrease", executableLines: 100, coveredLines: 90)
        let currentReport = makeCoverageReport(targets: [currentTarget1, currentTarget2])

        let previousTarget1 = makeTarget(name: "SmallIncrease", executableLines: 100, coveredLines: 50)
        let previousTarget2 = makeTarget(name: "LargeIncrease", executableLines: 100, coveredLines: 50)
        let previousReport = makeCoverageReport(targets: [previousTarget1, previousTarget2])

        let encoder = CSVEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        let lines = result.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].contains("LargeIncrease"), "First should be largest increase")
        XCTAssertTrue(lines[2].contains("SmallIncrease"), "Second should be smaller increase")
    }

    func testEncodeCompareTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = CSVEncoderType.compare(current: report, previous: nil)

        XCTAssertEqual(encoder.title, "Changes")
    }

    // MARK: - CSV Escaping Tests

    func testCSVEscapingWithComma() throws {
        let target = makeTarget(name: "Target,WithComma", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("\"Target,WithComma\""), "Should escape names with commas")
    }

    func testCSVEscapingWithQuotes() throws {
        let target = makeTarget(name: "Target\"WithQuotes\"", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("\"Target\"\"WithQuotes\"\"\""), "Should escape quotes by doubling them")
    }

    func testCSVEscapingWithNewline() throws {
        let target = makeTarget(name: "Target\nWithNewline", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("\"Target\nWithNewline\""), "Should escape names with newlines")
    }

    func testCSVEscapingNoEscapeNeeded() throws {
        let target = makeTarget(name: "SimpleTargetName", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        XCTAssertTrue(result.contains("SimpleTargetName"))
        XCTAssertFalse(result.contains("\"SimpleTargetName\""), "Should not escape simple names")
    }

    // MARK: - Edge Cases

    func testEncodeEmptyReport() throws {
        let report = makeCoverageReport(targets: [])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        XCTAssertEqual(result, "Rank,Target,Executable Lines,Covered Lines,Coverage\n")
    }

    func testEncodeZeroDivision() throws {
        let target = makeTarget(name: "Target", executableLines: 0, coveredLines: 0)
        let report = makeCoverageReport(targets: [target])

        let encoder = CSVEncoderType.detailed(report: report)
        let result = encoder.encode()

        // Should handle zero division gracefully
        XCTAssertTrue(result.contains("Target"))
        XCTAssertTrue(result.contains("0.00"))
    }
}
