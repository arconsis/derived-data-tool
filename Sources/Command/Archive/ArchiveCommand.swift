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

public final class ArchiveCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "archive",
        abstract: "Work with the created archives"
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
        do {
            try await Requirements.check()

            // Use protocol methods
            setupLogger()
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)

            // Setup archive location
            guard let archive = config.locations?.archive else {
                throw ArchiveError.archiveLocationMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")
            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()

            logger.log("setup completed")

            // Find archive files
            let uncompressedArchives = try await fileHandler.findFiles(at: workingDirectory, with: "json").forcedValue()
            let compessedArchives = try await fileHandler.findFiles(at: workingDirectory, with: "zlib").forcedValue()
            _ = uncompressedArchives + compessedArchives

            // TODO: check file integrity
        } catch {
            logger.error("Error: \(error: error)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
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

