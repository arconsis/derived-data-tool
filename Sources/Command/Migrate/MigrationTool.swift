//
//  MigrationTool.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 26.01.25.
//


import DependencyInjection
import Foundation
import Helper
import Shared

class MigrationTool {
    private static let reporterId: String = "MigrationTool"
    private let verbose: Bool
    private let quiet: Bool
    private let fileHandler: FileHandler
    private let cliTools: Tools
    private let repository: ReportModelRepository

    private let filterReports: [String]
    private let excludedTargets: [String]
    private let excludedFiles: [String]
    private let excludedFunctions: [String]
    private let includedTargets: [String]
    private let includedFiles: [String]
    private let includedFunctions: [String]

    private let workingDirectory: URL
    private let locationCurrentReport: URL
    private let archiver: Archiver

    
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    init(fileHandler: FileHandler,
         cliTools: Tools,
         repository: ReportModelRepository,
         archiver: Archiver,
         filterReports: [String],
         excludedTargets: [String],
         excludedFiles: [String],
         excludedFunctions: [String],
         includedTargets: [String],
         includedFiles: [String],
         includedFunctions: [String],
         workingDirectory: URL,
         locationCurrentReport: URL,
         verbose: Bool = false,
         quiet: Bool = false)
    {
        self.verbose = verbose
        self.quiet = quiet
        self.fileHandler = fileHandler
        self.cliTools = cliTools
        self.filterReports = filterReports
        self.excludedTargets = excludedTargets
        self.excludedFiles = excludedFiles
        self.excludedFunctions = excludedFunctions
        self.includedTargets = includedTargets
        self.includedFiles = includedFiles
        self.includedFunctions = includedFunctions
        self.workingDirectory = workingDirectory
        self.locationCurrentReport = locationCurrentReport
        self.archiver = archiver
        self.repository = repository
    }
}

extension MigrationTool: Runnable {
    func run() async throws {
        do {
            report(text: "setup completed", clearLine: false)

            let archives = archiver.sortedArchives

            var counter: Int = 0

            for archive in archives {
                let report = try archiver.report(for: archive)

                // Apply filters to coverage data
                let filteredCoverage = applyFilters(to: report.coverage)
                let filteredReport = CoverageMetaReport(fileInfo: report.fileInfo, coverage: filteredCoverage)

                try await repository.add(report: filteredReport)

                try fileHandler.deleteFile(at: archive.url)
                counter += 1
                self.report(step: counter, of: archives.count, inPercentage: true)
            }
            self.report(finished: true)
        } catch {
            logger.error("Error: \(error: error)")
            if !quiet {
                print(MigrateCommand.helpMessage())
                throw error
            }
        }
    }
}

// MARK: Helper

private extension MigrationTool {
    private var progressReporter: ProgressReporterFactory {
        ProgressReporterFactory.default
    }

    func report(percentage: Double) {
        progressReporter.report(percentage: percentage, onReporterWith: Self.reporterId)
    }

    func report(step: Int, of totalSteps: Int, inPercentage: Bool) {
        progressReporter.report(step: step, of: totalSteps, inPercentage: inPercentage, onReporterWith: Self.reporterId)
    }

    func report(finished: Bool) {
        progressReporter.report(finished: finished, onReporterWith: Self.reporterId)
    }

    func report(text: String, clearLine: Bool) {
        progressReporter.report(text: text, clearLine: clearLine, onReporterWith: Self.reporterId)
    }

    /// Applies exclude and include filters to a coverage report
    /// - Parameter coverage: The coverage report to filter
    /// - Returns: Filtered coverage report
    /// - Note: Filters are applied in order: Exclude → Include
    func applyFilters(to coverage: CoverageReport) -> CoverageReport {
        var filtered = coverage

        // Process excluded list first (remove unwanted items)
        filtered = filtered.exclude(targets: excludedTargets)
        filtered = filtered.exclude(files: excludedFiles)
        filtered = filtered.exclude(functions: excludedFunctions)

        // Process included list last (keep only wanted items from what's left)
        filtered = filtered.include(targets: includedTargets)
        filtered = filtered.include(files: includedFiles)
        filtered = filtered.include(functions: includedFunctions)

        return filtered
    }
}

