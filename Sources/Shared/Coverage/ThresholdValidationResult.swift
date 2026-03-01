//
//  ThresholdValidationResult.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation

/// Result of validating a single target against its threshold
public struct ThresholdValidationResult {
    public let targetName: String
    public let actualCoverage: Double
    public let requiredThreshold: Double
    public let passed: Bool
    public let filePath: String?

    public init(targetName: String, actualCoverage: Double, requiredThreshold: Double, passed: Bool, filePath: String? = nil) {
        self.targetName = targetName
        self.actualCoverage = actualCoverage
        self.requiredThreshold = requiredThreshold
        self.passed = passed
        self.filePath = filePath
    }

    public var actualCoveragePercentage: Double {
        actualCoverage * 100.0
    }
}
