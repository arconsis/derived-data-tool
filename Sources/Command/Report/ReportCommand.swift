//
//  ReportCommand.swift
//
//
//  Created by Moritz Ellerbrock on 03.07.23.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class ReportCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(commandName: "report", abstract: "Handle the reporting of the coverage")

    private var tools: ReportCommandToolWrapper!

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    @Flag(help: "activate extra logging")
    private var verbose: Bool = false

    @Flag(help: "suppress failure")
    private var quiet: Bool = false

    public init() {}

    private static let prefixName: String = "name_"
    private static let prefixDescription: String = "description_"

    public func run() async throws {
        try await Requirements.check()
        InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
        let config = try await ConfigFactory.getConfig()
        tools = try await ReportCommandToolWrapper.make(config: config)
        do {
            let dateComponents = DateComponents(day: 2)
            let tomorrow = Calendar.current.date(byAdding: dateComponents, to: Date())
            let currentReport = try tools.getLastReport(before: tomorrow)
            let previousReport = try tools.getLastReport(before: currentReport.fileInfo.date)

            let compared = ComparingTargets.combine(currentReport, previousReport)
                .sorted(by: { $0.differenceCoverage > $1.differenceCoverage })

            var parameters = [String: String]()

            for index in 0 ... 4 {
                parameters["\(Self.prefixName)\(index + 1)"] = (compared[index].name)

                let detailedDescription = "(\(compared[index].differenceCoverageString)%)    @\(compared[index].currentCoverageString)%"
                parameters["\(Self.prefixDescription)\(index + 1)"] = detailedDescription
            }

            parameters["overall_coverage"] = "\(currentReport.coverage.printableCoverage)%"

            if let mostCoveredTarget = currentReport.coverage.mostCoveredTarget {
                parameters["most_coverage_target"] = mostCoveredTarget.printableName
                parameters["coverage"] = "\(mostCoveredTarget.printableCoverage)%"
            } else {
                parameters["most_coverage_target"] = ""
                parameters["coverage"] = ""
            }

            let data = try JSONEncoder().encode(parameters)
            let object = try JSONDecoder().decode(SlackHttpBody.self, from: data)

            let request = try await tools.postRequest(with: object)

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
}

extension ReportCommand {
    enum ReportCommandError: LocalizedError {
        case archiveMissing
        case invalidWebhook
        case invalidPayload
        case internalError
        case reportMissing
        case slackTokenMissing
    }
}

extension ReportCommand {
    struct ReportCommandToolWrapper: Codable {
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
            throw ReportError.internalError
        }

        func encode(to _: Encoder) throws {
            throw ReportError.internalError
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
                throw ReportError.archiveMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")

            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()

            return .init(config: config,
                         fileHandler: fileHandler,
                         archiver: archiver,
                         workingDirectory: workingDirectory,
                         archiveLocation: archiveLocation)
        }
    }
}

extension ReportCommand.ReportCommandToolWrapper {
    typealias ReportError = ReportCommand.ReportCommandError
    func getLastReport(before creationDate: Date? = nil) throws -> CoverageMetaReport {
        guard let report = try archiver.lastReport(before: creationDate ?? Date()) else {
            throw ReportError.reportMissing
        }
        return report
    }

    func postRequest(with object: Codable) async throws -> URLRequest {
        guard let webhook = ProcessInfo.processInfo.environment["SLACK_COVERAGE_WEBHOOK"],
              let url = URL(string: webhook)
        else {
            throw ReportError.invalidWebhook
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        guard let body = try? JSONEncoder().encode(object) else {
            throw ReportError.invalidPayload
        }

        request.httpBody = body
        return request
    }
}

extension ReportCommand {
    struct SlackHttpBody: Codable {
        let overallCoverage: String
        let mostCoverageTarget: String
        let coverage: String

        let name1: String
        let description1: String

        let name2: String
        let description2: String

        let name3: String
        let description3: String

        let name4: String
        let description4: String

        let name5: String
        let description5: String

        private enum CodingKeys: String, CodingKey {
            case overallCoverage = "overall_coverage"
            case mostCoverageTarget = "most_coverage_target"
            case coverage
            case name1 = "name_1"
            case name2 = "name_2"
            case name3 = "name_3"
            case name4 = "name_4"
            case name5 = "name_5"
            case description1 = "description_1"
            case description2 = "description_2"
            case description3 = "description_3"
            case description4 = "description_4"
            case description5 = "description_5"
        }
    }
}
