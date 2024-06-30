//
//  CompareTool.swift
//
//
//  Created by Moritz Ellerbrock on 29.11.23.
//

import DependencyInjection
import Foundation
import Helper
import Shared

class CompareTool {
    private let verbose: Bool
    private let quiet: Bool
    private let workingDirectory: URL
    private let xcResultURLs: [URL]
    private let fileHandler: FileHandler
    private let tools: Tools
    private let archiveUrl: URL

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    init(workingDirectory: URL,
         xcResultURLs: [URL],
         fileHandler: FileHandler,
         tools: Tools,
         archiveUrl: URL,
         verbose: Bool,
         quiet: Bool)
    {
        self.workingDirectory = workingDirectory
        self.xcResultURLs = xcResultURLs
        self.fileHandler = fileHandler
        self.tools = tools
        self.archiveUrl = archiveUrl
        self.verbose = verbose
        self.quiet = quiet
    }

    static func xCResultfiles(at url: URL, fileHandler: FileHandler) async throws -> URLArrayResult {
        await fileHandler.findXCResultfiles(at: url)
    }
}

extension CompareTool: Runnable {
    func run() async throws {
        do {
            var xcResults = xcResultURLs.compactMap { url -> XCResultFile? in
                try? XCResultFile(with: url)
            }
            xcResults.sort(by: { $0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970 })

            logger.debug(xcResults)
            guard let reportFile = xcResults.first else {
                throw CompareError.noReportFileToCompareTo
            }

            let coverage = try await coverageReport(for: reportFile)

            let comparer = Comparer(fileHandler: fileHandler,
                                    tool: tools,
                                    archiveUrl: archiveUrl)

            _ = try await comparer.compare(coverage)
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            if !quiet {
                if let errorable = error as? any Errorable, errorable.printsHelp {
                    print(CompareCommand.helpMessage())
                }

                throw error
            }
        }
    }
}

private extension CompareTool {
    func findXCResultfiles(at url: URL) async throws -> URLArrayResult {
        await fileHandler.findXCResultfiles(at: url)
    }

    func coverageReport(for xcFile: XCResultFile) async throws -> CoverageReport {
        let jsonResult = await tools.xccov(filePath: xcFile.url)
        guard
            let json = jsonResult.value,
            let result = ReportGenerator.decodeFullXCOV(with: json).value
        else {
            throw CompareError.noReportFileToCompareTo
        }
        return result
    }
}
