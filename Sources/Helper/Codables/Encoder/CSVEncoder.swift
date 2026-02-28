//
//  CSVEncoder.swift
//
//
//  Created by Moritz Ellerbrock on 13.06.23.
//

import Foundation
import Shared

public enum CSVEncoderType {
    case header(meta: CoverageMetaReport)
    case detailed(report: CoverageReport)
    case topRanked(amount: Int, report: CoverageReport)
    case lastRanked(amount: Int, report: CoverageReport)
    case uncovered(report: CoverageReport)
    case compare(current: CoverageReport, previous: CoverageReport?)
}

extension CSVEncoderType: CoverageReportEncoding {
    var title: String {
        switch self {
        case .header:
            return "Coverage Report"
        case .detailed:
            return "All Target Ranked"
        case let .topRanked(amount, _):
            return "TOP \(amount)"
        case let .lastRanked(amount, _):
            return "Last \(amount)"
        case .uncovered:
            return "UNCOVERED TARGETS"
        case .compare:
            return "Changes"
        }
    }

    public func encode() -> String {
        switch self {
        case let .detailed(report):
            let relevantReports = report.targets
                .sorted(by: { $0.coverage > $1.coverage })

            return encodeCoverageDetailed(relevantReports)

        case let .topRanked(amount, report):
            let relevantReports = report.targets
                .filter { $0.coveredLines > 1 }
                .sorted(by: { $0.coverage > $1.coverage })
                .prefix(amount)
                .map { $0 }

            return encodeCoverageRanked(relevantReports)

        case let .lastRanked(amount, report):
            let relevantReports = report.targets
                .filter { $0.coveredLines > 1 }
                .sorted(by: { $0.coverage < $1.coverage })
                .prefix(amount)
                .sorted(by: { $0.coverage > $1.coverage })
                .map { $0 }

            return encodeCoverageRanked(relevantReports)

        case let .uncovered(report):
            let relevantReports = report.targets
                .filter { $0.coveredLines < 1 }
                .sorted(by: { $0.executableLines > $1.executableLines })
                .map { $0 }

            return encodeUncoverageDetailed(relevantReports)

        case let .compare(current, previous):
            return encodeCoverageCompared(current.targets, previous: previous?.targets)
        case let .header(meta):
            return encodeCoverageHeader(meta)
        }
    }
}

extension CSVEncoderType {
    private func encodeCoverageRanked(_ targets: [Target]) -> String {
        var result = "Rank,Target,Coverage\n"
        for (index, target) in targets.enumerated() {
            result += encodeCoverageRankedSingleLine(index + 1, target: target)
        }
        return result
    }

    private func encodeCoverageRankedSingleLine(_ rank: Int, target: Target) -> String {
        "\(rank),\(escapeCSV(target.name)),\(target.printableCoverage)\n"
    }
}

extension CSVEncoderType {
    private func encodeCoverageDetailed(_ targets: [Target]) -> String {
        var result = "Rank,Target,Executable Lines,Covered Lines,Coverage\n"
        for (index, target) in targets.enumerated() {
            result += encodeCoverageDetailedSingleLine(index + 1, target: target)
        }
        return result
    }

    private func encodeCoverageDetailedSingleLine(_ rank: Int, target: Target) -> String {
        "\(rank),\(escapeCSV(target.name)),\(target.executableLines),\(target.coveredLines),\(target.printableCoverage)\n"
    }
}

extension CSVEncoderType {
    private func encodeCoverageCompared(_ current: [Target], previous: [Target]?) -> String {
        let comparableTargets = combineTargets(current, previous)
            .filter { $0.differenceCoverage > 0.009 || $0.differenceCoverage < 0.0 }

        if comparableTargets.isEmpty {
            return "No significant changes since last time\n"
        }

        let sortedTargets = comparableTargets.sorted { $0.differenceCoverage > $1.differenceCoverage }
        var result = "Rank,Target,Previous,Current,Changes\n"
        for (index, target) in sortedTargets.enumerated() {
            result += encodeCoverageComparedSingleLine(index + 1, compared: target)
        }
        return result
    }

    private func encodeCoverageComparedSingleLine(_ rank: Int, compared: ComparingTargets) -> String {
        "\(rank),\(escapeCSV(compared.name)),\(compared.previousCoverageString),\(compared.currentCoverageString),\(compared.differenceCoverageString)\n"
    }

    private func combineTargets(_ current: [Target], _ previous: [Target]?) -> [ComparingTargets] {
        var combinations: [ComparingTargets] = []
        for target in current {
            let previousTarget = previous?.first(where: { $0.name == target.name })
            combinations.append(ComparingTargets(current: target, previous: previousTarget))
        }

        return combinations
    }
}

extension CSVEncoderType {
    private func encodeCoverageHeader(_ coverage: CoverageMetaReport) -> String {
        let percentage = coverage.coverage.coverage * 100
        let date = DateFormat.fullWeekdayFullMonthNameDayYear.string(from: coverage.fileInfo.date)
        var result = "Report,Date,Overall Coverage\n"
        result += "\(escapeCSV(title)),\(escapeCSV(date)),\(String(format: "%.1f", percentage))\n"
        return result
    }
}

extension CSVEncoderType {
    private func encodeUncoverageDetailed(_ targets: [Target]) -> String {
        var result = "Rank,Target,Covered Lines,Executable Lines\n"
        for (index, target) in targets.enumerated() {
            result += encodeUncoverageDetailedSingleLine(index + 1, target: target)
        }
        return result
    }

    private func encodeUncoverageDetailedSingleLine(_ rank: Int, target: Target) -> String {
        "\(rank),\(escapeCSV(target.name)),\(target.coveredLines),\(target.executableLines)\n"
    }
}

extension CSVEncoderType {
    /// Escapes CSV values that contain commas, quotes, or newlines
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
