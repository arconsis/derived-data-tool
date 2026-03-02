//
//  PRCommentFormatter.swift
//
//
//  Created by auto-claude on 02.03.26.
//

import DependencyInjection
import Foundation
import Shared

public class PRCommentFormatter {
    @Injected(\.logger) private var logger: Loggerable

    /// Unique marker to identify comments created by this tool
    private let commentMarker = "<!-- xcrtool-coverage-comment -->"

    public init() {}

    /// Formats a complete PR comment with coverage information
    /// - Parameters:
    ///   - current: The current coverage report
    ///   - previous: The previous coverage report (optional, for comparison)
    /// - Returns: Formatted markdown string for the PR comment
    public func format(current: CoverageMetaReport, previous: CoverageMetaReport? = nil) -> String {
        var content = commentMarker + "\n"
        content += formatCoverageSummary(current: current, previous: previous)
        content += "\n"
        content += formatTopChangedFiles(current: current, previous: previous, amount: 5)
        content += formatNewUntestedFiles(current: current, previous: previous)
        return content
    }

    /// Returns the marker used to identify comments created by this tool
    public func marker() -> String {
        return commentMarker
    }

    // MARK: - Private Methods

    private func formatCoverageSummary(current: CoverageMetaReport, previous: CoverageMetaReport?) -> String {
        var result = "## 📊 Coverage Report\n\n"

        let currentCoverage = current.coverage.coverage * 100.0
        let currentPercentage = String(format: "%.2f", currentCoverage)

        // Overall coverage section
        result += "**Overall Coverage:** `\(currentPercentage)%`"

        // Add comparison if previous report is available
        if let previous = previous {
            let previousCoverage = previous.coverage.coverage * 100.0
            let difference = currentCoverage - previousCoverage
            let differenceStr = formatDifference(difference)
            let emoji = coverageEmoji(for: difference)

            result += " (\(differenceStr)) \(emoji)\n\n"
        } else {
            result += "\n\n"
        }

        // Coverage details table
        result += "| Metric | Value |\n"
        result += "| :--- | :---: |\n"
        result += "| Executable Lines | \(current.coverage.executableLines) |\n"
        result += "| Covered Lines | \(current.coverage.coveredLines) |\n"

        if let previous = previous {
            let lineDiff = current.coverage.coveredLines - previous.coverage.coveredLines
            let lineDiffStr = lineDiff > 0 ? "+\(lineDiff)" : "\(lineDiff)"
            result += "| Lines Changed | \(lineDiffStr) |\n"
        }

        result += "\n"

        return result
    }

    private func formatTopChangedFiles(current: CoverageMetaReport, previous: CoverageMetaReport?, amount: Int) -> String {
        // If no previous report, skip this section
        guard let previous = previous else {
            return ""
        }

        // Build a map of file path to coverage for quick lookup
        var previousFileMap: [String: Double] = [:]
        for target in previous.coverage.targets {
            for file in target.files {
                previousFileMap[file.path] = file.coverage
            }
        }

        // Calculate coverage changes for all files
        struct FileChange {
            let name: String
            let path: String
            let currentCoverage: Double
            let previousCoverage: Double
            let difference: Double
        }

        var changes: [FileChange] = []
        for target in current.coverage.targets {
            for file in target.files {
                if let prevCoverage = previousFileMap[file.path] {
                    let diff = file.coverage - prevCoverage
                    // Only include files with actual coverage changes
                    if abs(diff) > 0.0001 {
                        changes.append(FileChange(
                            name: file.name,
                            path: file.path,
                            currentCoverage: file.coverage,
                            previousCoverage: prevCoverage,
                            difference: diff
                        ))
                    }
                }
            }
        }

        // Sort by absolute difference (largest changes first)
        changes.sort { abs($0.difference) > abs($1.difference) }

        // Take top N
        let topChanges = Array(changes.prefix(amount))

        // If no changes, don't show the section
        guard !topChanges.isEmpty else {
            return ""
        }

        // Format as markdown table
        var result = "## 📈 Top Changed Files\n\n"
        result += "| File | Coverage | Change |\n"
        result += "| :--- | :---: | :---: |\n"

        for change in topChanges {
            let currentPercentage = String(format: "%.2f%%", change.currentCoverage * 100.0)
            let diffPercentage = formatDifference(change.difference * 100.0)
            let emoji = coverageEmoji(for: change.difference * 100.0)

            result += "| `\(change.name)` | \(currentPercentage) | \(diffPercentage) \(emoji) |\n"
        }

        result += "\n"

        return result
    }

    private func formatNewUntestedFiles(current: CoverageMetaReport, previous: CoverageMetaReport?) -> String {
        // If no previous report, skip this section
        guard let previous = previous else {
            return ""
        }

        // Build a set of file paths from previous report for quick lookup
        var previousFilePaths = Set<String>()
        for target in previous.coverage.targets {
            for file in target.files {
                previousFilePaths.insert(file.path)
            }
        }

        // Find new files with 0% or very low coverage
        struct UntestedFile {
            let name: String
            let path: String
            let executableLines: Int
        }

        var untestedFiles: [UntestedFile] = []
        for target in current.coverage.targets {
            for file in target.files {
                // Check if file is new (not in previous report)
                if !previousFilePaths.contains(file.path) {
                    // Check if file has 0% coverage (no covered lines but has executable lines)
                    if file.executableLines > 0 && file.coveredLines == 0 {
                        untestedFiles.append(UntestedFile(
                            name: file.name,
                            path: file.path,
                            executableLines: file.executableLines
                        ))
                    }
                }
            }
        }

        // If no untested files, don't show the section
        guard !untestedFiles.isEmpty else {
            return ""
        }

        // Sort by number of executable lines (descending - most concerning first)
        untestedFiles.sort { $0.executableLines > $1.executableLines }

        // Format as markdown table
        var result = "## ⚠️ New Untested Files\n\n"
        result += "| File | Executable Lines |\n"
        result += "| :--- | :---: |\n"

        for file in untestedFiles {
            result += "| `\(file.name)` | \(file.executableLines) |\n"
        }

        result += "\n"

        return result
    }

    private func formatDifference(_ difference: Double) -> String {
        let formatted = String(format: "%.2f", abs(difference))
        if difference > 0 {
            return "+\(formatted)%"
        } else if difference < 0 {
            return "-\(formatted)%"
        } else {
            return "±\(formatted)%"
        }
    }

    private func coverageEmoji(for difference: Double) -> String {
        if difference > 0.5 {
            return "🎉"
        } else if difference > 0 {
            return "✅"
        } else if difference < -0.5 {
            return "⚠️"
        } else if difference < 0 {
            return "📉"
        } else {
            return "➡️"
        }
    }
}
