//
//  CoverageTool.swift
//
//
//  Created by Moritz Ellerbrock on 28.11.23.
//

import DependencyInjection
import Foundation
import Helper
import Shared

class CoverageTool {
    private let verbose: Bool
    private let quiet: Bool
    private let fileHandler: FileHandler
    private let cliTools: Tools
    private let githubExporterSetting: GithubExportSettings

    private let filterReports: [String]
    private let excludedTargets: [String]
    private let excludedFiles: [String]
    private let excludedFunctions: [String]

    private let workingDirectory: URL
    private let locationCurrentReport: URL
    private let archiveLocation: URL

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    init(fileHandler: FileHandler,
         cliTools: Tools,
         githubExporterSetting: GithubExportSettings,
         filterReports: [String],
         excludedTargets: [String],
         excludedFiles: [String],
         excludedFunctions: [String],
         workingDirectory: URL,
         locationCurrentReport: URL,
         archiveLocation: URL,
         verbose: Bool = false,
         quiet: Bool = false)
    {
        self.verbose = verbose
        self.quiet = quiet
        self.fileHandler = fileHandler
        self.cliTools = cliTools
        self.githubExporterSetting = githubExporterSetting
        self.filterReports = filterReports
        self.excludedTargets = excludedTargets
        self.excludedFiles = excludedFiles
        self.excludedFunctions = excludedFunctions
        self.workingDirectory = workingDirectory
        self.locationCurrentReport = locationCurrentReport
        self.archiveLocation = archiveLocation
    }
}

extension CoverageTool: Runnable {
    func run() async throws {
        do {
            logger.log("setup completed")

            let xcResults = try await xcfiles(from: workingDirectory)
            logger.log("found \(xcResults.count) relevant reports")
            let codeCoverageReports = try await coverageMetaReport(from: xcResults)

            logger.log("processing reports")
            try await process(codeCoverageReports, rootUrl: workingDirectory)

        } catch {
            logger.error("Error: \(error: error)")
            if !quiet {
                print(CoverageCommand.helpMessage())
                throw error
            }
        }
    }
}

private extension CoverageTool {
    func xcfiles(from workingDirectory: URL) async throws -> [XCResultFile] {
        guard
            let xcResultURLs = try? await crawlDerivedDataFolder(workingDirectory: workingDirectory)
        else {
            throw CoverageError.noXCResultFilesFound(location: workingDirectory.fullPath)
        }

        var xcResults = xcResultURLs.compactMap { url -> XCResultFile? in
            try? XCResultFile(with: url)
        }

        xcResults = xcResults.include(applications: filterReports)

        guard !xcResults.isEmpty else {
            throw CoverageError.noFilteredResults(filter: filterReports.joined(separator: ", "))
        }

        xcResults.sort(by: { $0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970 })

        return xcResults
    }

    func crawlDerivedDataFolder(workingDirectory: URL) async throws -> [URL] {
        if let workingDirectoryUrls = await findXCResultfiles(at: workingDirectory).value,
           !workingDirectoryUrls.isEmpty
        {
            return workingDirectoryUrls
        }

        // fallback to default location for DerivedData
        var homeDirecotry = try await homeDirectory()
        homeDirecotry = homeDirecotry.appending(pathComponent: "Library")
        homeDirecotry = homeDirecotry.appending(pathComponent: "Developer")
        homeDirecotry = homeDirecotry.appending(pathComponent: "Xcode")
        homeDirecotry = homeDirecotry.appending(pathComponent: "DerivedData")

        let xcHomeUrls = await findXCResultfiles(at: homeDirecotry).value

        if let xcHomeUrls, !xcHomeUrls.isEmpty {
            return xcHomeUrls
        }

        throw CoverageError.noXCResultFilesFound(location: homeDirecotry.fullPath)
    }

    func coverageMetaReport(from resultFiles: [XCResultFile]) async throws -> [CoverageMetaReport] {
        var codeCoverageReports: [CoverageMetaReport] = []

        for xcResult in resultFiles {
            if let json = await xccov(filePath: xcResult.url).value,
               var result = ReportGenerator.decodeFullXCOV(with: json).value {
                result = result.exclude(targets: excludedTargets)

                result = result.exclude(files: excludedFiles)

                result = result.exclude(functions: excludedFunctions)

                let meta = CoverageMetaReport(fileInfo: xcResult, coverage: result)
                codeCoverageReports.append(meta)
            }
        }

        guard codeCoverageReports.count > 0 else {
            throw CoverageError.noResultFilesToConvert
        }

        return codeCoverageReports
    }

    func process(_ coverageReports: [CoverageMetaReport],
                 rootUrl _: URL) async throws
    {
        guard coverageReports.count >= 1 else { throw CoverageError.noResultsToWorkWith }

        let sorted = coverageReports.sorted(by: { $0.fileInfo.date.timeIntervalSince1970 > $1.fileInfo.date.timeIntervalSince1970 })

        guard let current = sorted.first else { return }

        let ghConfig = GHConfig(settings: githubExporterSetting,
                                reportUrl: locationCurrentReport,
                                archiveUrl: archiveLocation)

        let githubExporter = await GithubExport(fileHandler: fileHandler,
                                                config: ghConfig)

        await githubExporter.createReport(from: current)
    }
}

// MARK: Helper

private extension CoverageTool {
    func findXCResultfiles(at path: URL) async -> URLArrayResult {
        await fileHandler.findXCResultfiles(at: path)
    }

    func homeDirectory() async throws -> URL {
        try await fileHandler.homeDirectory()
    }

    func xccov(filePath: URL) async -> StringResult {
        await cliTools.xccov(filePath: filePath)
    }
}
