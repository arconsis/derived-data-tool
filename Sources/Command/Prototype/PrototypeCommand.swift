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

public final class PrototypeCommand: AsyncParsableCommand {
    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    private var tools: PrototypeCommandToolWrapper!

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    public init() {}

    public static let configuration = CommandConfiguration(commandName: "test", abstract: "Playground to test new tools")

    public func run() async throws {
        try await Requirements.check()
        InjectedValues[\.logger] = MyLogger.makeLogger(verbose: true)
        let config = try await ConfigFactory.getConfig()
        tools = try await PrototypeCommandToolWrapper.make(config: config)
        do {
            let lastReport = try tools.getLastReport()
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

            let request = try await tools.postRequest(parameters: parameters)

            let session = URLSession.shared
            _ = try await session.data(for: request)

        } catch {
            logger.error("Error: \(error.localizedDescription)")
            if !quiet {
                if let errorable = error as? any Errorable, errorable.printsHelp {
                    print(Self.helpMessage())
                }

                throw error
            }
        }
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

extension PrototypeCommand {
    struct PrototypeCommandToolWrapper: Codable {
        private let config: Config
        let fileHandler: FileHandler
        var archiver: Archiver
        let workingDirectory: URL
        var archiveLocation: URL?

        init(config: Config,
             fileHandler: FileHandler,
             archiver: Archiver,
             workingDirectory: URL,
             archiveLocation: URL?)
        {
            self.config = config
            self.fileHandler = fileHandler
            self.archiver = archiver
            self.workingDirectory = workingDirectory
            self.archiveLocation = archiveLocation
        }

        init(from _: Decoder) throws {
            throw PrototypeError.internalError
        }

        func encode(to _: Encoder) throws {
            throw PrototypeError.internalError
        }

        @MainActor
        static func make(config: Config) async throws -> Self {
            let fileHandler = FileHandler()

            let workingDirectory: URL = await {
                if let gitRoot = await fileHandler.getGitRootDirectory().value {
                    return gitRoot
                } else {
                    return fileHandler.getCurrentDirectoryUrl()
                }
            }()

            guard let archive = config.locations?.archive else {
                throw PrototypeError.archiveMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")

            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)

            return .init(config: config,
                         fileHandler: fileHandler,
                         archiver: archiver,
                         workingDirectory: workingDirectory,
                         archiveLocation: archiveLocation)
        }
    }
}

extension PrototypeCommand.PrototypeCommandToolWrapper {
    typealias PrototypeError = PrototypeCommand.PrototypeError
    func getLastReport() throws -> CoverageMetaReport {
        guard let report = try archiver.lastReport() else {
            throw PrototypeError.reportMissing
        }
        return report
    }

    func postRequest(parameters: [String: Any]) async throws -> URLRequest {
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
}
