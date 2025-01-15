//
//  Comparer.swift
//
//
//  Created by Moritz Ellerbrock on 05.07.23.
//

import Foundation
import Shared

public class Comparer {
    private let fileHandler: FileHandler
    private let archiveUrl: URL // the base to compare to
    private let archiver: Archiver
    private let tool: Tools

    public init(fileHandler: FileHandler,
                tool: Tools,
                archiveUrl: URL)
    {
        self.fileHandler = fileHandler
        self.archiveUrl = archiveUrl
        self.tool = tool
        archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveUrl)
    }

    public func compare(_ coverageReport: FullCoverageReport) async throws -> [ComparingTargets] {
        try await archiver.setup()
        guard let baseReport = try archiver.lastReport()?.coverage else {
            throw ComparerError.baselineReportMissing
        }

        let current = coverageReport.concentrate(on: baseReport.targets)

        var targets = ComparingTargets.combine(current.targets, baseReport.targets)

        targets.sort { $0.differenceExecutableLines > $1.differenceExecutableLines }

        targets = targets.filter { abs($0.differenceExecutableLines) > 0 }

        return targets
    }
}

public extension Comparer {
    enum ComparerError: Errorable {
        case baselineReportMissing

        public var printsHelp: Bool { false }
        public var errorDescription: String? { localizedDescription }
    }
}
