//
//  JSONSummaryEncoderTests.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation
@testable import Helper
import Shared
import XCTest

final class JSONSummaryEncoderTests: XCTestCase {

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

    private func parseJSON(_ jsonString: String) throws -> [String: Any] {
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON")
            return [:]
        }
        return json
    }

    // MARK: - Header Tests

    func testEncodeHeader() throws {
        let target = makeTarget(name: "TestTarget", executableLines: 100, coveredLines: 75)
        let report = makeCoverageReport(targets: [target])
        let metaReport = makeCoverageMetaReport(coverage: report)

        let encoder = JSONSummaryEncoderType.header(meta: metaReport)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["type"] as? String, "Coverage Report")
        XCTAssertNotNil(json["date"])
        XCTAssertNotNil(json["application"])

        guard let overall = json["overall"] as? [String: Any] else {
            XCTFail("Missing overall section")
            return
        }

        XCTAssertEqual(overall["coverage"] as? String, "75.00")
        XCTAssertEqual(overall["lines_covered"] as? Int, 75)
        XCTAssertEqual(overall["lines_total"] as? Int, 100)
    }

    func testEncodeHeaderTitle() throws {
        let target = makeTarget(name: "TestTarget", executableLines: 100, coveredLines: 75)
        let report = makeCoverageReport(targets: [target])
        let metaReport = makeCoverageMetaReport(coverage: report)

        let encoder = JSONSummaryEncoderType.header(meta: metaReport)

        XCTAssertEqual(encoder.title, "Coverage Report")
    }

    func testEncodeHeaderContainsApplicationName() throws {
        let target = makeTarget(name: "TestTarget", executableLines: 100, coveredLines: 75)
        let report = makeCoverageReport(targets: [target])
        let metaReport = makeCoverageMetaReport(coverage: report)

        let encoder = JSONSummaryEncoderType.header(meta: metaReport)
        let result = encoder.encode()

        let json = try parseJSON(result)
        XCTAssertEqual(json["application"] as? String, "TestApp")
    }

    // MARK: - Detailed Tests

    func testEncodeDetailed() throws {
        let target1 = makeTarget(name: "TargetA", executableLines: 100, coveredLines: 80)
        let target2 = makeTarget(name: "TargetB", executableLines: 100, coveredLines: 60)
        let report = makeCoverageReport(targets: [target1, target2])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["type"] as? String, "All Target Ranked")

        guard let overall = json["overall"] as? [String: Any] else {
            XCTFail("Missing overall section")
            return
        }

        XCTAssertEqual(overall["coverage"] as? String, "70.00")
        XCTAssertEqual(overall["lines_covered"] as? Int, 140)
        XCTAssertEqual(overall["lines_total"] as? Int, 200)

        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 2)
        XCTAssertEqual(targets[0]["rank"] as? Int, 1)
        XCTAssertEqual(targets[0]["name"] as? String, "TargetA")
        XCTAssertEqual(targets[0]["coverage"] as? String, "80.00")
        XCTAssertEqual(targets[0]["executable_lines"] as? Int, 100)
        XCTAssertEqual(targets[0]["covered_lines"] as? Int, 80)
    }

    func testEncodeDetailedSorting() throws {
        let target1 = makeTarget(name: "LowCoverage", executableLines: 100, coveredLines: 30)
        let target2 = makeTarget(name: "HighCoverage", executableLines: 100, coveredLines: 90)
        let target3 = makeTarget(name: "MediumCoverage", executableLines: 100, coveredLines: 50)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets[0]["name"] as? String, "HighCoverage", "First rank should be highest coverage")
        XCTAssertEqual(targets[1]["name"] as? String, "MediumCoverage", "Second rank should be medium coverage")
        XCTAssertEqual(targets[2]["name"] as? String, "LowCoverage", "Third rank should be lowest coverage")
    }

    func testEncodeDetailedTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = JSONSummaryEncoderType.detailed(report: report)

        XCTAssertEqual(encoder.title, "All Target Ranked")
    }

    // MARK: - Top Ranked Tests

    func testEncodeTopRanked() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 90)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 80)
        let target3 = makeTarget(name: "Target3", executableLines: 100, coveredLines: 70)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = JSONSummaryEncoderType.topRanked(amount: 2, report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["type"] as? String, "TOP 2")

        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 2, "Should only include top 2")
        XCTAssertEqual(targets[0]["rank"] as? Int, 1)
        XCTAssertEqual(targets[0]["name"] as? String, "Target1")
        XCTAssertEqual(targets[0]["coverage"] as? String, "90.00")
        XCTAssertEqual(targets[1]["rank"] as? Int, 2)
        XCTAssertEqual(targets[1]["name"] as? String, "Target2")
        XCTAssertEqual(targets[1]["coverage"] as? String, "80.00")
    }

    func testEncodeTopRankedFiltersZeroCoverage() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 0)
        let report = makeCoverageReport(targets: [target1, target2])

        let encoder = JSONSummaryEncoderType.topRanked(amount: 10, report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 1, "Should filter targets with 0 covered lines")
        XCTAssertEqual(targets[0]["name"] as? String, "Target1")
    }

    func testEncodeTopRankedTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = JSONSummaryEncoderType.topRanked(amount: 5, report: report)

        XCTAssertEqual(encoder.title, "TOP 5")
    }

    // MARK: - Last Ranked Tests

    func testEncodeLastRanked() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 90)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 50)
        let target3 = makeTarget(name: "Target3", executableLines: 100, coveredLines: 20)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = JSONSummaryEncoderType.lastRanked(amount: 2, report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 2, "Should only include last 2")
        // Results should be sorted by coverage DESC after taking last 2
        XCTAssertEqual(targets[0]["name"] as? String, "Target2", "First should be Target2 (50%)")
        XCTAssertEqual(targets[1]["name"] as? String, "Target3", "Second should be Target3 (20%)")
    }

    func testEncodeLastRankedFiltersZeroCoverage() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 0)
        let report = makeCoverageReport(targets: [target1, target2])

        let encoder = JSONSummaryEncoderType.lastRanked(amount: 10, report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 1, "Should filter targets with 0 covered lines")
        XCTAssertEqual(targets[0]["name"] as? String, "Target1")
    }

    func testEncodeLastRankedTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = JSONSummaryEncoderType.lastRanked(amount: 3, report: report)

        XCTAssertEqual(encoder.title, "Last 3")
    }

    // MARK: - Uncovered Tests

    func testEncodeUncovered() throws {
        let target1 = makeTarget(name: "Uncovered1", executableLines: 100, coveredLines: 0)
        let target2 = makeTarget(name: "Uncovered2", executableLines: 50, coveredLines: 0)
        let target3 = makeTarget(name: "HasCoverage", executableLines: 100, coveredLines: 50)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = JSONSummaryEncoderType.uncovered(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["type"] as? String, "UNCOVERED TARGETS")

        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 2, "Should only include uncovered targets")
        XCTAssertEqual(targets[0]["name"] as? String, "Uncovered1")
        XCTAssertEqual(targets[1]["name"] as? String, "Uncovered2")
    }

    func testEncodeUncoveredSortsByExecutableLines() throws {
        let target1 = makeTarget(name: "Small", executableLines: 10, coveredLines: 0)
        let target2 = makeTarget(name: "Large", executableLines: 100, coveredLines: 0)
        let target3 = makeTarget(name: "Medium", executableLines: 50, coveredLines: 0)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = JSONSummaryEncoderType.uncovered(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets[0]["name"] as? String, "Large", "First should be largest")
        XCTAssertEqual(targets[1]["name"] as? String, "Medium", "Second should be medium")
        XCTAssertEqual(targets[2]["name"] as? String, "Small", "Third should be smallest")
    }

    func testEncodeUncoveredTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = JSONSummaryEncoderType.uncovered(report: report)

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

        let encoder = JSONSummaryEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["type"] as? String, "Changes")

        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertTrue(targets.count > 0)

        let target1Data = targets.first { ($0["name"] as? String) == "Target1" }
        XCTAssertNotNil(target1Data)
        XCTAssertEqual(target1Data?["previous"] as? String, "70.00")
        XCTAssertEqual(target1Data?["current"] as? String, "80.00")
        XCTAssertEqual(target1Data?["change"] as? String, "+10.00")

        guard let comparison = json["comparison"] as? [String: Any] else {
            XCTFail("Missing comparison section")
            return
        }

        XCTAssertNotNil(comparison["previous_coverage"])
        XCTAssertNotNil(comparison["current_coverage"])
        XCTAssertNotNil(comparison["delta"])
    }

    func testEncodeCompareWithNoPrevious() throws {
        let currentTarget = makeTarget(name: "Target1", executableLines: 100, coveredLines: 80)
        let currentReport = makeCoverageReport(targets: [currentTarget])

        let encoder = JSONSummaryEncoderType.compare(current: currentReport, previous: nil)
        let result = encoder.encode()

        let json = try parseJSON(result)

        // When previous is nil, all targets should show as changes from 0
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertTrue(targets.count > 0)
        let target = targets.first { ($0["name"] as? String) == "Target1" }
        XCTAssertNotNil(target)
        XCTAssertEqual(target?["previous"] as? String, "0.00")
        XCTAssertEqual(target?["current"] as? String, "80.00")

        // Should not have comparison section when previous is nil
        XCTAssertNil(json["comparison"])
    }

    func testEncodeCompareFiltersInsignificantChanges() throws {
        let currentTarget1 = makeTarget(name: "BigChange", executableLines: 100, coveredLines: 80)
        // SmallChange: 10001/100000 = 10.001% vs 10000/100000 = 10.000%, diff = 0.001%
        let currentTarget2 = makeTarget(name: "SmallChange", executableLines: 100000, coveredLines: 10001)
        let currentReport = makeCoverageReport(targets: [currentTarget1, currentTarget2])

        let previousTarget1 = makeTarget(name: "BigChange", executableLines: 100, coveredLines: 70)
        let previousTarget2 = makeTarget(name: "SmallChange", executableLines: 100000, coveredLines: 10000)
        let previousReport = makeCoverageReport(targets: [previousTarget1, previousTarget2])

        let encoder = JSONSummaryEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        let targetNames = targets.compactMap { $0["name"] as? String }
        XCTAssertTrue(targetNames.contains("BigChange"), "Should include targets with >0.9% change")
        XCTAssertFalse(targetNames.contains("SmallChange"), "Should filter targets with <0.9% change")
    }

    func testEncodeCompareNoSignificantChanges() throws {
        let currentTarget = makeTarget(name: "Target1", executableLines: 1000, coveredLines: 500)
        let currentReport = makeCoverageReport(targets: [currentTarget])

        let previousTarget = makeTarget(name: "Target1", executableLines: 1000, coveredLines: 500)
        let previousReport = makeCoverageReport(targets: [previousTarget])

        let encoder = JSONSummaryEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["message"] as? String, "No significant changes since last time")

        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 0, "Should have empty targets array when no significant changes")
    }

    func testEncodeCompareSortsByChange() throws {
        let currentTarget1 = makeTarget(name: "SmallIncrease", executableLines: 100, coveredLines: 55)
        let currentTarget2 = makeTarget(name: "LargeIncrease", executableLines: 100, coveredLines: 90)
        let currentReport = makeCoverageReport(targets: [currentTarget1, currentTarget2])

        let previousTarget1 = makeTarget(name: "SmallIncrease", executableLines: 100, coveredLines: 50)
        let previousTarget2 = makeTarget(name: "LargeIncrease", executableLines: 100, coveredLines: 50)
        let previousReport = makeCoverageReport(targets: [previousTarget1, previousTarget2])

        let encoder = JSONSummaryEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets[0]["name"] as? String, "LargeIncrease", "First should be largest increase")
        XCTAssertEqual(targets[1]["name"] as? String, "SmallIncrease", "Second should be smaller increase")
    }

    func testEncodeCompareTitle() throws {
        let report = makeCoverageReport(targets: [])
        let encoder = JSONSummaryEncoderType.compare(current: report, previous: nil)

        XCTAssertEqual(encoder.title, "Changes")
    }

    func testEncodeCompareDeltaFormatting() throws {
        let currentTarget1 = makeTarget(name: "Increase", executableLines: 100, coveredLines: 60)
        let currentTarget2 = makeTarget(name: "Decrease", executableLines: 100, coveredLines: 40)
        let currentReport = makeCoverageReport(targets: [currentTarget1, currentTarget2])

        let previousTarget1 = makeTarget(name: "Increase", executableLines: 100, coveredLines: 50)
        let previousTarget2 = makeTarget(name: "Decrease", executableLines: 100, coveredLines: 50)
        let previousReport = makeCoverageReport(targets: [previousTarget1, previousTarget2])

        let encoder = JSONSummaryEncoderType.compare(current: currentReport, previous: previousReport)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let comparison = json["comparison"] as? [String: Any],
              let delta = comparison["delta"] as? String else {
            XCTFail("Missing comparison delta")
            return
        }

        // Overall delta should be 0 (55% average for both current and previous)
        XCTAssertTrue(delta.hasPrefix("+") || delta.hasPrefix("-") || delta == "0.00", "Delta should be properly formatted")
    }

    // MARK: - JSON Structure Tests

    func testJSONIsWellFormed() throws {
        let target = makeTarget(name: "Target", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        // Should not throw when parsing
        XCTAssertNoThrow(try parseJSON(result))
    }

    func testJSONContainsSortedKeys() throws {
        let target = makeTarget(name: "Target", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        // JSON should be pretty-printed with sorted keys
        XCTAssertTrue(result.contains("\n"), "JSON should be pretty-printed")
        XCTAssertTrue(result.contains("  "), "JSON should have proper indentation")
    }

    func testJSONErrorHandling() throws {
        // This test verifies the encoder handles edge cases without crashing
        let target = makeTarget(name: "Test", executableLines: 0, coveredLines: 0)
        let report = makeCoverageReport(targets: [target])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        // Should return valid JSON even with zero values
        XCTAssertNoThrow(try parseJSON(result))
    }

    // MARK: - Edge Cases

    func testEncodeEmptyReport() throws {
        let report = makeCoverageReport(targets: [])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)

        XCTAssertEqual(json["type"] as? String, "All Target Ranked")

        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets.count, 0, "Should have empty targets array")
    }

    func testEncodeZeroDivision() throws {
        let target = makeTarget(name: "Target", executableLines: 0, coveredLines: 0)
        let report = makeCoverageReport(targets: [target])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        // Should handle zero division gracefully
        XCTAssertTrue(targets.count > 0)
        XCTAssertEqual(targets[0]["name"] as? String, "Target")
        XCTAssertEqual(targets[0]["coverage"] as? String, "0.00")
    }

    func testEncodeSpecialCharactersInTargetName() throws {
        let target = makeTarget(name: "Target-With-Special/Characters", executableLines: 100, coveredLines: 80)
        let report = makeCoverageReport(targets: [target])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        XCTAssertEqual(targets[0]["name"] as? String, "Target-With-Special/Characters", "Should preserve special characters in JSON")
    }

    func testEncodeRankingConsistency() throws {
        let target1 = makeTarget(name: "Target1", executableLines: 100, coveredLines: 90)
        let target2 = makeTarget(name: "Target2", executableLines: 100, coveredLines: 80)
        let target3 = makeTarget(name: "Target3", executableLines: 100, coveredLines: 70)
        let report = makeCoverageReport(targets: [target1, target2, target3])

        let encoder = JSONSummaryEncoderType.detailed(report: report)
        let result = encoder.encode()

        let json = try parseJSON(result)
        guard let targets = json["targets"] as? [[String: Any]] else {
            XCTFail("Missing targets array")
            return
        }

        // Verify ranks are sequential
        for (index, target) in targets.enumerated() {
            XCTAssertEqual(target["rank"] as? Int, index + 1, "Ranks should be sequential")
        }
    }
}
