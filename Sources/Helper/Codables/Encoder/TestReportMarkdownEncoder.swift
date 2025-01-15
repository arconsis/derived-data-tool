//
//  TestReportMarkdownEncoder.swift
//
//
//  Created by Moritz Ellerbrock on 09.05.23.
//

import Foundation
import Shared

struct TestReportMarkdownEncoder: TestReportEncoder {
    func encode(_ coverageReport: FullCoverageReport) throws -> String {
        let sortedTargets = coverageReport.targets.sorted(by: { $0.name < $1.name })
        var result = "| Targetname | Executable Lines | Covered Lines | Coverage |\n"
        result += "| :--- | ---: | :--- | :---: |\n"
        for target in sortedTargets {
            result += encodeSingleCoverage(target)
        }

        return result
    }

    func encode(_ targetReports: TargetReports) throws -> String {
        let sortedTargets = targetReports.sorted(by: { $0.name < $1.name })
        return encodeCoverage(sortedTargets)
    }

    func encode(_ target: Target) throws -> String {
        let sortedFiles = target.files.sorted(by: { $0.name < $1.name })
        return encodeCoverage(sortedFiles, firstColumn: "File")
    }

    func encode(_ file: File) throws -> String {
        let sortedFunctions = file.functions.sorted(by: { $0.name < $1.name })
        return encodeCoverage(sortedFunctions, firstColumn: "Function")
    }

    private func encodeCoverage(_ sortedReports: [any Coverage], firstColumn name: String = "Targetname") -> String {
        var result = "| \(name.capitalized) | Executable Lines | Covered Lines | Coverage |\n"
        result += "| :--- | ---: | :--- | :---: |\n"
        for target in sortedReports {
            result += encodeSingleCoverage(target)
        }

        return result
    }

    private func encodeSingleCoverage(_ target: any Coverage) -> String {
        return "| \(target.name) | \(target.executableLines) | \(target.coveredLines) | \(target.printableCoverage)% |\n"
    }
}
