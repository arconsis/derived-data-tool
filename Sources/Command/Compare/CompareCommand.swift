//
//  CompareCommand.swift
//
//
//  Created by Moritz Ellerbrock on 04.05.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class CompareCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Generate and export the process of code coverage over the last reports"
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

    @Option(name: [.customShort("t"), .customLong("targets")], help: "provide the targets that should be compared to the base")
    private var targets: [String]

    enum CodingKeys: CodingKey {
        case verbose, quiet, configFilePath, customGitRootpath, targets
    }

    public required init() {}

    public func run() async throws {
        do {
            // Use protocol methods
            setupLogger()
            logger.debug("Subcommand: started")

            try await Requirements.check()
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)

            // Setup archive location
            guard let archive = config.locations?.archive else {
                throw CompareError.archivePathIsMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")

            // Find xcresult files
            let xcResultURLs = await fileHandler.findXCResultfiles(at: workingDirectory).value

            guard let xcResultURLs, !xcResultURLs.isEmpty else {
                throw CompareError.noXCResultFilesFound(location: workingDirectory.fullPath)
            }

            let compareTool = CompareTool(
                workingDirectory: workingDirectory,
                xcResultURLs: xcResultURLs,
                fileHandler: fileHandler,
                tools: makeTools(),
                archiveUrl: archiveLocation,
                verbose: verbose,
                quiet: quiet
            )

            try await compareTool.run()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }
}

