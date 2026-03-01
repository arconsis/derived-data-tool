//
//  CoverageCommandThresholdTests.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
@testable import Coverage
@testable import Helper
@testable import Shared
import XCTest

final class CoverageCommandThresholdTests: XCTestCase {
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

    // MARK: - Absolute Threshold Tests

    func testThresholdSettings_ParsesMinCoverage() throws {
        let values = ["min_coverage": "80.0"]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNotNil(settings.minCoverage)
        XCTAssertEqual(settings.minCoverage!, 80.0, accuracy: 0.01)
        XCTAssertNil(settings.maxDrop)
        XCTAssertTrue(settings.perTargetThresholds.isEmpty)
    }

    func testThresholdSettings_ParsesMaxDrop() throws {
        let values = ["max_drop": "5.0"]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNil(settings.minCoverage)
        XCTAssertNotNil(settings.maxDrop)
        XCTAssertEqual(settings.maxDrop!, 5.0, accuracy: 0.01)
        XCTAssertTrue(settings.perTargetThresholds.isEmpty)
    }

    func testThresholdSettings_ParsesBothValues() throws {
        let values = [
            "min_coverage": "75.0",
            "max_drop": "3.0"
        ]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNotNil(settings.minCoverage)
        XCTAssertEqual(settings.minCoverage!, 75.0, accuracy: 0.01)
        XCTAssertNotNil(settings.maxDrop)
        XCTAssertEqual(settings.maxDrop!, 3.0, accuracy: 0.01)
    }

    func testThresholdSettings_ParsesPerTargetThresholds() throws {
        let perTargetJSON = """
        {
            "TargetA": {"minCoverage": 80.0},
            "TargetB": {"minCoverage": 90.0}
        }
        """

        let values = [
            "min_coverage": "75.0",
            "per_target_thresholds": perTargetJSON
        ]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNotNil(settings.minCoverage)
        XCTAssertEqual(settings.minCoverage!, 75.0, accuracy: 0.01)
        XCTAssertEqual(settings.perTargetThresholds.count, 2)

        if let targetA = settings.perTargetThresholds["TargetA"]?.minCoverage {
            XCTAssertEqual(targetA, 80.0, accuracy: 0.01)
        } else {
            XCTFail("TargetA minCoverage should not be nil")
        }

        if let targetB = settings.perTargetThresholds["TargetB"]?.minCoverage {
            XCTAssertEqual(targetB, 90.0, accuracy: 0.01)
        } else {
            XCTFail("TargetB minCoverage should not be nil")
        }
    }

    func testThresholdSettings_HandlesEmptyValues() throws {
        let values: [String: String] = [:]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNil(settings.minCoverage)
        XCTAssertNil(settings.maxDrop)
        XCTAssertTrue(settings.perTargetThresholds.isEmpty)
    }

    func testThresholdSettings_HandlesInvalidJSON() throws {
        let values = [
            "min_coverage": "75.0",
            "per_target_thresholds": "invalid json"
        ]
        let settings = try ThresholdSettings(values: values)

        // Should still parse min_coverage but skip invalid per_target_thresholds
        XCTAssertNotNil(settings.minCoverage)
        XCTAssertEqual(settings.minCoverage!, 75.0, accuracy: 0.01)
        XCTAssertTrue(settings.perTargetThresholds.isEmpty)
    }

    func testThresholdSettings_ToDictRoundTrip() throws {
        let perTargetJSON = """
        {"TargetA": {"minCoverage": 85.0}}
        """

        let originalValues = [
            "min_coverage": "80.0",
            "max_drop": "5.0",
            "per_target_thresholds": perTargetJSON
        ]

        let settings = try ThresholdSettings(values: originalValues)
        let dict = try settings.toDict()
        let recreated = try ThresholdSettings(values: dict)

        XCTAssertEqual(settings.minCoverage, recreated.minCoverage)
        XCTAssertEqual(settings.maxDrop, recreated.maxDrop)
        XCTAssertEqual(settings.perTargetThresholds.count, recreated.perTargetThresholds.count)
    }

    // MARK: - Validator Integration Tests

