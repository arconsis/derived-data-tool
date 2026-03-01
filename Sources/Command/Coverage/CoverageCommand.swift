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

    @Option(name: .long, help: "Minimum coverage threshold percentage (overrides config)")
    public var minCoverage: Double?

    @Option(name: .long, help: "Maximum coverage drop percentage (overrides config)")
    public var maxDrop: Double?

    @Flag(help: "output GitHub Actions workflow annotations")
    public var githubAnnotations: Bool = false

    enum CodingKeys: CodingKey {
        case verbose, quiet, configFilePath, customGitRootpath, minCoverage, maxDrop, githubAnnotations
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

            // Load and merge threshold settings
            let thresholdSettings = try loadThresholdSettings(from: config)

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
                thresholdSettings: thresholdSettings,
                verbose: verbose,
                quiet: quiet,
                githubAnnotations: githubAnnotations
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

    private func loadThresholdSettings(from config: Config) throws -> ThresholdSettings? {
        // Load threshold settings from config
        var configSettings: ThresholdSettings?
        do {
            configSettings = try config.settings(.threshold) as? ThresholdSettings
        } catch {
            // Threshold settings not configured in config file, which is fine
            configSettings = nil
        }

        // If we have CLI overrides, merge them with config settings
        if minCoverage != nil || maxDrop != nil {
            let configMinCoverage = configSettings?.minCoverage
            let configMaxDrop = configSettings?.maxDrop
            let configPerTargetThresholds = configSettings?.perTargetThresholds ?? [:]

            // CLI flags override config values
            let finalMinCoverage = minCoverage ?? configMinCoverage
            let finalMaxDrop = maxDrop ?? configMaxDrop

            // Create merged settings
            var mergedDict: [String: String] = [:]
            if let min = finalMinCoverage {
                mergedDict["min_coverage"] = "\(min)"
            }
            if let max = finalMaxDrop {
                mergedDict["max_drop"] = "\(max)"
            }
            if !configPerTargetThresholds.isEmpty {
                let jsonData = try SingleEncoder.shared.encode(configPerTargetThresholds)
                if let json = String(data: jsonData, encoding: .utf8) {
                    mergedDict["per_target_thresholds"] = json
                }
            }

            return try ThresholdSettings(values: mergedDict)
        }

        // No CLI overrides, return config settings as-is
        return configSettings
    }
}
