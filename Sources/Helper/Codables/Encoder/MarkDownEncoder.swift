//
//  MarkDownEncoder.swift
//
//
//  Created by Moritz Ellerbrock on 13.06.23.
//

import Foundation
import Shared

public enum MarkdownEncoderType {
    case header(meta: CoverageMetaReport)
    case detailed(report: CoverageReport)
    case topRanked(amount: Int, report: CoverageReport)
    case lastRanked(amount: Int, report: CoverageReport)
    case uncovered(report: CoverageReport)
    case compare(current: CoverageReport, previous: CoverageReport?)
}

public protocol CoverageReportEncoding {
    func encode() -> String
//    func encode(_: TargetReports) throws -> String
//    func encode(_: File) throws -> String
//    func encode(_: Target) throws -> String
}

extension MarkdownEncoderType: CoverageReportEncoding {
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
            return "!UNCOVERED TARGETS!"
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

extension MarkdownEncoderType {
    private func encodeCoverageRanked(_ targets: [Target]) -> String {
        var result = "# \(title.uppercased())\n| Rank | Target | Coverage |\n"
        result += "| :--- | :--- | :---: |\n"
        for (index, target) in targets.enumerated() {
            result += encodeCoverageRankedSingleLine(index + 1, target: target)
        }
        return result
    }

    private func encodeCoverageRankedSingleLine(_ rank: Int, target: Target) -> String {
        "| \(rank). | \(target.name) | \(target.printableCoverage)% |\n"
    }
}

extension MarkdownEncoderType {
    private func encodeCoverageDetailed(_ targets: [Target]) -> String {
        var result = "# \(title.uppercased())\n| Rank | Target | Executable Lines | Covered Lines | Coverage |\n"
        result += "| :--- | :--- | :---: | :---: | :---: |\n"
        for (index, target) in targets.enumerated() {
            result += encodeCoverageDetailedSingleLine(index + 1, target: target)
        }
        return result
    }

    private func encodeCoverageDetailedSingleLine(_ rank: Int, target: Target) -> String {
        "| \(rank). | \(target.name) | \(target.executableLines) | \(target.coveredLines) | \(target.printableCoverage)% |\n"
    }
}

extension MarkdownEncoderType {
    private func encodeCoverageCompared(_ current: [Target], previous: [Target]?) -> String {
        let comparableTargets = combineTargets(current, previous)
            .filter { $0.differenceCoverage > 0.009 || $0.differenceCoverage < 0.0 }

        if comparableTargets.isEmpty {
            return "# \(title.uppercased())\n ## The changes since last time are worth mentioning 😢\n"
        }

        let sortedTargets = comparableTargets.sorted { $0.differenceCoverage > $1.differenceCoverage }
        var result = "# \(title.uppercased())\n| Rank | Target | Previous | Current | Changes |\n"
        result += "| :--- | :--- | :---: | :---: | :---: |\n"
        for (index, target) in sortedTargets.enumerated() {
            result += encodeCoverageComparedSingleLine(index + 1, compared: target)
        }
        return result
    }

    private func encodeCoverageComparedSingleLine(_ rank: Int, compared: ComparingTargets) -> String {
        "| \(rank). | \(compared.name) | \(compared.previousCoverageString)% | \(compared.currentCoverageString)% | \(compared.differenceCoverageString)% |\n"
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

extension MarkdownEncoderType {
    private func encodeCoverageHeader(_ coverage: CoverageMetaReport) -> String {
        let percentage = coverage.coverage.coverage * 100
        let date = DateFormat.fullWeekdayFullMonthNameDayYear.string(from: coverage.fileInfo.date)
        var result = "# \(title.uppercased()) (\(date))\n"
        result += "# \(String(format: "%.1f", percentage))% Overall Coverage\n"
        return result
    }

//    func encode(_ coverageReport: CoverageReport) throws -> String {
//        let sortedTargets = coverageReport.targets.sorted(by: { $0.name < $1.name })
//        var result = "| Targetname | Executable Lines | Covered Lines | Coverage |\n"
//        result += "| :--- | ---: | :--- | :---: |\n"
//        for target in sortedTargets {
//            result += encodeSingleCoverage(target)
//        }
//
//        return result
//    }
//
//    func encode(_ targetReports: TargetReports) throws -> String {
//        let sortedTargets = targetReports.sorted(by: { $0.name < $1.name })
//        return encodeCoverage(sortedTargets)
//    }
//
//    func encode(_ target: Target) throws -> String {
//        let sortedFiles = target.files.sorted(by: { $0.name < $1.name })
//        return encodeCoverage(sortedFiles, firstColumn: "File")
//    }
//
//    func encode(_ file: File) throws -> String {
//        let sortedFunctions = file.functions.sorted(by: { $0.name < $1.name })
//        return encodeCoverage(sortedFunctions, firstColumn: "Function")
//    }
//
//    private func encodeCoverage(_ sortedReports: [any Coverage], firstColumn name: String = "Targetname") -> String {
//        var result = "| \(name.capitalized) | Executable Lines | Covered Lines | Coverage |\n"
//        result += "| :--- | ---: | :--- | :---: |\n"
//        for target in sortedReports {
//            result += encodeSingleCoverage(target)
//        }
//
//        return result
//    }
//
//    private func encodeSingleCoverage(_ target: any Coverage) -> String {
//        return "| \(target.name) | \(target.executableLines) | \(target.coveredLines) | \(target.printableCoverage)% |\n"
//    }
}

extension MarkdownEncoderType {
    private func encodeUncoverageDetailed(_ targets: [Target]) -> String {
        var result = "# \(title.uppercased())\n| Rank | Target | Covered Lines | Executable Lines |\n"
        result += "| :--- | :--- | :---: | :---: |\n"
        for (index, target) in targets.enumerated() {
            result += encodeUncoverageDetailedSingleLine(index + 1, target: target)
        }
        return result
    }

    private func encodeUncoverageDetailedSingleLine(_ rank: Int, target: Target) -> String {
        "| \(rank). | \(target.name) | \(target.coveredLines) | \(target.executableLines) |\n"
    }
}
