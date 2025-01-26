//
//  ArchiveCommand.swift
//
//
//  Created by Moritz Ellerbrock on 27.04.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class ArchiveCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(commandName: "archive", abstract: "Work with the created archives")

    private var tools: ArchiveCommandToolWrapper!

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
        try await Requirements.check()
        InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
        let config = try await ConfigFactory.getConfig(at: URL(with: configFilePath))
        tools = try await ArchiveCommandToolWrapper.make(config: config, workingDirectory: customGitRootpath)
        logger.log("setup completed")
        do {
            let uncompressedArchives = try await tools.findFiles(at: tools.workingDirectory, with: "json")
            let compessedArchives = try await tools.findFiles(at: tools.workingDirectory, with: "zlib")
            _ = uncompressedArchives + compessedArchives

            // TODO: check file integrity
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

private extension Coverage {
    func decodeReport(from contentData: Data) throws -> TargetReports {
        return try SingleDecoder.shared.decode(TargetReports.self, from: contentData)
    }

    func formattedJsonContent(from report: JSONReport, prettyPrint: Bool = true) -> String? {
        do {
            let data = try SingleEncoder.shared.encode(report)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: prettyPrint ? .prettyPrinted : .sortedKeys)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return nil
        }
    }
}

extension ArchiveCommand {
    enum ArchiveError: LocalizedError, CustomStringConvertible {
        case jsonContentMissing
        case noXCResultFilesFound(location: String)
        case noFilteredResults(filter: String)
        case noConfigFileFound
        case currentReportLocationMissing
        case archiveLocationMissing
        case noResultsToWorkWith
        case noResultFilesToConvert
        case internalError

        /// Retrieve the localized description for this error.
        var localizedDescription: String {
            switch self {
            case .jsonContentMissing:
                return "No Input provided"
            case let .noXCResultFilesFound(location: location):
                return "Could not find any .xcresult files at \(location)"
            case let .noFilteredResults(filter: filter):
                return "After filtering the found xcresult file, there are none left to process(\(filter))"
            case .noConfigFileFound:
                return "No Config file was found"
            case .currentReportLocationMissing:
                return "Add a `current_report` entry to locations in your config file!"
            case .archiveLocationMissing:
                return "Add a `archive` entry to locations in your config file!"
            case .noResultsToWorkWith:
                return "The filters and configurations set"
            case .internalError:
                return "This should not happen but it did, wait for an update, please"
            case .noResultFilesToConvert:
                return "There are no xcresult files to work with"
            }
        }

        var description: String { localizedDescription }
    }
}

extension ArchiveCommand {
    struct ArchiveCommandToolWrapper: Codable {
        private let config: Config
        let locationCurrentReport: String?
        let fileHandler: FileHandler
        let workingDirectory: URL
        let archiver: Archiver
        private let cliTools: Tools
        var archiveLocation: URL?

        var githubExporterSettering: GithubExportSettings {
            try! config.settings(.githubExporter) as! GithubExportSettings
        }

        private enum CodingKeys: String, CodingKey {
            case config,
                 locationCurrentReport,
                 workingDirectory,
                 archiveLocation
        }

        init(from _: Decoder) throws {
            throw ArchiveError.internalError
        }

        init(config: Config,
             locationCurrentReport: String?,
             fileHandler: FileHandler,
             archiver: Archiver,
             workingDirectory: URL,
             archiveLocation: URL?,
             cliTools: Tools)
        {
            self.config = config
            self.locationCurrentReport = locationCurrentReport
            self.fileHandler = fileHandler
            self.workingDirectory = workingDirectory
            self.cliTools = cliTools
            self.archiver = archiver
            self.archiveLocation = archiveLocation
        }

        @MainActor
        static func make(config: Config, workingDirectory: String?) async throws -> Self {
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

            guard let archive = config.locations?.archive else {
                throw ArchiveError.archiveLocationMissing
            }
            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")

            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()

            return .init(config: config,
                         locationCurrentReport: locationCurrentReport,
                         fileHandler: FileHandler(),
                         archiver: archiver,
                         workingDirectory: workingDirectory,
                         archiveLocation: archiveLocation,
                         cliTools: Tools())
        }
    }
}

extension ArchiveCommand.ArchiveCommandToolWrapper {
    func xccov(filePath: URL) async throws -> String {
        try await cliTools.xccov(filePath: filePath).forcedValue()
    }

    func findXCResultfiles(at path: URL) async throws -> [URL] {
        try await fileHandler.findXCResultfiles(at: path).forcedValue()
    }

    func findFiles(at url: URL, with fileExtension: String) async throws -> [URL] {
        try await fileHandler.findFiles(at: url, with: fileExtension).forcedValue()
    }

    func deleteFile(_ filename: String, at path: URL? = nil) async throws {
        try fileHandler.deleteFile(filename, at: path)
    }

    func writeContent(_ content: String, to filename: String, at path: URL? = nil, overwrite: Bool = false) async throws {
        try fileHandler.writeContent(content, to: filename, at: path, overwrite: overwrite)
    }
}
