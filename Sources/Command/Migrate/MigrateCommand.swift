//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 19.11.24.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class MigrateCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "migrate",
        abstract: "Migrate from old JSON/zipped JSON to DuckDB database"
    )

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
        var connector: DatabaseConnector?
        do {
            try await Requirements.check()

            // Use protocol methods
            setupLogger()
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)
            let filters = extractFilters(from: config)

            // Validate required configuration
            guard let databasePath = config.locations?.databasePath else {
                throw MigrationError.missingDatabasePath
            }

            guard let locationCurrentReport = config.locations?.currentReport else {
                throw MigrationError.currentReportLocationMissing
            }

            guard let archive = config.locations?.archive else {
                throw MigrationError.archiveLocationMissing
            }

            // Setup paths
            let reportUrl = workingDirectory.appending(pathComponent: locationCurrentReport)
            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")

            // Setup archiver
            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()

            // Setup database
            let databaseUrl = try await makeDatabaseUrl(
                databasePath: databasePath,
                fileHandler: fileHandler
            )

            connector = try await Repository.makeConnector(with: databaseUrl)

            guard let connector else {
                throw MigrationError.internalError
            }

            let repository = try await Repository.make(with: connector)

            // Create and run migration tool
            let migrateTool = MigrationTool(
                fileHandler: fileHandler,
                cliTools: makeTools(),
                repository: repository,
                archiver: archiver,
                filterReports: config.filterXCResults ?? [],
                excludedTargets: filters.excludedTargets,
                excludedFiles: filters.excludedFiles,
                excludedFunctions: filters.excludedFunctions,
                includedTargets: filters.includedTargets,
                includedFiles: filters.includedFiles,
                includedFunctions: filters.includedFunctions,
                workingDirectory: workingDirectory,
                locationCurrentReport: reportUrl,
                verbose: verbose,
                quiet: quiet
            )
            try await migrateTool.run()

            try await connector.disconnect()
        } catch {
            try await connector?.disconnect()
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }

    // MARK: - Private Helpers

    private func makeDatabaseUrl(databasePath: String, fileHandler: FileHandler) async throws -> URL {
        guard let root = await fileHandler.getGitRootDirectory().value else {
            throw MigrationError.internalError
        }

        let cleanPath = databasePath
            .ensureFilePath(defaultFileName: "database.sqlite")
            .relativeString
        let url = root.appending(pathComponent: cleanPath)
        let urlWithoutFileName = url.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: urlWithoutFileName,
            withIntermediateDirectories: true
        )

        return url
    }
}


