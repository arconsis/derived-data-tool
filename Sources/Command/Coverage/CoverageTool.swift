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
    private static let reporterId: String = "CoverageTool"
    private let verbose: Bool
    private let quiet: Bool
    private let fileHandler: FileHandler
    private let cliTools: Tools
    private let githubExporterSetting: GithubExportSettings
    private let repository: ReportModelRepository
    private let thresholdSettings: ThresholdSettings?

    private let filterReports: [String]
    private let excludedPatterns: MatchPatternConfig
    private let includedPatterns: MatchPatternConfig

    private let workingDirectory: URL
    private let locationCurrentReport: URL
    private let archiveLocation: URL

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    init(fileHandler: FileHandler,
         cliTools: Tools,
         githubExporterSetting: GithubExportSettings,
         repository: ReportModelRepository,
         filterReports: [String],
         excludedTargets: [String],
         excludedFiles: [String],
         excludedFunctions: [String],
         includedTargets: [String],
         includedFiles: [String],
         includedFunctions: [String],
         workingDirectory: URL,
         locationCurrentReport: URL,
         archiveLocation: URL,
         thresholdSettings: ThresholdSettings? = nil,
         verbose: Bool = false,
         quiet: Bool = false)
    {
        self.verbose = verbose
        self.quiet = quiet
        self.fileHandler = fileHandler
        self.cliTools = cliTools
        self.githubExporterSetting = githubExporterSetting
        self.filterReports = filterReports
        self.workingDirectory = workingDirectory
        self.locationCurrentReport = locationCurrentReport
        self.archiveLocation = archiveLocation
        self.repository = repository
        self.thresholdSettings = thresholdSettings
        self.excludedPatterns = MatchPatternConfig(targets: excludedTargets,
                                                   files: excludedFiles,
                                                   functions: excludedFunctions)

        self.includedPatterns = MatchPatternConfig(targets: includedTargets,
                                                   files: includedFiles,
                                                   functions: includedFunctions)
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
                // process excluded List first (remove unwanted items)
                result = result.exclude(targets: excludedPatterns.targets)
                result = result.exclude(files: excludedPatterns.files)
                result = result.exclude(functions: excludedPatterns.functions)

                // process included List last (keep only wanted items from what's left)
                result = result.include(targets: includedPatterns.targets)
                result = result.include(files: includedPatterns.files)
                result = result.include(functions: includedPatterns.functions)

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
        do {
            guard coverageReports.count >= 1 else { throw CoverageError.noResultsToWorkWith }

            let sorted = coverageReports.sorted(by: { $0.fileInfo.date.timeIntervalSince1970 > $1.fileInfo.date.timeIntervalSince1970 })

            guard let current = sorted.first else { return }

            let ghConfig = GHConfig(settings: githubExporterSetting,
                                    reportUrl: locationCurrentReport,
                                    archiveUrl: archiveLocation)

            let githubExporter = GithubExport(fileHandler: fileHandler, config: ghConfig)

            await githubExporter.createMarkDownReport(with: current)

            try await repository.add(report: current)

            // Validate thresholds if configured
            try await validateThresholds(current: current)

            try await repository.shutDownDatabaseConnection()
        } catch {
            try? await repository.shutDownDatabaseConnection()
            throw error
        }
    }

    func validateThresholds(current: CoverageMetaReport) async throws {
        guard let settings = thresholdSettings else {
            // No threshold configuration, skip validation
            return
        }

        let validator = Helper.ThresholdValidator()
        var hasFailures = false

        // Validate absolute threshold if configured
        if let minCoverage = settings.minCoverage {
            let result = validator.validateAbsolute(coverage: current.coverage, minCoverage: minCoverage)
            if case .fail(let reason, let details) = result {
                logger.error(reason)
                printThresholdFailure(
                    type: "Absolute Coverage Threshold",
                    current: details.actual,
                    required: details.expected
                )
                hasFailures = true
            }
        }

        // Validate relative threshold if configured
        if let maxDrop = settings.maxDrop {
            let previousReport = try? await repository.getLatestReport()
            let previousCoverage = previousReport?.coverage

            let result = validator.validateRelative(current: current.coverage, previous: previousCoverage, maxDrop: maxDrop)
            if case .fail(let reason, let details) = result {
                logger.error(reason)
                printRelativeThresholdFailure(
                    currentCoverage: current.coverage.coverage * 100.0,
                    previousCoverage: previousCoverage?.coverage ?? 0.0 * 100.0,
                    maxAllowedDrop: details.expected,
                    actualDrop: details.actual
                )
                hasFailures = true
            }
        }

        // Validate per-target thresholds if configured
        if !settings.perTargetThresholds.isEmpty {
            let results = validator.validatePerTarget(coverage: current.coverage, thresholds: settings.perTargetThresholds)

            var failingTargets: [(name: String, current: Double, required: Double)] = []
            for result in results {
                if case .fail(let reason, let details) = result {
                    logger.error(reason)
                    if let targetName = details.targetName {
                        failingTargets.append((name: targetName, current: details.actual, required: details.expected))
                    }
                }
            }

            if !failingTargets.isEmpty {
                printPerTargetThresholdFailures(targets: failingTargets)
                hasFailures = true
            }
        }

        // Throw the first error encountered to maintain exit code behavior
        if hasFailures {
            if let minCoverage = settings.minCoverage {
                let currentCoveragePercent = current.coverage.coverage * 100.0
                if currentCoveragePercent < minCoverage {
                    throw CoverageError.thresholdFailedAbsolute(expected: minCoverage, actual: currentCoveragePercent)
                }
            }

            if let maxDrop = settings.maxDrop {
                let previousReport = try? await repository.getLatestReport()
                if let previousCoverage = previousReport?.coverage {
                    let currentCoveragePercent = current.coverage.coverage * 100.0
                    let previousCoveragePercent = previousCoverage.coverage * 100.0
                    let actualDrop = previousCoveragePercent - currentCoveragePercent
                    if actualDrop > maxDrop {
                        throw CoverageError.thresholdFailedRelative(maxDrop: maxDrop, actualDrop: actualDrop)
                    }
                }
            }

            if !settings.perTargetThresholds.isEmpty {
                for (targetName, config) in settings.perTargetThresholds {
                    if let target = current.coverage.targets.first(where: { $0.name == targetName }),
                       let minCoverage = config.minCoverage {
                        let targetCoveragePercent = target.coverage * 100.0
                        if targetCoveragePercent < minCoverage {
                            throw CoverageError.thresholdFailedPerTarget(target: targetName, expected: minCoverage, actual: targetCoveragePercent)
                        }
                    }
                }
            }
        }
    }

    func printThresholdFailure(type: String, current: Double, required: Double) {
        if quiet { return }

        print("\n❌ \(type) Failed")
        print("   Current:  \(String(format: "%.2f", current))%")
        print("   Required: \(String(format: "%.2f", required))%")
        print("   Gap:      \(String(format: "%.2f", required - current))%")
        print("\n💡 Action Required: Add tests to increase coverage by \(String(format: "%.2f", required - current)) percentage points\n")
    }

    func printRelativeThresholdFailure(currentCoverage: Double, previousCoverage: Double, maxAllowedDrop: Double, actualDrop: Double) {
        if quiet { return }

        print("\n❌ Relative Coverage Threshold Failed")
        print("   Previous:        \(String(format: "%.2f", previousCoverage))%")
        print("   Current:         \(String(format: "%.2f", currentCoverage))%")
        print("   Drop:            \(String(format: "%.2f", actualDrop))%")
        print("   Max Allowed:     \(String(format: "%.2f", maxAllowedDrop))%")
        print("   Exceeded By:     \(String(format: "%.2f", actualDrop - maxAllowedDrop))%")
        print("\n💡 Action Required: Restore test coverage to previous levels or improve it\n")
    }

    func printPerTargetThresholdFailures(targets: [(name: String, current: Double, required: Double)]) {
        if quiet { return }

        print("\n❌ Per-Target Coverage Thresholds Failed")
        print("   The following targets did not meet their coverage requirements:\n")

        for target in targets {
            print("   • \(target.name)")
            print("     Current:  \(String(format: "%.2f", target.current))%")
            print("     Required: \(String(format: "%.2f", target.required))%")
            print("     Gap:      \(String(format: "%.2f", target.required - target.current))%")
            print()
        }

        print("💡 Action Required: Add tests for the targets listed above\n")
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

private extension CoverageTool {
    private var progressReporter: ProgressReporterFactory {
        ProgressReporterFactory.default
    }


    func report(percentage: Double) {
        progressReporter.report(percentage: percentage, onReporterWith: Self.reporterId)
    }

    func report(step: Int, of totalSteps: Int, inPercentage: Bool) {
        progressReporter.report(step: step, of: totalSteps, inPercentage: inPercentage, onReporterWith: Self.reporterId)
    }

    func report(finished: Bool) {
        progressReporter.report(finished: finished, onReporterWith: Self.reporterId)
    }

    func report(text: String, clearLine: Bool) {
        progressReporter.report(text: text, clearLine: clearLine, onReporterWith: Self.reporterId)
    }
}
