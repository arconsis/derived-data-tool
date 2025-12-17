//
//  PrototypeCommand.swift
//
//
//  Created by Moritz Ellerbrock on 30.04.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class PrototypeCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Playground to test new tools"
    )

    public var logger: Loggerable {
        InjectedValues[\.logger]
    }

    @Flag(help: "activate extra logging")
    public var verbose: Bool = false

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    @Option(name: [.customShort("c"), .customLong("config")])
    public var configFilePath: String?

    @Option(name: [.customShort("g"), .customLong("gitroot")])
    public var customGitRootpath: String?

    enum CodingKeys: CodingKey {
        case verbose, quiet, configFilePath, customGitRootpath
    }

    public init() {}

    public func run() async throws {
        do {
            try await Requirements.check()

            // Use protocol methods - note: hardcoded verbose=true for this test command
            InjectedValues[\.logger] = MyLogger.makeLogger(verbose: true)
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)

            // Setup archive location
            guard let archive = config.locations?.archive else {
                throw PrototypeError.archiveMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")
            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)

            // Get last report
            let lastReport = try getLastReport(archiver: archiver)
            let sortedTargets = lastReport.coverage.targets.sorted(by: { $0.coverage > $1.coverage })

            let parameters: [String: String] = [
                "name_1": sortedTargets[0].name,
                "coverage_1": sortedTargets[0].printableCoverage,
                "name_2": sortedTargets[1].name,
                "coverage_2": sortedTargets[1].printableCoverage,
                "name_3": sortedTargets[2].name,
                "coverage_3": sortedTargets[2].printableCoverage,
                "name_4": sortedTargets[3].name,
                "coverage_4": sortedTargets[3].printableCoverage,
                "name_5": sortedTargets[4].name,
                "coverage_5": sortedTargets[4].printableCoverage,
            ]

            let request = try await makePostRequest(parameters: parameters)

            let session = URLSession.shared
            _ = try await session.data(for: request)

        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }

    // MARK: - Private Helpers

    private func getLastReport(archiver: Archiver) throws -> CoverageMetaReport {
        guard let report = try archiver.lastReport() else {
            throw PrototypeError.reportMissing
        }
        return report
    }

    private func makePostRequest(parameters: [String: Any]) async throws -> URLRequest {
        guard let webhook = ProcessInfo.processInfo.environment["SLACK_COVERAGE_WEBHOOK"],
              let url = URL(string: webhook)
        else {
            throw PrototypeError.invalidWebhook
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            throw PrototypeError.invalidPayload
        }
        request.httpBody = httpBody
        return request
    }

    func useStandardsForOutputAndErrors() throws {
        // Create a file handle to work with
        let standardOutput = FileHandle.standardOutput

        // Build up a string; whatever you want
        let stuff = "something"
        let something = "I'm a string with \(stuff) in it\n"
        guard let data = something.data(using: .utf8) else {
            throw PrototypeError.internalError
        }

        standardOutput.write(data)
    }

    func testFileHandler() async throws {
//        let fileHandler = FileHandler()
//
//        let url = try fileHandler.getGitRootDirectory()
//        let locations = try fileHandler.findFiles(at: url, with: "xcresult")
//        for location in locations {
//            let json = try await fileHandler.xccov(filePath: location)
        ////            print(json)
//        }
        ////        print(locations)
    }
}

extension PrototypeCommand {
    enum PrototypeError: LocalizedError {
        case jsonContentMissing
        case archiveMissing
        case reportMissing
        case invalidWebhook
        case invalidPayload
        case internalError
    }
}

