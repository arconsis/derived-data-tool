//
//  TrendCommand.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class TrendCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "trend",
        abstract: "Generate coverage trend charts showing coverage evolution over time",
        discussion: """
            Creates SVG charts visualizing coverage trends from historical reports stored in the database. \
            Supports filtering by date range or report count, tracking specific targets, and displaying \
            threshold reference lines. Useful for monitoring coverage progress in CI/CD pipelines.
            """
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

    @Option(name: [.customShort("g"), .customLong("gitroot")])
    public var customGitRootpath: String?

    @Option(name: [.customShort("d"), .customLong("days")], help: "Number of days of history to include")
    private var days: Int?

    @Option(name: [.customShort("l"), .customLong("limit")], help: "Maximum number of reports to include")
    private var limit: Int?

    @Option(name: [.customShort("t"), .customLong("targets")], help: "Target names to include in per-target trends")
    private var targets: [String] = []

    @Option(name: [.customLong("threshold")], help: "Coverage threshold to display as reference line")
    private var threshold: Double?

    @Option(name: [.customShort("o"), .customLong("output")], help: "Output path for the SVG chart")
    private var output: String = "coverage-trend.svg"

    enum CodingKeys: CodingKey {
        case verbose, quiet, configFilePath, customGitRootpath, days, limit, targets, threshold, output
    }

    public required init() {}

    public func run() async throws {
        do {
            try await Requirements.check()

            // Use protocol methods
            setupLogger()
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)

            // Setup database
            guard let databasePath = config.locations?.databasePath else {
                throw TrendError.chartGenerationFailed(reason: "Database path not configured")
            }

            let repository = try await makeRepository(
                databasePath: databasePath,
                fileHandler: fileHandler
            )

            // Setup output path
            let outputUrl: URL
            if output.hasPrefix("/") {
                outputUrl = URL(fileURLWithPath: output)
            } else {
                outputUrl = workingDirectory.appending(pathComponent: output)
            }

            // Create and run trend tool
            let trendTool = TrendTool(
                fileHandler: fileHandler,
                repository: repository,
                days: days,
                limit: limit,
                targetFilters: targets,
                threshold: threshold,
                outputPath: outputUrl,
                verbose: verbose,
                quiet: quiet
            )

            try await trendTool.run()
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
                throw TrendError.chartGenerationFailed(reason: "Could not find git root directory")
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
            if let trendError = error as? TrendError {
                throw trendError
            }

            throw error
        }
    }
}
