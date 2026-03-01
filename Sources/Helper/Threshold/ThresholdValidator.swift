//
//  ThresholdValidator.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation
import Shared

public enum ThresholdResult: Sendable {
    case pass
    case fail(reason: String, details: ThresholdFailureDetails)

    public var isPassing: Bool {
        if case .pass = self {
            return true
        }
        return false
    }
}

public struct ThresholdFailureDetails: Sendable {
    public let expected: Double
    public let actual: Double
    public let targetName: String?

    public init(expected: Double, actual: Double, targetName: String? = nil) {
        self.expected = expected
        self.actual = actual
        self.targetName = targetName
    }
}

public class ThresholdValidator {
    public init() {}

    /// Validates that coverage meets or exceeds the minimum absolute threshold
    /// - Parameters:
    ///   - coverage: The coverage report to validate
    ///   - minCoverage: Minimum coverage percentage (0-100)
    /// - Returns: ThresholdResult indicating pass or fail
    public func validateAbsolute(coverage: CoverageReport, minCoverage: Double) -> ThresholdResult {
        let currentCoveragePercent = coverage.coverage * 100.0

        guard currentCoveragePercent >= minCoverage else {
            let reason = String(format: "Coverage %.2f%% is below minimum threshold %.2f%%",
                              currentCoveragePercent, minCoverage)
            let details = ThresholdFailureDetails(expected: minCoverage,
                                                 actual: currentCoveragePercent)
            return .fail(reason: reason, details: details)
        }

        return .pass
    }

    /// Validates that coverage has not dropped more than the maximum allowed amount
    /// - Parameters:
    ///   - current: The current coverage report
    ///   - previous: The previous coverage report (optional)
    ///   - maxDrop: Maximum allowed coverage drop in percentage points (0-100)
    /// - Returns: ThresholdResult indicating pass or fail
    public func validateRelative(current: CoverageReport,
                                previous: CoverageReport?,
                                maxDrop: Double) -> ThresholdResult {
        guard let previous = previous else {
            // No previous report to compare against, so we pass
            return .pass
        }

        let currentCoveragePercent = current.coverage * 100.0
        let previousCoveragePercent = previous.coverage * 100.0
        let actualDrop = previousCoveragePercent - currentCoveragePercent

        guard actualDrop <= maxDrop else {
            let reason = String(format: "Coverage dropped %.2f%%, exceeding maximum allowed drop of %.2f%%",
                              actualDrop, maxDrop)
            let details = ThresholdFailureDetails(expected: maxDrop, actual: actualDrop)
            return .fail(reason: reason, details: details)
        }

        return .pass
    }

    /// Validates that each target meets its configured threshold
    /// - Parameters:
    ///   - coverage: The coverage report to validate
    ///   - thresholds: Dictionary mapping target names to their threshold configurations
    /// - Returns: Array of ThresholdResults, one per target with configured thresholds
    public func validatePerTarget(coverage: CoverageReport,
                                 thresholds: [String: ThresholdConfig]) -> [ThresholdResult] {
        var results: [ThresholdResult] = []

        for (targetName, config) in thresholds {
            guard let target = coverage.targets.first(where: { $0.name == targetName }) else {
                // Target not found in report, skip validation
                continue
            }

            let targetCoveragePercent = target.coverage * 100.0

            // Validate minimum coverage for this target if configured
            if let minCoverage = config.minCoverage {
                if targetCoveragePercent < minCoverage {
                    let reason = String(format: "Target '%@' coverage %.2f%% is below minimum threshold %.2f%%",
                                      targetName, targetCoveragePercent, minCoverage)
                    let details = ThresholdFailureDetails(expected: minCoverage,
                                                         actual: targetCoveragePercent,
                                                         targetName: targetName)
                    results.append(.fail(reason: reason, details: details))
                } else {
                    results.append(.pass)
                }
            }
        }

        return results
    }
}

public extension ThresholdValidator {
    enum ThresholdValidatorError: Errorable {
        case validationFailed(results: [ThresholdResult])

        public var printsHelp: Bool { false }

        public var errorDescription: String? {
            switch self {
            case .validationFailed(let results):
                let failures = results.compactMap { result -> String? in
                    if case .fail(let reason, _) = result {
                        return reason
                    }
                    return nil
                }
                return failures.joined(separator: "\n")
            }
        }
    }
}
