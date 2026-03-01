//
//  GitHubActionsAnnotations.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
import Shared

/// Formats threshold validation results as GitHub Actions workflow command annotations
/// GitHub Actions annotation format: ::error file={name},line={line}::{message}
/// Reference: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message
public struct GitHubActionsAnnotations {
    public init() {}

    /// Formats validation results as GitHub Actions error annotations
    /// - Parameter results: Array of threshold validation results
    /// - Returns: String containing formatted annotations, one per line
    public func format(results: [ThresholdValidationResult]) -> String {
        let failedResults = results.filter { !$0.passed }

        guard !failedResults.isEmpty else {
            return ""
        }

        let annotations = failedResults.map { result in
            formatAnnotation(for: result)
        }

        return annotations.joined(separator: "\n")
    }

    /// Formats a single validation result as a GitHub Actions error annotation
    /// - Parameter result: The threshold validation result
    /// - Returns: Formatted annotation string
    private func formatAnnotation(for result: ThresholdValidationResult) -> String {
        let actualPercentage = String(format: "%.2f", result.actualCoveragePercentage)
        let requiredPercentage = String(format: "%.2f", result.requiredThreshold)
        let message = "Coverage below threshold (\(actualPercentage)% < \(requiredPercentage)%)"

        // GitHub Actions annotations use file= parameter
        // For targets, we use the target name as the file reference
        return "::error file=\(result.targetName),line=1::\(message)"
    }
}
