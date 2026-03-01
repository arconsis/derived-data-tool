//
//  SVGChartGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation
import Shared

/// Generates self-contained SVG trend charts from coverage data
public class SVGChartGenerator {
    private let chartData: TrendChartData
    private let width: Double
    private let height: Double
    private let padding: Padding

    /// Chart dimensions configuration
    public struct Padding {
        let top: Double
        let right: Double
        let bottom: Double
        let left: Double

        public init(top: Double = 60, right: Double = 120, bottom: Double = 60, left: Double = 60) {
            self.top = top
            self.right = right
            self.bottom = bottom
            self.left = left
        }
    }

    public init(
        chartData: TrendChartData,
        width: Double = 1200,
        height: Double = 600,
        padding: Padding = Padding()
    ) {
        self.chartData = chartData
        self.width = width
        self.height = height
        self.padding = padding
    }

    /// Generate the complete SVG chart as a string
    public func generateSVG() -> String {
        var svg = svgHeader()
        svg += svgStyles()
        svg += svgTitle()
        svg += svgGrid()
        svg += svgAxes()
        svg += svgDataLines()
        svg += svgThresholdLine()
        svg += svgLegend()
        svg += svgFooter()
        return svg
    }

    // MARK: - SVG Components

    private func svgHeader() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(Int(width))" height="\(Int(height))" viewBox="0 0 \(Int(width)) \(Int(height))" xmlns="http://www.w3.org/2000/svg">

