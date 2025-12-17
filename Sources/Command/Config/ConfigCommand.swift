//
//  ConfigCommand.swift
//
//
//  Created by Moritz Ellerbrock on 15.06.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public class ConfigCommand: AsyncParsableCommand {
    var tools = ConfigCommandToolWrapper()

    // MARK: - AsyncParsableCommand

    public static let configuration = CommandConfiguration(commandName: "config", abstract: "Creates initial Config-file")

    @Flag(help: "activate extra logging")
    private var verbose: Bool = false

    @Option(name: [.customShort("g"), .customLong("gitroot")], help: "git root path")
    private var customGitRootpath: String?

    enum CodingKeys: CodingKey {
        case verbose, customGitRootpath
    }

    func gitRootpath() async -> URL {
        if let customGitRootpath {
            return URL(with: customGitRootpath)
        } else if let searchPath = await tools.getGitRootDirectory().value {
            return searchPath
        } else {
            return await tools.getCurrentDirectoryUrl()
        }
    }

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    // MARK: - Implementation

    public required init() {}

    public func run() async throws {
        try await Requirements.check()

        InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
        do {
            let gitRootpath = await gitRootpath()

            let config = Config.makeInitial()

            try await ConfigFactory.save(config, at: gitRootpath)

            logger.debug("HIT")

        } catch {
            logger.error("Error: \(error.localizedDescription)")

            if let errorable = error as? any Errorable, errorable.printsHelp {
                print(Self.helpMessage())
            }

            throw error
        }
    }
}

extension ConfigCommand {
    struct ConfigCommandToolWrapper {
        var fileHandler: FileHandler {
            get async {
                FileHandler()
            }
        }

        var cliTools: Tools { Tools() }

        func getGitRootDirectory() async -> URLResult {
            await fileHandler.getGitRootDirectory()
        }

        func getCurrentDirectoryUrl() async -> URL {
            await fileHandler.getCurrentDirectoryUrl()
        }
    }
}
