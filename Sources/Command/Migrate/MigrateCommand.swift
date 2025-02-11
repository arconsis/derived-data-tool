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

public final class MigrateCommand: AsyncParsableCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(commandName: "migrate", abstract: "Migrate from old JSON/zipped JSON to DuckDB database")

    private var tools: MigrateCommandToolWrapper!

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    @Flag(help: "activate extra logging")
    private var verbose: Bool = false

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    @Option(name: [.customShort("c"), .customLong("config")], help: "Path to the .xcrtool.yml")
    private var configFilePath: String?

    @Option(name: [.customShort("g"), .customLong("gitroot")], help: "git root path")
    private var customGitRootpath: String?

    public required init() {}

    @MainActor
    public func run() async throws {
        var connector: DatabaseConnector?
        do {
            try await Requirements.check()
            InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
            let config = try await ConfigFactory.getConfig(at: URL(with: configFilePath))
            guard let databasePath = config.locations?.databasePath else { throw MigrationError.missingDatabasePath }
            tools = await MigrateCommandToolWrapper.make(config: config, workingDirectory: customGitRootpath, databasePath: databasePath)

            guard let locationCurrentReport = tools.locationCurrentReport else { throw MigrationError.currentReportLocationMissing }
            let reportUrl: URL = tools.workingDirectory.appending(pathComponent: locationCurrentReport)

            guard let archiveLocation = tools.archiveLocation else { throw MigrationError.archiveLocationMissing }

            let archiver = Archiver(fileHandler: tools.fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()
            guard let root = await tools.fileHandler.getGitRootDirectory().value else {
                throw MigrationError.internalError
            }
            let relativeDatabasePath = root.appending(pathComponent: databasePath)

            connector = try await Repository.makeConnector(with: relativeDatabasePath)

            guard let connector else {
                throw MigrationError.internalError
            }

            let repository = try await Repository.make(with: connector)

            let migrateTool: MigrationTool = .init(fileHandler: tools.fileHandler,
                                                   cliTools: Tools(),
                                                   repository: repository,
                                                   archiver: archiver,
                                                   filterReports: tools.filterReports,
                                                   excludedTargets: tools.excludedTargets,
                                                   excludedFiles: tools.excludedFiles,
                                                   excludedFunctions: tools.excludedFunctions,
                                                   workingDirectory: tools.workingDirectory,
                                                   locationCurrentReport: reportUrl,
                                                   verbose: verbose,
                                                   quiet: quiet)
            try await migrateTool.run()

            try await connector.disconnect()
        } catch {
            try await connector?.disconnect()
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }

    }
}

extension MigrateCommand {
    struct MigrateCommandToolWrapper: Codable {
        private let config: Config
        let excludedTargets: [String]
        let excludedFiles: [String]
        let excludedFunctions: [String]
        let filterReports: [String]
        let locationCurrentReport: String?
        let fileHandler: FileHandler
        let workingDirectory: URL
        let databasePath: String
        private let cliTools: Tools
        var archiveLocation: URL?

//        var githubExporterSetting: GithubExportSettings {
//            try! config.settings(.githubExporter) as! GithubExportSettings
//        }

        private enum CodingKeys: String, CodingKey {
            case config,
                 excludedTargets,
                 excludedFiles,
                 excludedFunctions,
                 filterReports,
                 locationCurrentReport,
                 databasePath,
                 workingDirectory
        }

        init(from _: Decoder) throws {
            throw MigrationError.internalError
        }

        init(config: Config,
             excludedTargets: [String],
             excludedFiles: [String],
             excludedFunctions: [String],
             filterReports: [String],
             locationCurrentReport: String?,
             databasePath: String,
             fileHandler: FileHandler,
             workingDirectory: URL,
             archiveLocation: URL?,
             cliTools: Tools)
        {
            self.config = config
            self.excludedTargets = excludedTargets
            self.excludedFiles = excludedFiles
            self.excludedFunctions = excludedFunctions
            self.filterReports = filterReports
            self.locationCurrentReport = locationCurrentReport
            self.databasePath = databasePath
            self.fileHandler = fileHandler
            self.workingDirectory = workingDirectory
            self.cliTools = cliTools
            self.archiveLocation = archiveLocation
        }

        @MainActor
        static func make(config: Config, workingDirectory: String?, databasePath: String) async -> Self {
            let excludedTargets: [String] = config.excluded?.targets ?? []
            let excludedFiles: [String] = config.excluded?.files ?? []
            let excludedFunctions: [String] = config.excluded?.functions ?? []
            let filterReports: [String] = config.filterXCResults ?? []
            let locationCurrentReport: String? = config.locations?.currentReport
            let fileHandler = FileHandler()

            let workingDirectory: URL = await {
                if let workingDirectory {
                    return URL(with: workingDirectory)
                } else if let gitRoot = await fileHandler.getGitRootDirectory().value {
                    return gitRoot
                } else {
                    return fileHandler.getCurrentDirectoryUrl()
                }
            }()

            var archiveLocation: URL?
            if let archive = config.locations?.archive {
                archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")
            }

            return .init(config: config,
                         excludedTargets: excludedTargets,
                         excludedFiles: excludedFiles,
                         excludedFunctions: excludedFunctions,
                         filterReports: filterReports,
                         locationCurrentReport: locationCurrentReport,
                         databasePath: databasePath,
                         fileHandler: FileHandler(),
                         workingDirectory: workingDirectory,
                         archiveLocation: archiveLocation,
                         cliTools: Tools())
        }
    }
}

