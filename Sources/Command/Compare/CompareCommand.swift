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

public final class CompareCommand: AsyncParsableCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(commandName: "compare", abstract: "Generate and export the process of code coverage over the last reports")

    var tools: CompareCommandToolWrapper!

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    @Flag(help: "activate extra logging")
    private var verbose: Bool = false

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    @Option(name: [.customShort("c"), .customLong("config")], help: "Path to the .xcrtool.yml")
    private var configFilePath: String?

    @Option(name: [.customShort("t"), .customLong("targets")], help: "provide the targets that should be compared to the base")
    private var targets: [String]

    public required init() {}

    public func run() async throws {
        do {
            InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
            logger.debug("Subcommand: started")

            try await Requirements.check()
            let config = try await ConfigFactory.getConfig(at: URL(with: configFilePath))
            tools = try await CompareCommandToolWrapper.make(config: config, filterReports: targets)

            guard let xcResultURLs = await tools.findXCResultfiles().value else {
                return
            }

            let compareTool = CompareTool(workingDirectory: tools.workingDirectory,
                                          xcResultURLs: xcResultURLs,
                                          fileHandler: tools.fileHandler,
                                          tools: tools.tools,
                                          archiveUrl: tools.archiveUrl,
                                          verbose: verbose,
                                          quiet: quiet)

            try await compareTool.run()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: CompareCommand.helpMessage())
        }
    }
}

extension CompareCommand {
    struct CompareCommandToolWrapper: Codable {
        let config: Config
        let workingDirectory: URL
        let archiveUrl: URL
        let fileHandler: FileHandler
        let tools: Tools

        private enum CodingKeys: String, CodingKey {
            case config,
                 workingDirectory,
                 archiveUrl
        }

        init(from _: Decoder) throws {
            throw CompareError.internalError
        }

        func encode(to _: Encoder) throws {
            throw CompareError.internalError
        }

        init(config: Config, workingDirectory: URL, archiveUrl: URL, fileHandler: FileHandler, tools: Tools) {
            self.config = config
            self.workingDirectory = workingDirectory
            self.archiveUrl = archiveUrl
            self.fileHandler = fileHandler
            self.tools = tools
        }

        @MainActor
        static func make(config: Config,
                         filterReports _: [String]) async throws -> Self
        {
            let fileHandler = FileHandler()

            let workingDirectoryUrl = fileHandler.getCurrentDirectoryUrl()

            guard
                let archive = config.locations?.archive
            else {
                throw CompareError.archivePathIsMissing
            }

            let archiveLocation = workingDirectoryUrl.appending(pathComponent: "\(archive)/")

            return .init(config: config,
                         workingDirectory: workingDirectoryUrl,
                         archiveUrl: archiveLocation,
                         fileHandler: fileHandler,
                         tools: Tools())
        }
    }
}

extension CompareCommand.CompareCommandToolWrapper {
    func findXCResultfiles() async -> URLArrayResult {
        let result = await fileHandler.findXCResultfiles(at: workingDirectory)
        guard
            let xcResultURLs = result.value,
            !xcResultURLs.isEmpty
        else {
            return .failure(.init(printsHelp: false, error: CompareError.noXCResultFilesFound(location: workingDirectory.fullPath)))
        }
        return result
    }

    func xccov(filePath: URL) async -> StringResult {
        await tools.xccov(filePath: filePath)
    }
}
