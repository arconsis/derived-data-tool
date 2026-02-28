//
//  JSONSummaryEncoder.swift
//
//
//  Created by Moritz Ellerbrock on 13.06.23.
//

import Foundation
import Shared

public enum JSONSummaryEncoderType {
    case header(meta: CoverageMetaReport)
    case detailed(report: CoverageReport)
    case topRanked(amount: Int, report: CoverageReport)
    case lastRanked(amount: Int, report: CoverageReport)
    case uncovered(report: CoverageReport)
    case compare(current: CoverageReport, previous: CoverageReport?)
}

extension JSONSummaryEncoderType: CoverageReportEncoding {
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

            return encodeCoverageDetailed(relevantReports, report: report)

        case let .topRanked(amount, report):
            let relevantReports = report.targets
                .filter { $0.coveredLines > 1 }
                .sorted(by: { $0.coverage > $1.coverage })
                .prefix(amount)
                .map { $0 }

            return encodeCoverageRanked(relevantReports, report: report)

        case let .lastRanked(amount, report):
            let relevantReports = report.targets
                .filter { $0.coveredLines > 1 }
                .sorted(by: { $0.coverage < $1.coverage })
                .prefix(amount)
                .sorted(by: { $0.coverage > $1.coverage })
                .map { $0 }

            return encodeCoverageRanked(relevantReports, report: report)

        case let .uncovered(report):
            let relevantReports = report.targets
                .filter { $0.coveredLines < 1 }
                .sorted(by: { $0.executableLines > $1.executableLines })
                .map { $0 }

            return encodeUncoverageDetailed(relevantReports, report: report)

        case let .compare(current, previous):
            return encodeCoverageCompared(current, previous: previous)
        case let .header(meta):
            return encodeCoverageHeader(meta)
        }
    }
}

extension JSONSummaryEncoderType {
    private func encodeCoverageRanked(_ targets: [Target], report: CoverageReport) -> String {
        var json: [String: Any] = [:]
        json["type"] = title
        json["overall"] = createOverallSummary(report)
        json["targets"] = targets.enumerated().map { index, target in
            createTargetSummary(target, rank: index + 1)
        }

        return encodeJSON(json)
    }
}

extension JSONSummaryEncoderType {
    private func encodeCoverageDetailed(_ targets: [Target], report: CoverageReport) -> String {
        var json: [String: Any] = [:]
        json["type"] = title
        json["overall"] = createOverallSummary(report)
        json["targets"] = targets.enumerated().map { index, target in
            createDetailedTargetSummary(target, rank: index + 1)
        }

        return encodeJSON(json)
    }
}

extension JSONSummaryEncoderType {
    private func encodeCoverageCompared(_ current: CoverageReport, previous: CoverageReport?) -> String {
        let comparableTargets = combineTargets(current.targets, previous?.targets)
            .filter { $0.differenceCoverage > 0.009 || $0.differenceCoverage < 0.0 }

        var json: [String: Any] = [:]
        json["type"] = title
        json["overall"] = createOverallSummary(current)

        if comparableTargets.isEmpty {
            json["message"] = "No significant changes since last time"
            json["targets"] = []
        } else {
            let sortedTargets = comparableTargets.sorted { $0.differenceCoverage > $1.differenceCoverage }
            json["targets"] = sortedTargets.enumerated().map { index, compared in
                createComparisonSummary(compared, rank: index + 1)
            }
        }

        if let previous = previous {
            json["comparison"] = createComparisonOverall(current: current, previous: previous)
        }

        return encodeJSON(json)
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

extension JSONSummaryEncoderType {
    private func encodeCoverageHeader(_ meta: CoverageMetaReport) -> String {
        let percentage = meta.coverage.coverage * 100
        let date = DateFormat.fullWeekdayFullMonthNameDayYear.string(from: meta.fileInfo.date)

        var json: [String: Any] = [:]
        json["type"] = title
        json["date"] = date
        json["application"] = meta.fileInfo.application
        json["overall"] = [
            "coverage": String(format: "%.2f", percentage),
            "lines_covered": meta.coverage.coveredLines,
            "lines_total": meta.coverage.executableLines
        ]

        return encodeJSON(json)
    }
}

extension JSONSummaryEncoderType {
    private func encodeUncoverageDetailed(_ targets: [Target], report: CoverageReport) -> String {
        var json: [String: Any] = [:]
        json["type"] = title
        json["overall"] = createOverallSummary(report)
        json["targets"] = targets.enumerated().map { index, target in
            [
                "rank": index + 1,
                "name": target.name,
                "covered_lines": target.coveredLines,
                "executable_lines": target.executableLines,
                "coverage": target.printableCoverage
            ]
        }

        return encodeJSON(json)
    }
}

extension JSONSummaryEncoderType {
    private func createOverallSummary(_ report: CoverageReport) -> [String: Any] {
        [
            "coverage": report.printableCoverage,
            "lines_covered": report.coveredLines,
            "lines_total": report.executableLines
        ]
    }

    private func createTargetSummary(_ target: Target, rank: Int) -> [String: Any] {
        [
            "rank": rank,
            "name": target.name,
            "coverage": target.printableCoverage
        ]
    }

    private func createDetailedTargetSummary(_ target: Target, rank: Int) -> [String: Any] {
        [
            "rank": rank,
            "name": target.name,
            "executable_lines": target.executableLines,
            "covered_lines": target.coveredLines,
            "coverage": target.printableCoverage
        ]
    }

    private func createComparisonSummary(_ compared: ComparingTargets, rank: Int) -> [String: Any] {
        [
            "rank": rank,
            "name": compared.name,
            "previous": compared.previousCoverageString,
            "current": compared.currentCoverageString,
            "change": compared.differenceCoverageString
        ]
    }

    private func createComparisonOverall(current: CoverageReport, previous: CoverageReport) -> [String: Any] {
        let currentCoverage = current.coverage * 100
        let previousCoverage = previous.coverage * 100
        let delta = currentCoverage - previousCoverage

        return [
            "previous_coverage": String(format: "%.2f", previousCoverage),
            "current_coverage": String(format: "%.2f", currentCoverage),
            "delta": delta > 0 ? "+\(String(format: "%.2f", delta))" : String(format: "%.2f", delta)
        ]
    }

    private func encodeJSON(_ object: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return "{\"error\": \"Failed to encode JSON\"}"
        }
    }
}
