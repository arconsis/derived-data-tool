//
//  Config+Thresholds.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation

public extension Config {
    struct Thresholds: Codable, CustomStringConvertible {
        public let global: Double?
        public let targets: [String: Double]?

        public var description: String {
            return """
            Global: \(global?.description ?? "N/A")
            Targets: \(targets?.description ?? "N/A")
            """
        }
    }

    enum ThresholdValidationWarning: CustomStringConvertible {
        case invalidGlobalThreshold(Double)
        case invalidTargetThreshold(String, Double)
        case redundantTargetThreshold(String, Double)
        case emptyThresholdsConfiguration

        public var description: String {
            switch self {
            case .invalidGlobalThreshold(let value):
                return "Global threshold \(value) is outside valid range (0-100)"
            case .invalidTargetThreshold(let target, let value):
                return "Threshold for target '\(target)' (\(value)) is outside valid range (0-100)"
            case .redundantTargetThreshold(let target, let value):
                return "Target '\(target)' has threshold \(value) which equals the global threshold (redundant configuration)"
            case .emptyThresholdsConfiguration:
                return "Thresholds configuration exists but contains no global or target-specific thresholds"
            }
        }
    }

    /// Validates threshold configuration and returns any warnings
    /// - Returns: Array of validation warnings (empty if no issues found)
    func validateThresholds() -> [ThresholdValidationWarning] {
        guard let thresholds = self.thresholds else {
            return [] // No thresholds configured, nothing to validate
        }

        var warnings: [ThresholdValidationWarning] = []

        // Check if configuration is completely empty
        if thresholds.global == nil && (thresholds.targets == nil || thresholds.targets?.isEmpty == true) {
            warnings.append(.emptyThresholdsConfiguration)
            return warnings
        }

        // Validate global threshold range
        if let global = thresholds.global {
            if global < 0 || global > 100 {
                warnings.append(.invalidGlobalThreshold(global))
            }
        }

        // Validate target-specific thresholds
        if let targets = thresholds.targets {
            for (targetName, threshold) in targets {
                // Check value range
                if threshold < 0 || threshold > 100 {
                    warnings.append(.invalidTargetThreshold(targetName, threshold))
                }

                // Check for redundancy with global threshold
                if let global = thresholds.global, threshold == global {
                    warnings.append(.redundantTargetThreshold(targetName, threshold))
                }
            }
        }

        return warnings
    }
}
