//
//  BuildCommand.swift
//
//
//  Created by Moritz Ellerbrock on 01.06.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public class BuildCommand: AsyncParsableCommand {
    private var tools: BuildCommandToolWrapper!

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

    // MARK: - AsyncParsableCommand

    public static let configuration = CommandConfiguration(commandName: "build", abstract: "Inspect build process and test results")

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    @Flag(help: "activate extra logging")
    private var verbose: Bool = false

    @Option(name: [.customShort("c"), .customLong("config")], help: "Path to the .xcrtool.yml")
    var configFilePath: String?

    @Option(name: [.customShort("g"), .customLong("gitroot")], help: "git root path")
    private var customGitRootpath: String?

    // MARK: - Implementation

    public required init() {}

    public func run() async throws {
        try await Requirements.check()
        let config = try await ConfigFactory.getConfig(at: URL(with: customGitRootpath))
        tools = BuildCommandToolWrapper(config: config)
        InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
        do {
            let gitRootpath = await gitRootpath()

            let xcResultURLs = await tools.findXCResultfiles(at: gitRootpath).value

            guard let xcResultURLs, !xcResultURLs.isEmpty else {
                throw BuildError.noXCResultFilesFound(location: gitRootpath.fullPath)
            }

            var xcResults = xcResultURLs.compactMap { url -> XCResultFile? in
                try? XCResultFile(with: url)
            }

            let filterReports = tools.filterReports()

            xcResults = xcResults.include(applications: filterReports)

            guard !xcResults.isEmpty else {
                throw BuildError.noFilteredResults(filter: filterReports.joined(separator: ", "))
            }

            xcResults.sort(by: { $0.date.timeIntervalSinceReferenceDate > $1.date.timeIntervalSinceReferenceDate })

            var report: RawXCResult?

            if let lastRun = xcResults.first,
               let json = await tools.cliTools.xcResultTool(filePath: lastRun.url).value {
                logger.debug(lastRun.toFileName())
                report = try decodeReport(from: json)

//                let jsonRepresentable = formattedJsonContent(from: report)
            } else {
                throw BuildError.noFilteredResults(filter: "")
            }
            logger.debug(report.debugDescription)

        } catch {
            logger.error("Error: \(error: error)")
            if !quiet {
                if let errorable = error as? any Errorable, errorable.printsHelp {
                    print(Self.helpMessage())
                }

                throw error
            }
        }
    }
}

extension BuildCommand {
    enum BuildError: Error, CustomStringConvertible {
        case jsonContentMissing
        case stringToDataConversionFailed
        case noXCResultFilesFound(location: String)
        case noFilteredResults(filter: String)

        /// Retrieve the localized description for this error.
        var localizedDescription: String {
            switch self {
            case .jsonContentMissing:
                return "No Input provided"
            case .stringToDataConversionFailed:
                return "While converting JSON-String to data an error occured"
            case let .noXCResultFilesFound(location: location):
                return "Could not find any .xcresult files at \(location)"
            case let .noFilteredResults(filter: filter):
                return "After filtering the found xcresult file, there are none left to process(\(filter))"
            }
        }

        var description: String { localizedDescription }
    }
}

private extension BuildCommand {
    func decodeReport(from contentString: String) throws -> RawXCResult {
        guard let contentData = contentString.data(using: .utf8) else { throw BuildError.stringToDataConversionFailed }
        return try SingleDecoder.shared.decode(RawXCResult.self, from: contentData)
    }

    func formattedJsonContent(from report: RawXCResult, prettyPrint: Bool = true) -> String? {
        do {
            let data = try SingleEncoder.shared.encode(report)
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: prettyPrint ? .prettyPrinted : .sortedKeys)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return nil
        }
    }
}

extension BuildCommand {
    struct BuildCommandToolWrapper: Codable {
        let config: Config

        var fileHandler: FileHandler {
            get async {
                FileHandler()
            }
        }

        var cliTools: Tools { Tools() }

        init(config: Config) {
            self.config = config
        }

        func getGitRootDirectory() async -> URLResult {
            await fileHandler.getGitRootDirectory()
        }

        func getCurrentDirectoryUrl() async -> URL {
            await fileHandler.getCurrentDirectoryUrl()
        }

        func excludedTargets() -> [String] {
            config.excluded?.targets ?? []
        }

        func excludedFiles() -> [String] {
            config.excluded?.files ?? []
        }

        func excludedFunctions() -> [String] {
            config.excluded?.functions ?? []
        }

        func filterReports() -> [String] {
            config.filterXCResults ?? []
        }

        func findXCResultfiles(at path: URL) async -> URLArrayResult {
            await fileHandler.findXCResultfiles(at: path)
        }

        func xcResultTool(filePath: URL) async -> StringResult {
            await cliTools.xcResultTool(filePath: filePath)
        }
    }
}
