//
//  PRCommentCommand.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import ArgumentParser
import DependencyInjection
import Foundation
import Helper
import Shared

public final class PRCommentCommand: DerivedDataCommand, QuietErrorHandling {
    public static let configuration = CommandConfiguration(
        commandName: "pr-comment",
        abstract: "Post coverage summary as a comment to a GitHub Pull Request",
        discussion: """
            Generates and posts a formatted coverage summary as a comment on the specified GitHub Pull Request. \
            Includes overall coverage percentage, change from base, top files with biggest coverage changes, and \
            new untested files. Uses GITHUB_TOKEN environment variable for authentication. Updates existing \
            comment on subsequent runs instead of creating duplicate comments.
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

    @Option(name: [.customShort("g"), .customLong("gitroot")])
    public var customGitRootpath: String?

    @Option(name: [.customShort("p"), .customLong("pr-number")], help: "GitHub Pull Request number")
    private var prNumber: Int

    @Option(name: [.customShort("r"), .customLong("repo")], help: "GitHub repository name (e.g., 'my-repo')")
    private var repository: String

    @Option(name: [.customShort("o"), .customLong("owner")], help: "GitHub repository owner (e.g., 'my-org' or 'username')")
    private var owner: String

    enum CodingKeys: CodingKey {
        case verbose, quiet, configFilePath, customGitRootpath, prNumber, repository, owner
    }

    public required init() {}

    public func run() async throws {
        do {
            // Use protocol methods
            setupLogger()
            logger.debug("PR Comment subcommand: started")

            try await Requirements.check()
            let config = try await loadConfig()
            let fileHandler = makeFileHandler()
            let workingDirectory = await resolveWorkingDirectory(using: fileHandler)

            logger.debug("Working directory: \(workingDirectory.fullPath)")
            logger.debug("PR Number: \(prNumber), Repository: \(owner)/\(repository)")

            // Setup archive location
            guard let archive = config.locations?.archive else {
                throw PRCommentError.archiveMissing
            }

            let archiveLocation = workingDirectory.appending(pathComponent: "\(archive)/")
            logger.debug("Archive location: \(archiveLocation.fullPath)")

            let archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveLocation)
            try await archiver.setup()

            // Get reports
            let dateComponents = DateComponents(day: 2)
            let tomorrow = Calendar.current.date(byAdding: dateComponents, to: Date())
            let currentReport = try getLastReport(archiver: archiver, before: tomorrow)
            let previousReport = try getLastReport(archiver: archiver, before: currentReport.fileInfo.date)

            logger.debug("Current report loaded: \(currentReport.coverage.printableCoverage)%")
            logger.debug("Previous report loaded: \(previousReport.coverage.printableCoverage)%")

            // Get GitHub exporter settings
            guard let githubExporterSettings = try config.settings(.githubExporter) as? GithubExportSettings else {
                throw PRCommentError.configError
            }

            // Initialize GitHub API client
            let githubClient = try GitHubAPIClient()
            logger.debug("GitHub API client initialized")

            // Format PR comment using config settings
            let formatter = PRCommentFormatter()
            let commentBody = formatter.format(
                current: currentReport,
                previous: previousReport,
                topFiles: githubExporterSettings.prCommentTopFiles,
                includeUntested: githubExporterSettings.prCommentIncludeUntested
            )
            logger.debug("Coverage comment formatted (top files: \(githubExporterSettings.prCommentTopFiles), include untested: \(githubExporterSettings.prCommentIncludeUntested))")

            // Check for existing comment to update instead of creating duplicate
            let existingComment = try await githubClient.findExistingComment(
                owner: owner,
                repo: repository,
                prNumber: prNumber,
                marker: formatter.marker()
            )

            // Post or update comment
            if let existing = existingComment {
                logger.debug("Updating existing comment (ID: \(existing.id))")
                _ = try await githubClient.updateComment(
                    owner: owner,
                    repo: repository,
                    commentId: existing.id,
                    body: commentBody
                )
                logger.log("Successfully updated coverage comment on PR #\(prNumber)")
            } else {
                logger.debug("Creating new comment")
                _ = try await githubClient.createComment(
                    owner: owner,
                    repo: repository,
                    prNumber: prNumber,
                    body: commentBody
                )
                logger.log("Successfully created coverage comment on PR #\(prNumber)")
            }

            logger.debug("PR Comment subcommand: completed")

        } catch {
            logger.error("Error: \(error.localizedDescription)")
            try handle(error: error, quietly: quiet, helpMessage: Self.helpMessage())
        }
    }

    // MARK: - Private Helpers

    private func getLastReport(archiver: Archiver, before creationDate: Date? = nil) throws -> CoverageMetaReport {
        guard let report = try archiver.lastReport(before: creationDate ?? Date()) else {
            throw PRCommentError.reportMissing
        }
        return report
    }
}

extension PRCommentCommand {
    enum PRCommentError: LocalizedError {
        case archiveMissing
        case gitHubTokenMissing
        case reportMissing
        case apiError(String)
        case configError

        public var errorDescription: String? {
            switch self {
            case .archiveMissing:
                return "Archive location is missing from configuration"
            case .gitHubTokenMissing:
                return "GITHUB_TOKEN environment variable is not set"
            case .reportMissing:
                return "No coverage report found in archive"
            case .apiError(let message):
                return "GitHub API error: \(message)"
            case .configError:
                return "GitHub exporter settings are missing from configuration"
            }
        }
    }
}