    func testValidator_WithAbsoluteThreshold_Passes() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let validator = ThresholdValidator()

        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidator_WithAbsoluteThreshold_Fails() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let validator = ThresholdValidator()

        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 80.0)

        XCTAssertFalse(result.isPassing)
        if case .fail(let reason, let details) = result {
            XCTAssertTrue(reason.contains("70.00"))
            XCTAssertTrue(reason.contains("80.00"))
            XCTAssertEqual(details.expected, 80.0, accuracy: 0.01)
            XCTAssertEqual(details.actual, 70.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result")
        }
    }

    func testValidator_WithRelativeThreshold_NoPreviousReport() throws {
        let current = Self.makeCoverageReport(coveredLines: 50, executableLines: 100)
        let validator = ThresholdValidator()

        let result = validator.validateRelative(current: current, previous: nil, maxDrop: 5.0)

        // Should pass when there's no previous report to compare against
        XCTAssertTrue(result.isPassing)
    }

    func testValidator_WithRelativeThreshold_PassesWithinLimit() throws {
        let previous = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 77, executableLines: 100)
        let validator = ThresholdValidator()

        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidator_WithRelativeThreshold_FailsExceedsLimit() throws {
        let previous = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let validator = ThresholdValidator()

        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertFalse(result.isPassing)
        if case .fail(let reason, let details) = result {
            XCTAssertTrue(reason.contains("10.00"))
            XCTAssertTrue(reason.contains("5.00"))
            XCTAssertEqual(details.actual, 10.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result")
        }
    }

    func testValidator_WithPerTargetThresholds_AllPass() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 85, 100),
            ("TargetB", 92, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 80.0),
            "TargetB": ThresholdConfig(minCoverage: 90.0)
        ]

        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.isPassing })
    }

    func testValidator_WithPerTargetThresholds_SomeFail() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 85, 100),
            ("TargetB", 70, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 80.0),
            "TargetB": ThresholdConfig(minCoverage: 85.0)
        ]

        let validator = ThresholdValidator()
        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        let failingResults = results.filter { !$0.isPassing }
        XCTAssertEqual(failingResults.count, 1)

        if case .fail(let reason, let details) = failingResults.first! {
            XCTAssertEqual(details.targetName, "TargetB")
            XCTAssertTrue(reason.contains("TargetB"))
        } else {
            XCTFail("Expected fail result for TargetB")
        }
    }

    // MARK: - Error Message Tests

    func testCoverageError_ThresholdFailedAbsolute() {
        let error = CoverageError.thresholdFailedAbsolute(expected: 80.0, actual: 70.0)

        let message = error.localizedDescription
        XCTAssertTrue(message.contains("80.00"))
        XCTAssertTrue(message.contains("70.00"))
        XCTAssertTrue(message.contains("threshold"))
    }

    func testCoverageError_ThresholdFailedRelative() {
        let error = CoverageError.thresholdFailedRelative(maxDrop: 5.0, actualDrop: 10.0)

        let message = error.localizedDescription
        XCTAssertTrue(message.contains("5.00"))
        XCTAssertTrue(message.contains("10.00"))
        XCTAssertTrue(message.contains("drop"))
    }

    func testCoverageError_ThresholdFailedPerTarget() {
        let error = CoverageError.thresholdFailedPerTarget(target: "MyTarget", expected: 90.0, actual: 75.0)

        let message = error.localizedDescription
        XCTAssertTrue(message.contains("MyTarget"))
        XCTAssertTrue(message.contains("90.00"))
        XCTAssertTrue(message.contains("75.00"))
    }

    // MARK: - Database Integration Tests

    func testRepository_StoresAndRetrievesReport() async throws {
        let report = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 80,
            executableLines: 100
        )

        // Add report to repository
        try await repository.add(report: report)

        // Retrieve latest report
        let retrieved = try await repository.getLatestReport()

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.fileInfo.application, "TestApp")

        // Verify coverage values match
        let originalCoverage = report.coverage.coverage
        let retrievedCoverage = retrieved?.coverage.coverage ?? 0.0
        XCTAssertEqual(originalCoverage, retrievedCoverage, accuracy: 0.01)
    }

    func testRepository_GetLatestReport_ReturnsNewest() async throws {
        let oldReport = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 70,
            executableLines: 100,
            timestamp: Date(timeIntervalSince1970: 1000)
        )

        let newReport = Self.makeCoverageMetaReport(
            appName: "TestApp",
            coveredLines: 85,
            executableLines: 100,
            timestamp: Date(timeIntervalSince1970: 2000)
        )

        try await repository.add(report: oldReport)
        try await repository.add(report: newReport)

        let retrieved = try await repository.getLatestReport()

        XCTAssertNotNil(retrieved)

        // Should retrieve the newer report (85% coverage)
        let retrievedCoverage = (retrieved?.coverage.coverage ?? 0.0) * 100.0
        XCTAssertEqual(retrievedCoverage, 85.0, accuracy: 0.1)
    }

    func testRepository_GetLatestReport_ReturnsNilWhenEmpty() async throws {
        let retrieved = try await repository.getLatestReport()
        XCTAssertNil(retrieved)
    }

    // MARK: - Edge Cases

    func testThresholdSettings_HandlesVeryLargeValues() throws {
        let values = [
            "min_coverage": "99.9999",
            "max_drop": "0.0001"
        ]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNotNil(settings.minCoverage)
        XCTAssertEqual(settings.minCoverage!, 99.9999, accuracy: 0.00001)
        XCTAssertNotNil(settings.maxDrop)
        XCTAssertEqual(settings.maxDrop!, 0.0001, accuracy: 0.00001)
    }

    func testThresholdSettings_HandlesZeroValues() throws {
        let values = [
            "min_coverage": "0.0",
            "max_drop": "0.0"
        ]
        let settings = try ThresholdSettings(values: values)

        XCTAssertNotNil(settings.minCoverage)
        XCTAssertEqual(settings.minCoverage!, 0.0, accuracy: 0.01)
        XCTAssertNotNil(settings.maxDrop)
        XCTAssertEqual(settings.maxDrop!, 0.0, accuracy: 0.01)
    }

    func testValidator_EdgeCase_ExactlyAtThreshold() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 75, executableLines: 100)
        let validator = ThresholdValidator()

        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        // Should pass when exactly at threshold
        XCTAssertTrue(result.isPassing)
    }

    func testValidator_EdgeCase_VerySmallDifference() throws {
        // Coverage is 74.99%
        let coverage = Self.makeCoverageReport(coveredLines: 7499, executableLines: 10000)
        let validator = ThresholdValidator()

        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        // Should fail even with very small difference
        XCTAssertFalse(result.isPassing)
    }
}

// MARK: - Test Helpers

extension CoverageCommandThresholdTests {
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
}
