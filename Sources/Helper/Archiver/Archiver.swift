//
//  Archiver.swift
//
//
//  Created by Moritz Ellerbrock on 26.06.23.
//

import DependencyInjection
import Foundation
import Shared

/// The Archiver
/// should handle the archiving process of the old reports
/// as a first draft the last report should be saved as clear text JSON, every older report will be compressed as zlib
///
/// Discussion: some values are hardcoded for now but should be moved to the config
/// Not sure what yet
///
///

public class Archiver: HelperProtocol {
    private static let uncompressedFile = ".json"
    private static let compressedFile = ".zlib"

    @Injected(\.logger) private var logger: Loggerable

    private let fileHandler: FileHandler
    private let archiveUrl: URL
    private var archives: [ArchivedFile] = []
    private let coder = CoverageMetaReportCoder()
    private var isSetup: Bool = false

    public var sortedArchivedUrls: [URL] {
        sortedArchives.map { $0.url }
    }

    public var sortedArchives: [ArchivedFile] {
        archives.sorted { $0.date > $1.date }
    }

    public init(fileHandler: FileHandler, archiveUrl: URL) {
        self.fileHandler = fileHandler
        self.archiveUrl = archiveUrl
    }

    public func setup() async throws {
        try await setScannedArchiveDirectory()
    }

    func addReportToArchive(_ report: CoverageMetaReport) async throws {
        try await prepareExistingArchives(lastReportDate: report.fileInfo.date)

        try await writeReportToDisk(report)

        try await setScannedArchiveDirectory()
    }

    public func lastReport(before creationDate: Date = Date()) throws -> CoverageMetaReport? {
        let relevantArchives = sortedArchives.filter { !Calendar.current.isDate($0.date, equalTo: creationDate, toGranularity: .day) }
        guard let archive = relevantArchives.first else { return nil }
        return try report(for: archive)
    }

    public func allReports() throws -> [CoverageMetaReport] {
        try archives.map { try report(for: $0) }
    }

    public func report(for archive: ArchivedFile) throws -> CoverageMetaReport {
        return try coder.decode(contentOf: archive.url)
    }
}

private extension Archiver {
    func setScannedArchiveDirectory() async throws {
        archives = await scanArchiveDirectory()
        isSetup = true
    }

    func scanArchiveDirectory() async -> [ArchivedFile] {
        let json = await fileHandler.findFiles(at: archiveUrl, with: "json").value ?? []
        let zlib = await fileHandler.findFiles(at: archiveUrl, with: "zlib").value ?? []
        let files = json + zlib
        return files.compactMap { ArchivedFile(url: $0) }
    }

    func convertUncompressedReportToCompressed(_: URL) throws {}

    func archiveNewReport(_: CoverageMetaReport) throws -> URL {
        return URL(fileReferenceLiteralResourceName: "")
    }


    func prepareExistingArchives(lastReportDate: Date) async throws {
        await prepareArchiver()
        archives = archives.filter { !Calendar.current.isDate($0.date, equalTo: lastReportDate, toGranularity: .day) }
        for archive in archives where !archive.isCompressed {
            let report: CoverageMetaReport = try coder.decode(contentOf: archive.url)
            try fileHandler.deleteFile(at: archive.url)
            let compressedData = try coder.encode(report)
            var url = archive.url
            url.replaceFileExtension(with: "zlib")
            try fileHandler.writeData(compressedData, at: url)
        }
    }

    func writeReportToDisk(_ report: CoverageMetaReport) async throws {
        let data = try coder.encode(report, compressed: false)
        let filename = "\(DateFormat.yearMontDay.string(from: report.fileInfo.date))\(Self.uncompressedFile)"
        let url = archiveUrl.appending(pathComponent: filename)
        try fileHandler.writeData(data, at: url)
    }

    func prepareArchiver() async {
        if isSetup { return }
        else {
            try? await setup()
        }
    }
}

public extension Archiver {
    struct ArchivedFile {
        public let url: URL
        public let isCompressed: Bool
        public let date: Date

        init?(url: URL) {
            self.url = url
            let filename = url.lastPathComponent // 2023-06-06.zlib || 2023-06-06.json
            let filenameParts = filename.split(separator: ".")
            guard
                let dateString = filenameParts.first.map(String.init),
                let date = DateFormat.yearMontDay.date(from: dateString),
                let fileExtension = filenameParts.last
            else {
                return nil
            }

            self.date = date
            isCompressed = fileExtension == "zlib"
        }
    }
}
