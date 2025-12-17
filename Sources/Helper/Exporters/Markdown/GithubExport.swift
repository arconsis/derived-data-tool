//
//  GithubExport.swift
//
//
//  Created by Moritz Ellerbrock on 14.06.23.
//

import DependencyInjection
import Foundation
import Shared

/// GitHubExporter
/// Discussion: some values are hardcoded for now but should be moved to the config
///  - TOP X ranked list
///  - LAST X ranked list
///
///  Maybe also the order OR types of List to export
///  - topRanked
///  - lastRanked
///  - detailed
///  - compare
///

public typealias GHConfig = GithubExport.GithubExportConfig

public class GithubExport {
    public struct GithubExportConfig {
        public let settings: GithubExportSettings
        public let reportUrl: URL
        public let archiveUrl: URL

        public init(settings: GithubExportSettings, reportUrl: URL, archiveUrl: URL) {
            self.settings = settings
            self.reportUrl = reportUrl
            self.archiveUrl = archiveUrl
        }
    }

    private let fileHandler: FileHandler
    private let archiver: Archiver
    private let reportUrl: URL
    private let archiveUrl: URL
    private let settings: GithubExportSettings

    @Injected(\.logger) private var logger: Loggerable

    public init(fileHandler: FileHandler,
                config: GithubExportConfig)
    {
        self.fileHandler = fileHandler
        settings = config.settings
        reportUrl = config.reportUrl
        archiveUrl = config.archiveUrl
        archiver = Archiver(fileHandler: fileHandler, archiveUrl: archiveUrl)
    }

    public func archiveReport(_ current: CoverageMetaReport) async {
        do {
            try await setupAndDelete()
            // archive CoverageReport-Content
            try await archiver.addReportToArchive(current)
        } catch {
            logger.error(error.localizedDescription)
            return
        }
    }

    public func createMarkDownReport(with current: CoverageMetaReport) async {
        do {
            try await setupAndDelete()

            // load archive
            let previous: CoverageMetaReport? = try? archiver.lastReport(before: current.fileInfo.date)

            // create new file
            let fileContent = createFileContent(with: current, previous: previous)
            try saveReport(content: fileContent, at: reportUrl)
        } catch {
            logger.error(error.localizedDescription)
            return
        }
    }

    private func setupAndDelete() async throws {
        try await archiver.setup()
        // delete old file
        deleteReport()
    }

    private func createFileContent(with current: CoverageMetaReport, previous: CoverageMetaReport?) -> String {
        var fileContent = ""
        fileContent += MarkdownEncoderType.header(meta: current).encode()
        fileContent += "\n"
        fileContent += MarkdownEncoderType.topRanked(amount: settings.top, report: current.coverage).encode()
        fileContent += "\n"
        fileContent += MarkdownEncoderType.lastRanked(amount: settings.last, report: current.coverage).encode()
        fileContent += "\n"
        fileContent += MarkdownEncoderType.uncovered(report: current.coverage).encode()
        fileContent += "\n"
        fileContent += MarkdownEncoderType.detailed(report: current.coverage).encode()
        fileContent += "\n"
        fileContent += MarkdownEncoderType.compare(current: current.coverage, previous: previous?.coverage).encode()
        fileContent += "\n"
        return fileContent
    }
}

// MARK: fileHandler Helpers

private extension GithubExport {
    func deleteReport() {
        do {
            try fileHandler.deleteFile(at: reportUrl)
        } catch {
            return
        }
    }

    func saveReport(content: String, at url: URL) throws {
        try fileHandler.writeContent(content, at: url)
    }
}

private extension GithubExport {
    enum GithubExportError: Error {
        case stringToDataConversionFailed
    }
}
