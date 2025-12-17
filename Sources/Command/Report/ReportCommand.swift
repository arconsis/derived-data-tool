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

public final class ReportCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "report",
        abstract: "Handle the reporting of the coverage"
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

    private static let prefixName: String = "name_"
    private static let prefixDescription: String = "description_"

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
                throw ReportCommandError.archiveMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")
            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()

            // Get reports
            let dateComponents = DateComponents(day: 2)
            let tomorrow = Calendar.current.date(byAdding: dateComponents, to: Date())
            let currentReport = try getLastReport(archiver: archiver, before: tomorrow)
            let previousReport = try getLastReport(archiver: archiver, before: currentReport.fileInfo.date)

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

            let data = try SingleEncoder.shared.encode(parameters)
            let object = try SingleDecoder.shared.decode(SlackHttpBody.self, from: data)

            let request = try await makePostRequest(with: object)

            let session = URLSession.shared
            _ = try await session.data(for: request)

        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }

    // MARK: - Private Helpers

    private func getLastReport(archiver: Archiver, before creationDate: Date? = nil) throws -> CoverageMetaReport {
        guard let report = try archiver.lastReport(before: creationDate ?? Date()) else {
            throw ReportCommandError.reportMissing
        }
        return report
    }

    private func makePostRequest(with object: Codable) async throws -> URLRequest {
        guard let webhook = ProcessInfo.processInfo.environment["SLACK_COVERAGE_WEBHOOK"],
              let url = URL(string: webhook)
        else {
            throw ReportCommandError.invalidWebhook
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        guard let body = try? SingleEncoder.shared.encode(object) else {
            throw ReportCommandError.invalidPayload
        }

        request.httpBody = body
        return request
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
