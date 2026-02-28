//
//  ThresholdValidator.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import DependencyInjection
import Foundation
import Shared

/// Validates coverage reports against configured thresholds
class ThresholdValidator {
    private let thresholds: Config.Thresholds
    private let verbose: Bool

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    init(thresholds: Config.Thresholds, verbose: Bool = false) {
        self.thresholds = thresholds
        self.verbose = verbose
    }

    /// Validates all targets in a coverage report against their configured thresholds
    /// - Parameter report: The coverage report to validate
    /// - Returns: Array of validation results, one per target
    func validate(report: CoverageReport) -> [ThresholdValidationResult] {
        logger.log("Validating coverage thresholds for \(report.targets.count) targets")

        let results = report.targets.map { target in
            validateTarget(target)
        }

        let passed = results.filter(\.passed).count
        let failed = results.count - passed

        if verbose {
            logger.log("Threshold validation complete: \(passed) passed, \(failed) failed")
        }

        return results
    }

    /// Validates a single target against its threshold
    /// - Parameter target: The target to validate
    /// - Returns: Validation result for this target
    private func validateTarget(_ target: Target) -> ThresholdValidationResult {
        let threshold = thresholdForTarget(target.name)
        let thresholdDecimal = threshold / 100.0
        let passed = target.coverage >= thresholdDecimal

        let result = ThresholdValidationResult(
            targetName: target.name,
            actualCoverage: target.coverage,
            requiredThreshold: threshold,
            passed: passed
        )

        if verbose {
            let status = passed ? "✓" : "✗"
            logger.log("\(status) \(target.name): \(target.printableCoverage)% (threshold: \(String(format: "%.2f", threshold))%)")
        }

        return result
    }

    /// Determines the threshold for a specific target
    /// - Parameter targetName: Name of the target
    /// - Returns: Coverage threshold percentage (e.g., 80.0 for 80%)
    private func thresholdForTarget(_ targetName: String) -> Double {
        // Check if there's a specific threshold for this target
        if let targetThreshold = thresholds.targets?[targetName] {
            return targetThreshold
        }

        // Fall back to global threshold
        return thresholds.global ?? 80.0 // Default to 80% if nothing is configured
    }

    /// Checks if all targets passed their thresholds
    /// - Parameter results: Array of validation results
    /// - Returns: True if all targets passed
    func allTargetsPassed(_ results: [ThresholdValidationResult]) -> Bool {
        results.allSatisfy(\.passed)
    }

    /// Gets the list of failed targets
    /// - Parameter results: Array of validation results
    /// - Returns: Array of failed results
    func failedTargets(_ results: [ThresholdValidationResult]) -> [ThresholdValidationResult] {
        results.filter { !$0.passed }
    }
}
