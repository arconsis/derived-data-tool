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

public final class BuildCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Inspect build process and test results"
    )

    public var logger: Loggerable {
        InjectedValues[\.logger]
    }

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    @Flag(help: "activate extra logging")
    public var verbose: Bool = false

    @Option(name: [.customShort("c"), .customLong("config")], help: "Path to the .xcrtool.yml")
    public var configFilePath: String?

    @Option(name: [.customShort("g"), .customLong("gitroot")], help: "git root path")
    public var customGitRootpath: String?

    enum CodingKeys: CodingKey {
        case quiet, verbose, configFilePath, customGitRootpath
    }

    public required init() {}

    public func run() async throws {
        do {
            try await Requirements.check()

            // Use protocol methods
            setupLogger()
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let gitRootpath = await resolveWorkingDirectory(using: fileHandler)

            // Find xcresult files
            let xcResultURLs = await fileHandler.findXCResultfiles(at: gitRootpath).value

            guard let xcResultURLs, !xcResultURLs.isEmpty else {
                throw BuildError.noXCResultFilesFound(location: gitRootpath.fullPath)
            }

            var xcResults = xcResultURLs.compactMap { url -> XCResultFile? in
                try? XCResultFile(with: url)
            }

            let filterReports = config.filterXCResults ?? []

            xcResults = xcResults.include(applications: filterReports)

            guard !xcResults.isEmpty else {
                throw BuildError.noFilteredResults(filter: filterReports.joined(separator: ", "))
            }

            xcResults.sort(by: { $0.date.timeIntervalSinceReferenceDate > $1.date.timeIntervalSinceReferenceDate })

            var report: RawXCResult?

            if let lastRun = xcResults.first,
               let json = await makeTools().xcResultTool(filePath: lastRun.url).value {
                logger.debug(lastRun.toFileName())
                report = try decodeReport(from: json)

//                let jsonRepresentable = formattedJsonContent(from: report)
            } else {
                throw BuildError.noFilteredResults(filter: "")
            }
            logger.debug(report.debugDescription)

        } catch {
            logger.error("Error: \(error: error)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
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

