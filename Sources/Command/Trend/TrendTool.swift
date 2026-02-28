//
//  TrendTool.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import DependencyInjection
import Foundation
import Helper
import Shared

class TrendTool {
    private let verbose: Bool
    private let quiet: Bool
    private let fileHandler: FileHandler
    private let repository: ReportModelRepository

    private let days: Int?
    private let limit: Int?
    private let targetFilters: [String]
    private let threshold: Double?
    private let outputPath: URL

    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    init(fileHandler: FileHandler,
         repository: ReportModelRepository,
         days: Int? = nil,
         limit: Int? = nil,
         targetFilters: [String] = [],
         threshold: Double? = nil,
         outputPath: URL,
         verbose: Bool = false,
         quiet: Bool = false)
    {
        self.verbose = verbose
        self.quiet = quiet
        self.fileHandler = fileHandler
        self.repository = repository
        self.days = days
        self.limit = limit
        self.targetFilters = targetFilters
        self.threshold = threshold
        self.outputPath = outputPath
    }
}

extension TrendTool: Runnable {
    func run() async throws {
        do {
            logger.log("setup completed")

            // Fetch reports from database
            let reports = try await fetchReports()
            logger.log("found \(reports.count) coverage reports")

            // Validate minimum data points
            guard reports.count >= 2 else {
                throw TrendError.insufficientDataPoints(minimum: 2)
            }

            // Transform to chart data
            let chartData = try buildChartData(from: reports)
            logger.log("built chart data with \(chartData.overallTrend.count) data points")

            // Generate SVG
            let svgGenerator = SVGChartGenerator(chartData: chartData)
            let svg = svgGenerator.generateSVG()
            logger.log("generated SVG chart")

            // Write to file
            try fileHandler.writeContent(svg, at: outputPath, overwrite: true)
            logger.log("wrote chart to \(outputPath.fullPath)")

            if !quiet {
                print("✅ Coverage trend chart generated successfully")
                print("📊 Output: \(outputPath.fullPath)")
                print("📈 Data points: \(reports.count)")
                if let targetTrends = chartData.targetTrends {
                    print("🎯 Targets: \(targetTrends.map { $0.name }.joined(separator: ", "))")
                }
            }

            // Shutdown database connection on success
            try await repository.shutDownDatabaseConnection()
        } catch {
            // Shutdown database connection on error
            try? await repository.shutDownDatabaseConnection()

            logger.error("Error: \(error: error)")
            if !quiet {
                print("❌ Error generating trend chart: \(error.localizedDescription)")
            }
            throw error
        }
    }
}

private extension TrendTool {
    func fetchReports() async throws -> [ReportModel] {
        let reports: [ReportModel]

        if let days = days {
            // Fetch reports from last N days
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            reports = try await repository.fetchReports(since: startDate)
        } else if let limit = limit {
            // Fetch last N reports
            reports = try await repository.fetchReports(limit: limit)
        } else {
            // Default: last 30 days
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            reports = try await repository.fetchReports(since: startDate)
        }

        guard !reports.isEmpty else {
            throw TrendError.noReportsInDatabase
        }

        return reports
    }

    func buildChartData(from reports: [ReportModel]) throws -> TrendChartData {
        // Build overall trend data points
        var overallDataPoints: [TrendChartData.DataPoint] = []

        for report in reports.reversed() { // Reverse to get chronological order
            // Parse timestamp
            guard let date = parseISO8601Date(report.timestamp) else {
                continue
            }

            // Calculate overall coverage
            if let coverage = report.coverage,
               !coverage.targets.isEmpty {
                let totalExecutableLines = coverage.targets.reduce(0) { $0 + $1.executableLines }
                let totalCoveredLines = coverage.targets.reduce(0) { $0 + $1.coveredLines }

                guard totalExecutableLines > 0 else { continue }

                let coveragePercentage = Double(totalCoveredLines) / Double(totalExecutableLines)
                overallDataPoints.append(TrendChartData.DataPoint(date: date, coverage: coveragePercentage))
            }
        }

        // Build per-target trends if filters specified
        var targetTrends: [TrendChartData.TargetTrend]? = nil

        if !targetFilters.isEmpty {
            var trendsDict: [String: [TrendChartData.DataPoint]] = [:]

            for report in reports.reversed() { // Reverse to get chronological order
                guard let date = parseISO8601Date(report.timestamp),
                      let coverage = report.coverage else {
                    continue
                }

                for target in coverage.targets {
                    // Check if target matches any filter
                    let matchesFilter = targetFilters.contains { filter in
                        target.name.contains(filter)
                    }

                    guard matchesFilter else { continue }

                    // Calculate target coverage
                    guard target.executableLines > 0 else { continue }
                    let coveragePercentage = Double(target.coveredLines) / Double(target.executableLines)

                    // Add to trend
                    if trendsDict[target.name] == nil {
                        trendsDict[target.name] = []
                    }
                    trendsDict[target.name]?.append(TrendChartData.DataPoint(date: date, coverage: coveragePercentage))
                }
            }

            // Verify all requested targets were found
            if trendsDict.isEmpty && !targetFilters.isEmpty {
                throw TrendError.targetNotFound(name: targetFilters.joined(separator: ", "))
            }

            // Convert to array of TargetTrend
            targetTrends = trendsDict.map { name, dataPoints in
                TrendChartData.TargetTrend(name: name, dataPoints: dataPoints)
            }.sorted { $0.name < $1.name }
        }

        return TrendChartData(
            overallTrend: overallDataPoints,
            targetTrends: targetTrends,
            threshold: threshold
        )
    }

    func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
