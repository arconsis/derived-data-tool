//
//  ThresholdValidationTests.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation
@testable import Shared
import XCTest

final class ThresholdValidationTests: XCTestCase {
    func testValidThresholdsNoWarnings() throws {
        // Valid configuration with both global and target-specific thresholds
        let config = Config(
            thresholds: Config.Thresholds(
                global: 80.0,
                targets: [
                    "TargetA": 90.0,
                    "TargetB": 70.0
                ]
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 0, "Valid configuration should produce no warnings")
    }

    func testInvalidGlobalThreshold() throws {
        // Global threshold outside valid range
        let config = Config(
            thresholds: Config.Thresholds(
                global: 150.0,
                targets: nil
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 1, "Should have exactly one warning for invalid global threshold")

        if case .invalidGlobalThreshold(let value) = warnings.first {
            XCTAssertEqual(value, 150.0)
        } else {
            XCTFail("Expected invalidGlobalThreshold warning")
        }
    }

    func testInvalidTargetThreshold() throws {
        // Target threshold outside valid range
        let config = Config(
            thresholds: Config.Thresholds(
                global: 80.0,
                targets: [
                    "TargetA": -10.0,
                    "TargetB": 200.0
                ]
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 2, "Should have two warnings for invalid target thresholds")

        let invalidTargetWarnings = warnings.filter {
            if case .invalidTargetThreshold = $0 { return true }
            return false
        }
        XCTAssertEqual(invalidTargetWarnings.count, 2)
    }

    func testRedundantTargetThreshold() throws {
        // Target threshold equals global threshold (redundant)
        let config = Config(
            thresholds: Config.Thresholds(
                global: 80.0,
                targets: [
                    "TargetA": 90.0,
                    "TargetB": 80.0  // Same as global
                ]
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 1, "Should have one warning for redundant target threshold")

        if case .redundantTargetThreshold(let target, let value) = warnings.first {
            XCTAssertEqual(target, "TargetB")
            XCTAssertEqual(value, 80.0)
        } else {
            XCTFail("Expected redundantTargetThreshold warning")
        }
    }

    func testEmptyThresholdsConfiguration() throws {
        // Thresholds section exists but is empty
        let config = Config(
            thresholds: Config.Thresholds(
                global: nil,
                targets: nil
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 1, "Should have one warning for empty configuration")

        if case .emptyThresholdsConfiguration = warnings.first {
            // Success
        } else {
            XCTFail("Expected emptyThresholdsConfiguration warning")
        }
    }

    func testEmptyTargetsMapIsNotWarning() throws {
        // Empty targets map with global threshold is valid
        let config = Config(
            thresholds: Config.Thresholds(
                global: 80.0,
                targets: [:]
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 0, "Empty targets map with global threshold should be valid")
    }

    func testNoThresholdsConfigured() throws {
        // No thresholds configured at all
        let config = Config(thresholds: nil)

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 0, "No thresholds configured should produce no warnings")
    }

    func testMultipleWarnings() throws {
        // Configuration with multiple issues
        let config = Config(
            thresholds: Config.Thresholds(
                global: 150.0,  // Invalid
                targets: [
                    "TargetA": 200.0,  // Invalid
                    "TargetB": 150.0   // Invalid + Redundant
                ]
            )
        )

        let warnings = config.validateThresholds()
        // Should have: 1 invalid global + 2 invalid targets + 1 redundant = 4 warnings
        XCTAssertEqual(warnings.count, 4, "Should have multiple warnings for multiple issues")
    }

    func testBoundaryValues() throws {
        // Test boundary values (0 and 100 are valid)
        let config = Config(
            thresholds: Config.Thresholds(
                global: 0.0,
                targets: [
                    "TargetA": 100.0,
                    "TargetB": 50.0
                ]
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 0, "Boundary values 0 and 100 should be valid")
    }

    func testNegativeAndAboveHundred() throws {
        // Test just outside boundaries
        let config = Config(
            thresholds: Config.Thresholds(
                global: -0.1,
                targets: [
                    "TargetA": 100.1
                ]
            )
        )

        let warnings = config.validateThresholds()
        XCTAssertEqual(warnings.count, 2, "Values just outside boundaries should be invalid")
    }
}
