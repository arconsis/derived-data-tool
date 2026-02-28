//
//  ThresholdTests.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation
@testable import Coverage
@testable import Shared
import XCTest

final class ThresholdTests: XCTestCase {

    // MARK: - Test Helpers

    func makeTarget(name: String, coveredLines: Int, executableLines: Int) -> Target {
        let function = Function(
            name: "testFunction",
            executableLines: executableLines,
            coveredLines: coveredLines,
            lineNumber: 1,
            executionCount: 1
        )
        let file = File(name: "test.swift", path: "/test.swift", functions: [function])
        return Target(name: name, files: [file])
    }

    func makeReport(targets: [Target]) -> CoverageReport {
        return CoverageReport(targets: targets)
    }

    // MARK: - Global Threshold Tests

    func testGlobalThresholdPassing() throws {
        // Target with 85% coverage should pass 80% threshold
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "TestTarget", coveredLines: 85, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].passed)
        XCTAssertEqual(results[0].targetName, "TestTarget")
        XCTAssertEqual(results[0].requiredThreshold, 80.0)
        XCTAssertEqual(results[0].actualCoverage, 0.85)
    }

    func testGlobalThresholdFailing() throws {
        // Target with 75% coverage should fail 80% threshold
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "TestTarget", coveredLines: 75, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].passed)
        XCTAssertEqual(results[0].targetName, "TestTarget")
        XCTAssertEqual(results[0].requiredThreshold, 80.0)
        XCTAssertEqual(results[0].actualCoverage, 0.75)
    }

    func testGlobalThresholdExactMatch() throws {
        // Target with exactly 80% coverage should pass 80% threshold
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "TestTarget", coveredLines: 80, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].passed)
        XCTAssertEqual(results[0].actualCoverage, 0.80)
    }

    // MARK: - Per-Target Threshold Tests

    func testPerTargetThresholdOverridesGlobal() throws {
        // Target-specific threshold should override global
        let thresholds = Config.Thresholds(
            global: 80.0,
            targets: ["CriticalTarget": 95.0]
        )
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "CriticalTarget", coveredLines: 90, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].passed) // 90% < 95% threshold
        XCTAssertEqual(results[0].requiredThreshold, 95.0)
    }

    func testTargetWithoutSpecificThresholdUsesGlobal() throws {
        // Target without specific threshold should use global
        let thresholds = Config.Thresholds(
            global: 80.0,
            targets: ["OtherTarget": 95.0]
        )
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "TestTarget", coveredLines: 85, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].passed)
        XCTAssertEqual(results[0].requiredThreshold, 80.0) // Uses global
    }

    func testMixedTargetThresholds() throws {
        // Multiple targets with different thresholds
        let thresholds = Config.Thresholds(
            global: 80.0,
            targets: [
                "CriticalTarget": 95.0,
                "UITarget": 70.0
            ]
        )
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "CriticalTarget", coveredLines: 96, executableLines: 100), // Pass
            makeTarget(name: "UITarget", coveredLines: 75, executableLines: 100),       // Pass
            makeTarget(name: "CommonTarget", coveredLines: 85, executableLines: 100)    // Pass (uses global 80%)
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results[0].passed) // CriticalTarget: 96% >= 95%
        XCTAssertEqual(results[0].requiredThreshold, 95.0)

        XCTAssertTrue(results[1].passed) // UITarget: 75% >= 70%
        XCTAssertEqual(results[1].requiredThreshold, 70.0)

        XCTAssertTrue(results[2].passed) // CommonTarget: 85% >= 80%
        XCTAssertEqual(results[2].requiredThreshold, 80.0)
    }

    // MARK: - Default Threshold Tests

    func testDefaultThresholdWhenNothingConfigured() throws {
        // Should use default 80% when no thresholds configured
        let thresholds = Config.Thresholds(global: nil, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "TestTarget", coveredLines: 85, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].passed)
        XCTAssertEqual(results[0].requiredThreshold, 80.0) // Default threshold
    }

    func testDefaultThresholdFailure() throws {
        // Target failing default 80% threshold
        let thresholds = Config.Thresholds(global: nil, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "TestTarget", coveredLines: 75, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].passed)
        XCTAssertEqual(results[0].requiredThreshold, 80.0)
    }

    // MARK: - Multiple Targets Tests

    func testMultipleTargetsAllPassing() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "Target1", coveredLines: 85, executableLines: 100),
            makeTarget(name: "Target2", coveredLines: 90, executableLines: 100),
            makeTarget(name: "Target3", coveredLines: 95, executableLines: 100)
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.passed })
    }

    func testMultipleTargetsSomeFailing() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "PassingTarget", coveredLines: 85, executableLines: 100),  // Pass
            makeTarget(name: "FailingTarget1", coveredLines: 75, executableLines: 100), // Fail
            makeTarget(name: "FailingTarget2", coveredLines: 60, executableLines: 100)  // Fail
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results[0].passed)
        XCTAssertFalse(results[1].passed)
        XCTAssertFalse(results[2].passed)
    }

    // MARK: - Helper Methods Tests

    func testAllTargetsPassedHelperAllPassing() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "Target1", coveredLines: 85, executableLines: 100),
            makeTarget(name: "Target2", coveredLines: 90, executableLines: 100)
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)

        XCTAssertTrue(validator.allTargetsPassed(results))
    }

    func testAllTargetsPassedHelperSomeFailing() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "PassingTarget", coveredLines: 85, executableLines: 100),
            makeTarget(name: "FailingTarget", coveredLines: 75, executableLines: 100)
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)

        XCTAssertFalse(validator.allTargetsPassed(results))
    }

    func testFailedTargetsHelper() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "PassingTarget", coveredLines: 85, executableLines: 100),
            makeTarget(name: "FailingTarget1", coveredLines: 75, executableLines: 100),
            makeTarget(name: "FailingTarget2", coveredLines: 60, executableLines: 100)
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)
        let failedResults = validator.failedTargets(results)

        XCTAssertEqual(failedResults.count, 2)
        XCTAssertEqual(failedResults[0].targetName, "FailingTarget1")
        XCTAssertEqual(failedResults[1].targetName, "FailingTarget2")
    }

    func testFailedTargetsHelperNoneFailure() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let targets = [
            makeTarget(name: "Target1", coveredLines: 85, executableLines: 100),
            makeTarget(name: "Target2", coveredLines: 90, executableLines: 100)
        ]
        let report = makeReport(targets: targets)

        let results = validator.validate(report: report)
        let failedResults = validator.failedTargets(results)

        XCTAssertEqual(failedResults.count, 0)
    }

    // MARK: - Edge Cases

    func testZeroCoverageTarget() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "UncoveredTarget", coveredLines: 0, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].passed)
        XCTAssertEqual(results[0].actualCoverage, 0.0)
    }

    func testFullCoverageTarget() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let target = makeTarget(name: "FullyCoveredTarget", coveredLines: 100, executableLines: 100)
        let report = makeReport(targets: [target])

        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].passed)
        XCTAssertEqual(results[0].actualCoverage, 1.0)
    }

    func testEmptyReport() throws {
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: false)

        let report = makeReport(targets: [])
        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 0)
        XCTAssertTrue(validator.allTargetsPassed(results)) // Vacuous truth - all zero targets passed
    }

    // MARK: - Verbose Mode Tests

    func testVerboseModeEnabled() throws {
        // Test that verbose mode can be enabled (actual logging would require mocking the logger)
        let thresholds = Config.Thresholds(global: 80.0, targets: nil)
        let validator = ThresholdValidator(thresholds: thresholds, verbose: true)

        let target = makeTarget(name: "TestTarget", coveredLines: 85, executableLines: 100)
        let report = makeReport(targets: [target])

        // Should not crash and should still produce valid results
        let results = validator.validate(report: report)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].passed)
    }

    // MARK: - ThresholdValidationResult Tests

    func testActualCoveragePercentageConversion() throws {
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.856,
            requiredThreshold: 80.0,
            passed: true
        )

        XCTAssertEqual(result.actualCoveragePercentage, 85.6)
    }

    func testThresholdValidationResultInitialization() throws {
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.75,
            requiredThreshold: 80.0,
            passed: false
        )

        XCTAssertEqual(result.targetName, "TestTarget")
        XCTAssertEqual(result.actualCoverage, 0.75)
        XCTAssertEqual(result.requiredThreshold, 80.0)
        XCTAssertFalse(result.passed)
    }
}
