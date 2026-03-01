//
//  TrendChartData.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation

/// Model representing trend chart data for SVG generation
public struct TrendChartData {
    /// Individual data point in the chart
    public struct DataPoint {
        public let date: Date
        public let coverage: Double

        public init(date: Date, coverage: Double) {
            self.date = date
            self.coverage = coverage
        }
    }

    /// Per-target trend line data
    public struct TargetTrend {
        public let name: String
        public let dataPoints: [DataPoint]

        public init(name: String, dataPoints: [DataPoint]) {
            self.name = name
            self.dataPoints = dataPoints
        }
    }

    /// Overall coverage trend data points
    public let overallTrend: [DataPoint]

    /// Optional per-target trend lines
    public let targetTrends: [TargetTrend]?

    /// Optional threshold line value (0.0 to 1.0)
    public let threshold: Double?

    public init(overallTrend: [DataPoint], targetTrends: [TargetTrend]? = nil, threshold: Double? = nil) {
        self.overallTrend = overallTrend
        self.targetTrends = targetTrends
        self.threshold = threshold
    }
}
