//
//  CoverageCommand.swift
//
//
//  Created by Moritz Ellerbrock on 27.04.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class CoverageCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(commandName: "coverage", abstract: "Generate an accumulated JSON for code coverage")

    public var logger: Loggerable {
        InjectedValues[\.logger]
    }

    @Flag(help: "activate extra logging")
    public var verbose: Bool = false

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    @Option(name: [.customShort("c"), .customLong("config")], help: "Path to the .xcrtool.yml")
    public var configFilePath: String?

    @Option(name: [.customShort("g"), .customLong("gitroot")], help: "git root path")
    public var customGitRootpath: String?

    enum CodingKeys: CodingKey {
        case verbose, quiet, configFilePath, customGitRootpath
    }

    public required init() {}

    public func run() async throws {
        do {
            try await Requirements.check()
            setupLogger()

            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)
            let filters = extractFilters(from: config)

            // Validate required configuration
            guard let databasePath = config.locations?.databasePath else {
                throw CoverageError.missingDatabasePath
            }
            guard let locationCurrentReport = config.locations?.currentReport else {
                throw CoverageError.currentReportLocationMissing
            }

            // Setup paths
            let reportUrl = workingDirectory.appending(pathComponent: locationCurrentReport)
            let archiveLocation: URL? = config.locations?.archive.map {
                workingDirectory.appending(pathComponent: "\($0)/")
            }
            guard let archiveLocation else {
                throw CoverageError.archiveLocationMissing
            }

            // Setup database
            let repository = try await makeRepository(
                databasePath: databasePath,
                fileHandler: fileHandler
            )

            // Get GitHub exporter settings
            guard let githubExporterSetting = try config.settings(.githubExporter) as? GithubExportSettings else {
                throw CoverageError.internalError
            }

            // Create and run coverage tool
            let coverageTool = CoverageTool(
                fileHandler: fileHandler,
                cliTools: makeTools(),
                githubExporterSetting: githubExporterSetting,
                repository: repository,
                filterReports: config.filterXCResults ?? [],
                excludedTargets: filters.excludedTargets,
                excludedFiles: filters.excludedFiles,
                excludedFunctions: filters.excludedFunctions,
                includedTargets: filters.includedTargets,
                includedFiles: filters.includedFiles,
                includedFunctions: filters.includedFunctions,
                workingDirectory: workingDirectory,
                locationCurrentReport: reportUrl,
                archiveLocation: archiveLocation,
                verbose: verbose,
                quiet: quiet
            )

            try await coverageTool.run()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }

    // MARK: - Private Helpers

    private func makeRepository(
        databasePath: String,
        fileHandler: FileHandler
    ) async throws -> ReportModelRepository {
        do {
            guard let root = await fileHandler.getGitRootDirectory().value else {
                throw CoverageError.internalError
            }

            let cleanPath = databasePath.ensureFilePath(defaultFileName: "database.sqlite").relativeString
            let databaseUrl = root.appending(pathComponent: cleanPath)
            let urlWithoutFileName = databaseUrl.deletingLastPathComponent()

            try FileManager.default.createDirectory(
                at: urlWithoutFileName,
                withIntermediateDirectories: true
            )

            return try await Repository.makeRepository(with: databaseUrl)
        } catch {
            if let covergeError = error as? CoverageError {
                throw covergeError
            }

            throw error
        }
    }
}