        """
    }

    private func svgStyles() -> String {
        return """
        <defs>
          <style type="text/css">
            .chart-title { font: bold 20px sans-serif; fill: #333; }
            .axis-label { font: 12px sans-serif; fill: #666; }
            .grid-line { stroke: #e0e0e0; stroke-width: 1; }
            .axis-line { stroke: #333; stroke-width: 2; }
            .overall-line { stroke: #2196F3; stroke-width: 3; fill: none; }
            .target-line { stroke-width: 2; fill: none; }
            .threshold-line { stroke: #f44336; stroke-width: 2; stroke-dasharray: 5,5; fill: none; }
            .data-point { fill: #2196F3; }
            .legend-text { font: 12px sans-serif; fill: #333; }
            .legend-rect { stroke: #333; stroke-width: 1; }
          </style>
        </defs>

        """
    }

    private func svgTitle() -> String {
        return """
          <text x="\(width / 2)" y="30" text-anchor="middle" class="chart-title">Coverage Trend History</text>

        """
    }

    private func svgGrid() -> String {
        let chartWidth = width - padding.left - padding.right
        let chartHeight = height - padding.top - padding.bottom
        var grid = ""

        // Horizontal grid lines (for coverage percentages)
        for i in 0...10 {
            let y = padding.top + (chartHeight * Double(i) / 10.0)
            grid += "  <line x1=\"\(padding.left)\" y1=\"\(y)\" x2=\"\(width - padding.right)\" y2=\"\(y)\" class=\"grid-line\"/>\n"
        }

        // Vertical grid lines (for dates)
        let dataPoints = chartData.overallTrend.count
        if dataPoints > 1 {
            let step = max(1, dataPoints / 10)
            for i in stride(from: 0, to: dataPoints, by: step) {
                let x = padding.left + (chartWidth * Double(i) / Double(dataPoints - 1))
                grid += "  <line x1=\"\(x)\" y1=\"\(padding.top)\" x2=\"\(x)\" y2=\"\(height - padding.bottom)\" class=\"grid-line\"/>\n"
            }
        }

        grid += "\n"
        return grid
    }

    private func svgAxes() -> String {
        let chartWidth = width - padding.left - padding.right
        let chartHeight = height - padding.top - padding.bottom
        var axes = ""

        // X-axis
        axes += "  <line x1=\"\(padding.left)\" y1=\"\(height - padding.bottom)\" x2=\"\(width - padding.right)\" y2=\"\(height - padding.bottom)\" class=\"axis-line\"/>\n"

        // Y-axis
        axes += "  <line x1=\"\(padding.left)\" y1=\"\(padding.top)\" x2=\"\(padding.left)\" y2=\"\(height - padding.bottom)\" class=\"axis-line\"/>\n"

        // Y-axis labels (coverage percentages)
        for i in 0...10 {
            let y = padding.top + (chartHeight * Double(i) / 10.0)
            let percentage = 100 - (i * 10)
            axes += "  <text x=\"\(padding.left - 10)\" y=\"\(y + 5)\" text-anchor=\"end\" class=\"axis-label\">\(percentage)%</text>\n"
        }

        // X-axis labels (dates)
        let dataPoints = chartData.overallTrend.count
        if dataPoints > 0 {
            let step = max(1, dataPoints / 6) // Show max 6 date labels
            for i in stride(from: 0, to: dataPoints, by: step) {
                let x = padding.left + (chartWidth * Double(i) / Double(dataPoints - 1))
                let dateLabel = formatDate(chartData.overallTrend[i].date)
                axes += "  <text x=\"\(x)\" y=\"\(height - padding.bottom + 20)\" text-anchor=\"middle\" class=\"axis-label\">\(dateLabel)</text>\n"
            }

            // Always show the last date
            if dataPoints > 1 {
                let lastIndex = dataPoints - 1
                let x = padding.left + chartWidth
                let dateLabel = formatDate(chartData.overallTrend[lastIndex].date)
                axes += "  <text x=\"\(x)\" y=\"\(height - padding.bottom + 20)\" text-anchor=\"middle\" class=\"axis-label\">\(dateLabel)</text>\n"
            }
        }

        axes += "\n"
        return axes
    }

    private func svgDataLines() -> String {
        var lines = ""

        // Overall coverage line
        if !chartData.overallTrend.isEmpty {
            lines += "  <path d=\"\(createLinePath(chartData.overallTrend))\" class=\"overall-line\"/>\n"

            // Data points
            for point in chartData.overallTrend {
                let coords = calculateCoordinates(point)
                lines += "  <circle cx=\"\(coords.x)\" cy=\"\(coords.y)\" r=\"4\" class=\"data-point\"/>\n"
            }
        }

        // Per-target lines
        if let targetTrends = chartData.targetTrends {
            let colors = ["#4CAF50", "#FF9800", "#9C27B0", "#00BCD4", "#FFEB3B", "#795548"]
            for (index, targetTrend) in targetTrends.enumerated() {
                let color = colors[index % colors.count]
                if !targetTrend.dataPoints.isEmpty {
                    lines += "  <path d=\"\(createLinePath(targetTrend.dataPoints))\" class=\"target-line\" stroke=\"\(color)\"/>\n"
                }
            }
        }

        lines += "\n"
        return lines
    }

    private func svgThresholdLine() -> String {
        guard let threshold = chartData.threshold else { return "" }

        let chartHeight = height - padding.top - padding.bottom
        let y = padding.top + chartHeight * (1.0 - threshold)

        var line = ""
        line += "  <line x1=\"\(padding.left)\" y1=\"\(y)\" x2=\"\(width - padding.right)\" y2=\"\(y)\" class=\"threshold-line\"/>\n"
        line += "  <text x=\"\(width - padding.right + 10)\" y=\"\(y + 5)\" class=\"axis-label\" fill=\"#f44336\">Threshold: \(Int(threshold * 100))%</text>\n"
        line += "\n"
        return line
    }

    private func svgLegend() -> String {
        var legend = ""
        let legendX = width - padding.right + 10
        var legendY = padding.top + 20
        let lineHeight: Double = 25

        // Overall coverage
        legend += "  <line x1=\"\(legendX)\" y1=\"\(legendY - 5)\" x2=\"\(legendX + 30)\" y2=\"\(legendY - 5)\" class=\"overall-line\"/>\n"
        legend += "  <text x=\"\(legendX + 35)\" y=\"\(legendY)\" class=\"legend-text\">Overall</text>\n"
        legendY += lineHeight

        // Target trends
        if let targetTrends = chartData.targetTrends {
            let colors = ["#4CAF50", "#FF9800", "#9C27B0", "#00BCD4", "#FFEB3B", "#795548"]
            for (index, targetTrend) in targetTrends.enumerated() {
                let color = colors[index % colors.count]
                legend += "  <line x1=\"\(legendX)\" y1=\"\(legendY - 5)\" x2=\"\(legendX + 30)\" y2=\"\(legendY - 5)\" class=\"target-line\" stroke=\"\(color)\"/>\n"
                legend += "  <text x=\"\(legendX + 35)\" y=\"\(legendY)\" class=\"legend-text\">\(targetTrend.name)</text>\n"
                legendY += lineHeight
            }
        }

        // Threshold
        if chartData.threshold != nil {
            legend += "  <line x1=\"\(legendX)\" y1=\"\(legendY - 5)\" x2=\"\(legendX + 30)\" y2=\"\(legendY - 5)\" class=\"threshold-line\"/>\n"
            legend += "  <text x=\"\(legendX + 35)\" y=\"\(legendY)\" class=\"legend-text\">Threshold</text>\n"
        }

        legend += "\n"
        return legend
    }

    private func svgFooter() -> String {
        return "</svg>\n"
    }

    // MARK: - Helper Methods

    private func createLinePath(_ dataPoints: [TrendChartData.DataPoint]) -> String {
        guard !dataPoints.isEmpty else { return "" }

        var path = ""
        for (index, point) in dataPoints.enumerated() {
            let coords = calculateCoordinates(point)
            if index == 0 {
                path += "M \(coords.x) \(coords.y)"
            } else {
                path += " L \(coords.x) \(coords.y)"
            }
        }
        return path
    }

    private func calculateCoordinates(_ dataPoint: TrendChartData.DataPoint) -> (x: Double, y: Double) {
        let chartWidth = width - padding.left - padding.right
        let chartHeight = height - padding.top - padding.bottom

        // Find the index of this data point in the overall trend
        guard let index = chartData.overallTrend.firstIndex(where: { $0.date == dataPoint.date }) else {
            return (x: padding.left, y: padding.top)
        }

        let dataPoints = chartData.overallTrend.count
        let xRatio = dataPoints > 1 ? Double(index) / Double(dataPoints - 1) : 0
        let x = padding.left + (chartWidth * xRatio)

        // Y coordinate (inverted because SVG Y grows downward)
        let yRatio = 1.0 - dataPoint.coverage
        let y = padding.top + (chartHeight * yRatio)

        return (x: x, y: y)
    }

    private func formatDate(_ date: Date) -> String {
        return DateFormat.dayAbbreviatedMonthYear.string(from: date)
    }
}
