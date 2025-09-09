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

public final class CoverageCommand: AsyncParsableCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(commandName: "coverage", abstract: "Generate an accumulated JSON for code coverage")

    private var tools: CoverageCommandToolWrapper!

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
        do {
            try await Requirements.check()
            InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
            let config = try await ConfigFactory.getConfig(at: URL(with: configFilePath))
            tools = await CoverageCommandToolWrapper.make(config: config, workingDirectory: customGitRootpath)

            guard let locationCurrentReport = tools.locationCurrentReport else { throw CoverageError.currentReportLocationMissing }
            let reportUrl: URL = tools.workingDirectory.appending(pathComponent: locationCurrentReport)

            guard let archiveLocation = tools.archiveLocation else { throw CoverageError.archiveLocationMissing }

            let coverageTool: CoverageTool = .init(fileHandler: tools.fileHandler,
                                                   cliTools: Tools(),
                                                   githubExporterSetting: tools.githubExporterSetting,
                                                   filterReports: tools.filterReports,
                                                   excludedTargets: tools.excludedTargets,
                                                   excludedFiles: tools.excludedFiles,
                                                   excludedFunctions: tools.excludedFunctions,
                                                   includedTargets: tools.includedTargets,
                                                   includedFiles: tools.includedFiles,
                                                   includedFunctions: tools.includedFunctions,
                                                   workingDirectory: tools.workingDirectory,
                                                   locationCurrentReport: reportUrl,
                                                   archiveLocation: archiveLocation,
                                                   verbose: verbose,
                                                   quiet: quiet)
            try await coverageTool.run()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }
}

extension CoverageCommand {
    struct CoverageCommandToolWrapper: Codable {
        private let config: Config
        let excludedTargets: [String]
        let excludedFiles: [String]
        let excludedFunctions: [String]

        let includedTargets: [String]
        let includedFiles: [String]
        let includedFunctions: [String]

        let filterReports: [String]
        let locationCurrentReport: String?
        let fileHandler: FileHandler
        let workingDirectory: URL
        private let cliTools: Tools
        var archiveLocation: URL?

        var githubExporterSetting: GithubExportSettings {
            try! config.settings(.githubExporter) as! GithubExportSettings
        }

        private enum CodingKeys: String, CodingKey {
            case config,
                 excludedTargets,
                 excludedFiles,
                 excludedFunctions,
                 filterReports,
                 locationCurrentReport,
                 workingDirectory
        }

        init(from _: Decoder) throws {
            throw CoverageError.internalError
        }

        init(config: Config,
             excludedTargets: [String],
             excludedFiles: [String],
             excludedFunctions: [String],
             includedTargets: [String],
             includedFiles: [String],
             includedFunctions: [String],
             filterReports: [String],
             locationCurrentReport: String?,
             fileHandler: FileHandler,
             workingDirectory: URL,
             archiveLocation: URL?,
             cliTools: Tools)
        {
            self.config = config
            self.excludedTargets = excludedTargets
            self.excludedFiles = excludedFiles
            self.excludedFunctions = excludedFunctions

            self.includedTargets = includedTargets
            self.includedFiles = includedFiles
            self.includedFunctions = includedFunctions

            self.filterReports = filterReports
            self.locationCurrentReport = locationCurrentReport
            self.fileHandler = fileHandler
            self.workingDirectory = workingDirectory
            self.cliTools = cliTools
            self.archiveLocation = archiveLocation
        }

        @MainActor
        static func make(config: Config, workingDirectory: String?) async -> Self {
            let excludedTargets: [String] = config.excluded?.targets ?? []
            let excludedFiles: [String] = config.excluded?.files ?? []
            let excludedFunctions: [String] = config.excluded?.functions ?? []

            let includedTargets: [String] = config.included?.targets ?? []
            let includedFiles: [String] = config.included?.files ?? []
            let includedFunctions: [String] = config.included?.functions ?? []

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
                         includedTargets: includedTargets,
                         includedFiles: includedFiles,
                         includedFunctions: includedFunctions,
                         filterReports: filterReports,
                         locationCurrentReport: locationCurrentReport,
                         fileHandler: FileHandler(),
                         workingDirectory: workingDirectory,
                         archiveLocation: archiveLocation,
                         cliTools: Tools())
        }
    }
}
