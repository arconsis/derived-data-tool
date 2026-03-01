//
//  GitHubActionsAnnotationExporter.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import DependencyInjection
import Foundation
import Shared

/// Exports GitHub Actions workflow annotations for coverage threshold violations
/// Produces ::warning and ::error commands that appear inline in GitHub PR UI
///
/// GitHub Actions Annotation Format:
/// - ::error file={name},line={line}::{message}
/// - ::warning file={name},line={line}::{message}
///
/// Discussion: File path and line number resolution will be added in subtask-2-3.
/// For now, annotations use the target name and line=1 as placeholders.
public class GitHubActionsAnnotationExporter {
    @Injected(\.logger) private var logger: Loggerable

    /// GitHub Actions limits annotations to 10 per workflow run
    /// https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message
    private static let maxAnnotations = 10

    public init() {}

    /// Generates GitHub Actions annotations from threshold validation results
    /// - Parameter results: Array of validation results from ThresholdValidator
    /// - Returns: String containing formatted annotations ready for stdout
    public func formatAnnotations(from results: [ThresholdValidationResult]) -> String {
        var annotations: [String] = []

        // Filter failed results and apply GitHub Actions annotation limit
        let failedResults = results.filter { !$0.passed }
        let limitedResults = Array(failedResults.prefix(Self.maxAnnotations))

        for result in limitedResults {
            let annotation = createAnnotation(for: result)
            annotations.append(annotation)
        }

        // If we hit the limit, add a warning annotation about truncated results
        if failedResults.count > Self.maxAnnotations {
            let truncatedCount = failedResults.count - Self.maxAnnotations
            let warningMessage = "⚠️ \(truncatedCount) additional threshold failure(s) not shown (GitHub Actions limit: \(Self.maxAnnotations) annotations)"
            annotations.append("::warning::\(warningMessage)")
            logger.log("Truncated \(truncatedCount) annotations due to GitHub Actions limit of \(Self.maxAnnotations)")
        }

        if !annotations.isEmpty {
            logger.log("Generated \(annotations.count) GitHub Actions annotations")
        }

        return annotations.joined(separator: "\n")
    }

    /// Creates a single annotation for a failed threshold validation
    /// - Parameter result: The validation result
    /// - Returns: Formatted annotation string
    private func createAnnotation(for result: ThresholdValidationResult) -> String {
        let message = formatMessage(for: result)

        // For now, use line=1 as placeholder (file path resolution comes in subtask-2-3)
        // Targets that fail thresholds get ::error annotations
        let annotationType = "error"
        let fileName = result.targetName // Will be replaced with actual file path in subtask-2-3
        let lineNumber = 1

        return "::\(annotationType) file=\(fileName),line=\(lineNumber)::\(message)"
    }

    /// Formats the annotation message with coverage details
    /// - Parameter result: The validation result
    /// - Returns: Human-readable message
    private func formatMessage(for result: ThresholdValidationResult) -> String {
        let actual = String(format: "%.2f", result.actualCoveragePercentage)
        let required = String(format: "%.2f", result.requiredThreshold)

        return "Coverage \(actual)% is below threshold \(required)% for target '\(result.targetName)'"
    }
}
