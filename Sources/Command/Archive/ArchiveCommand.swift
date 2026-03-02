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
        abstract: "Manage and verify archived coverage reports",
        discussion: """
            Manages the archive directory containing historical coverage reports. Verifies \
            the integrity of stored JSON and compressed reports used for trend analysis and \
            comparison.
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

            // Check file integrity
            let allArchives = archiver.sortedArchives
            logger.log("Validating integrity of \(allArchives.count) archive file(s)...")

            var validCount = 0
            var legacyCount = 0
            var corruptedCount = 0

            for archivedFile in allArchives {
                do {
                    let report = try archiver.report(for: archivedFile)
                    if report.checksum != nil {
                        logger.log("✓ \(archivedFile.url.lastPathComponent) - Valid (with checksum)")
                        validCount += 1
                    } else {
                        logger.warn("⚠ \(archivedFile.url.lastPathComponent) - Legacy file (no checksum)")
                        legacyCount += 1
                    }
                } catch {
                    // Check if it's a checksum mismatch error
                    let errorString = error.localizedDescription
                    if errorString.contains("checksumMismatch") {
                        logger.error("✗ \(archivedFile.url.lastPathComponent) - CORRUPTED (checksum mismatch)")
                        logger.error("  \(errorString)")
                        corruptedCount += 1
                    } else {
                        logger.error("✗ \(archivedFile.url.lastPathComponent) - Error: \(errorString)")
                    }
                }
            }

            // Summary
            logger.log("")
            logger.log("Integrity validation summary:")
            logger.log("  Valid files: \(validCount)")
            logger.log("  Legacy files (no checksum): \(legacyCount)")
            logger.log("  Corrupted files: \(corruptedCount)")

            if corruptedCount > 0 {
                throw ArchiveError.integrityValidationFailed(corruptedCount: corruptedCount)
            }
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
        case integrityValidationFailed(corruptedCount: Int)

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
            case let .integrityValidationFailed(corruptedCount: count):
                return "Archive integrity validation failed: \(count) corrupted file(s) detected"
            }
        }

        var description: String { localizedDescription }
    }
}

