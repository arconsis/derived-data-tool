//
//  ComparingTargets.swift
//
//
//  Created by Moritz Ellerbrock on 04.07.23.
//

import Foundation

public struct ComparingTargets {
    public let current: Target
    public let previous: Target?

    public var name: String {
        current.printableName
    }

    public init(current: Target, previous: Target? = nil) {
        self.current = current
        self.previous = previous
    }

    public static func combine(_ current: [Target], _ previous: [Target]?) -> [ComparingTargets] {
        var combinations: [ComparingTargets] = []
        for target in current {
            let previousTarget = previous?.first(where: { $0.name == target.name })
            combinations.append(ComparingTargets(current: target, previous: previousTarget))
        }

        return combinations
    }

    public static func combine(_ current: CoverageReport, _ previous: CoverageReport?) -> [ComparingTargets] {
        return combine(current.targets, previous?.targets)
    }

    public static func combine(_ current: CoverageMetaReport, _ previous: CoverageMetaReport?) -> [ComparingTargets] {
        return combine(current.coverage.targets, previous?.coverage.targets)
    }
}

// MARK: Coverage

public extension ComparingTargets {
    private var previousCoverage: Double {
        (previous?.coverage ?? 0.0) * 100.0
    }

    private var currentCoverage: Double {
        current.coverage * 100.0
    }

    var previousCoverageString: String {
        String(format: "%.2f", previousCoverage)
    }

    var currentCoverageString: String {
        String(format: "%.2f", currentCoverage)
    }

    var differenceCoverageString: String {
        return differenceCoverage > 0 ? "+\(String(format: "%.2f", differenceCoverage))" : String(format: "%.2f", differenceCoverage)
    }

    var differenceCoverage: Double {
        currentCoverage - previousCoverage
    }
}

// MARK: CoveredLines

public extension ComparingTargets {
    private var previousCoveredLines: Int {
        (previous?.coveredLines ?? 0)
    }

    private var currentCoveredLines: Int {
        current.coveredLines
    }

    var previousCoveredLinesString: String {
        String(previousCoverage)
    }

    var currentCoveredLinesString: String {
        String(currentCoverage)
    }

    var differenceCoveredLinesString: String {
        return differenceCoveredLines > 0 ? "+\(String(differenceCoveredLines))" : String(differenceCoveredLines)
    }

    var differenceCoveredLines: Int {
        currentCoveredLines - previousCoveredLines
    }
}

// MARK: ExecutableLines

public extension ComparingTargets {
    private var previousExecutableLines: Int {
        (previous?.executableLines ?? 0)
    }

    private var currentExecutableLines: Int {
        current.executableLines
    }

    var previousExecutableLinesString: String {
        String(previousCoverage)
    }

    var currentExecutableLinesString: String {
        String(currentCoverage)
    }

    var differenceExecutableLinesString: String {
        return differenceExecutableLines > 0 ? "+\(String(differenceExecutableLines))" : String(differenceExecutableLines)
    }

    var differenceExecutableLines: Int {
        currentExecutableLines - previousExecutableLines
    }
}
