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
    private let verbose: Bool
    private let quiet: Bool
    private let fileHandler: FileHandler
    private let cliTools: Tools
    private let repository: ReportModelRepository

    private let filterReports: [String]
    private let excludedTargets: [String]
    private let excludedFiles: [String]
    private let excludedFunctions: [String]

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
        self.workingDirectory = workingDirectory
        self.locationCurrentReport = locationCurrentReport
        self.archiver = archiver
        self.repository = repository
    }
}

extension MigrationTool: Runnable {
    func run() async throws {
        do {
            logger.log("setup completed")

            let archives = archiver.sortedArchives

            var counter: Int = 0

            for archive in archives {
                logger.log("archive: \(archive)")
                let report = try archiver.report(for: archive)

                try await repository.add(report: report)

                try fileHandler.deleteFile(at: archive.url)
                counter += 1
                print("Finished \(String(format: "%.2f", (Double(counter) / Double(archives.count) * 100.0)))%")
            }
            print("DONE")
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

}

