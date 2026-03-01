//
//  ThresholdValidatorTests.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class ThresholdValidatorTests: XCTestCase {
    var validator: ThresholdValidator!

    override func setUp() {
        super.setUp()
        validator = ThresholdValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - validateAbsolute Tests

    func testValidateAbsolute_PassesWhenCoverageExceedsThreshold() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        XCTAssertTrue(result.isPassing)
        if case .fail = result {
            XCTFail("Expected pass result")
        }
    }

    func testValidateAbsolute_PassesWhenCoverageMeetsThreshold() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 75, executableLines: 100)
        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidateAbsolute_FailsWhenCoverageBelowThreshold() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        XCTAssertFalse(result.isPassing)
        if case .fail(let reason, let details) = result {
            XCTAssertTrue(reason.contains("70.00"))
            XCTAssertTrue(reason.contains("75.00"))
            XCTAssertEqual(details.expected, 75.0, accuracy: 0.01)
            XCTAssertEqual(details.actual, 70.0, accuracy: 0.01)
            XCTAssertNil(details.targetName)
        } else {
            XCTFail("Expected fail result")
        }
    }

    func testValidateAbsolute_HandlesZeroCoverage() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 0, executableLines: 100)
        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 50.0)

        XCTAssertFalse(result.isPassing)
        if case .fail(let reason, let details) = result {
            XCTAssertTrue(reason.contains("0.00"))
            XCTAssertEqual(details.actual, 0.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result")
        }
    }

    func testValidateAbsolute_HandlesFullCoverage() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 100, executableLines: 100)
        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 95.0)

        XCTAssertTrue(result.isPassing)
    }

    // MARK: - validateRelative Tests

    func testValidateRelative_PassesWhenNoPreviousReport() throws {
        let current = Self.makeCoverageReport(coveredLines: 50, executableLines: 100)
        let result = validator.validateRelative(current: current, previous: nil, maxDrop: 5.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidateRelative_PassesWhenCoverageImproves() throws {
        let previous = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidateRelative_PassesWhenDropWithinLimit() throws {
        let previous = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 77, executableLines: 100)
        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidateRelative_PassesWhenDropExactlyAtLimit() throws {
        let previous = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 75, executableLines: 100)
        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertTrue(result.isPassing)
    }

    func testValidateRelative_FailsWhenDropExceedsLimit() throws {
        let previous = Self.makeCoverageReport(coveredLines: 80, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 70, executableLines: 100)
        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertFalse(result.isPassing)
        if case .fail(let reason, let details) = result {
            XCTAssertTrue(reason.contains("10.00"))
            XCTAssertTrue(reason.contains("5.00"))
            XCTAssertEqual(details.expected, 5.0, accuracy: 0.01)
            XCTAssertEqual(details.actual, 10.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result")
        }
    }

    func testValidateRelative_HandlesSignificantDrop() throws {
        let previous = Self.makeCoverageReport(coveredLines: 90, executableLines: 100)
        let current = Self.makeCoverageReport(coveredLines: 50, executableLines: 100)
        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 5.0)

        XCTAssertFalse(result.isPassing)
        if case .fail(_, let details) = result {
            XCTAssertEqual(details.actual, 40.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result")
        }
    }

    // MARK: - validatePerTarget Tests

    func testValidatePerTarget_PassesForAllTargets() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 80, 100),
            ("TargetB", 90, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 70.0),
            "TargetB": ThresholdConfig(minCoverage: 85.0)
        ]

        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.isPassing })
    }

    func testValidatePerTarget_FailsForOneTarget() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 80, 100),
            ("TargetB", 60, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 70.0),
            "TargetB": ThresholdConfig(minCoverage: 75.0)
        ]

        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 2)

        // Verify one passes and one fails (order not guaranteed)
        let passingCount = results.filter { $0.isPassing }.count
        let failingCount = results.filter { !$0.isPassing }.count

        XCTAssertEqual(passingCount, 1)
        XCTAssertEqual(failingCount, 1)

        // Find and verify the failing result
        let failingResult = results.first { !$0.isPassing }
        XCTAssertNotNil(failingResult)

        if case .fail(let reason, let details) = failingResult! {
            XCTAssertTrue(reason.contains("TargetB"))
            XCTAssertTrue(reason.contains("60.00"))
            XCTAssertTrue(reason.contains("75.00"))
            XCTAssertEqual(details.targetName, "TargetB")
            XCTAssertEqual(details.expected, 75.0, accuracy: 0.01)
            XCTAssertEqual(details.actual, 60.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result for TargetB")
        }
    }

    func testValidatePerTarget_SkipsMissingTargets() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 80, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 70.0),
            "TargetB": ThresholdConfig(minCoverage: 75.0),
            "TargetC": ThresholdConfig(minCoverage: 80.0)
        ]

        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].isPassing)
    }

    func testValidatePerTarget_HandlesEmptyThresholds() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 80, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [:]

        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 0)
    }

    func testValidatePerTarget_HandlesNilMinCoverage() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 50, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: nil)
        ]

        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 0)
    }

    func testValidatePerTarget_MultipleTargetsSomePass() throws {
        let coverage = Self.makeCoverageReportWithTargets([
            ("TargetA", 95, 100),
            ("TargetB", 50, 100),
            ("TargetC", 75, 100)
        ])

        let thresholds: [String: ThresholdConfig] = [
            "TargetA": ThresholdConfig(minCoverage: 90.0),
            "TargetB": ThresholdConfig(minCoverage: 70.0),
            "TargetC": ThresholdConfig(minCoverage: 75.0)
        ]

        let results = validator.validatePerTarget(coverage: coverage, thresholds: thresholds)

        XCTAssertEqual(results.count, 3)

        // Count passing and failing results (order is not guaranteed from dictionary)
        let passingCount = results.filter { $0.isPassing }.count
        let failingCount = results.filter { !$0.isPassing }.count

        XCTAssertEqual(passingCount, 2)
        XCTAssertEqual(failingCount, 1)

        // Verify the failing result is for TargetB
        let failingResult = results.first { !$0.isPassing }
        XCTAssertNotNil(failingResult)
        if case .fail(_, let details) = failingResult! {
            XCTAssertEqual(details.targetName, "TargetB")
            XCTAssertEqual(details.expected, 70.0, accuracy: 0.01)
            XCTAssertEqual(details.actual, 50.0, accuracy: 0.01)
        } else {
            XCTFail("Expected fail result for TargetB")
        }
    }

    // MARK: - ThresholdResult Tests

    func testThresholdResult_IsPassingForPassCase() throws {
        let result: ThresholdResult = .pass
        XCTAssertTrue(result.isPassing)
    }

    func testThresholdResult_IsPassingForFailCase() throws {
        let details = ThresholdFailureDetails(expected: 75.0, actual: 50.0)
        let result: ThresholdResult = .fail(reason: "Test failure", details: details)
        XCTAssertFalse(result.isPassing)
    }

    // MARK: - ThresholdValidatorError Tests

    func testThresholdValidatorError_PrintsHelp() throws {
        let details = ThresholdFailureDetails(expected: 75.0, actual: 50.0)
        let results: [ThresholdResult] = [.fail(reason: "Test failure", details: details)]
        let error = ThresholdValidator.ThresholdValidatorError.validationFailed(results: results)

        XCTAssertFalse(error.printsHelp)
    }

    func testThresholdValidatorError_ErrorDescription() throws {
        let details1 = ThresholdFailureDetails(expected: 75.0, actual: 50.0)
        let details2 = ThresholdFailureDetails(expected: 80.0, actual: 60.0)
        let results: [ThresholdResult] = [
            .fail(reason: "First failure", details: details1),
            .pass,
            .fail(reason: "Second failure", details: details2)
        ]
        let error = ThresholdValidator.ThresholdValidatorError.validationFailed(results: results)

        let description = error.errorDescription
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("First failure"))
        XCTAssertTrue(description!.contains("Second failure"))
        XCTAssertFalse(description!.contains(".pass"))
    }

    func testThresholdValidatorError_EmptyResultsDescription() throws {
        let error = ThresholdValidator.ThresholdValidatorError.validationFailed(results: [])

        let description = error.errorDescription
        XCTAssertNotNil(description)
        XCTAssertEqual(description, "")
    }

    // MARK: - Edge Cases

    func testValidateAbsolute_VerySmallDifferences() throws {
        let coverage = Self.makeCoverageReport(coveredLines: 7499, executableLines: 10000)
        let result = validator.validateAbsolute(coverage: coverage, minCoverage: 75.0)

        XCTAssertFalse(result.isPassing)
    }

    func testValidateRelative_VerySmallDrop() throws {
        let previous = Self.makeCoverageReport(coveredLines: 7501, executableLines: 10000)
        let current = Self.makeCoverageReport(coveredLines: 7500, executableLines: 10000)
        let result = validator.validateRelative(current: current, previous: previous, maxDrop: 0.1)

        XCTAssertTrue(result.isPassing)
    }
}

// MARK: - Test Helpers

extension ThresholdValidatorTests {
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
}
