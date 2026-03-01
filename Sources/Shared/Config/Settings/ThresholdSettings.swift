//
//  ThresholdSettings.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation

public struct ThresholdConfig: Codable {
    public let minCoverage: Double?
    public let maxDrop: Double?

    public init(minCoverage: Double? = nil, maxDrop: Double? = nil) {
        self.minCoverage = minCoverage
        self.maxDrop = maxDrop
    }
}

public struct ThresholdSettings: SettingsObjectify {
    private static let minCoverageKey: String = "min_coverage"
    private static let maxDropKey: String = "max_drop"
    private static let perTargetThresholdsKey: String = "per_target_thresholds"

    public let minCoverage: Double?
    public let maxDrop: Double?
    public let perTargetThresholds: [String: ThresholdConfig]

    public init(values: [String: String]) throws {
        // Parse minCoverage
        if let minCoverageString = values[Self.minCoverageKey],
           let minCoverage = Double(minCoverageString) {
            self.minCoverage = minCoverage
        } else {
            self.minCoverage = nil
        }

        // Parse maxDrop
        if let maxDropString = values[Self.maxDropKey],
           let maxDrop = Double(maxDropString) {
            self.maxDrop = maxDrop
        } else {
            self.maxDrop = nil
        }

        // Parse perTargetThresholds (JSON encoded)
        if let perTargetThresholdsString = values[Self.perTargetThresholdsKey],
           let data = perTargetThresholdsString.data(using: .utf8),
           let decoded = try? SingleDecoder.shared.decode([String: ThresholdConfig].self, from: data) {
            self.perTargetThresholds = decoded
        } else {
            self.perTargetThresholds = [:]
        }
    }

    public func toDict() throws -> [String: String] {
        var dict = [String: String]()

        if let minCoverage = minCoverage {
            dict[Self.minCoverageKey] = "\(minCoverage)"
        }

        if let maxDrop = maxDrop {
            dict[Self.maxDropKey] = "\(maxDrop)"
        }

        if !perTargetThresholds.isEmpty {
            let jsonData = try SingleEncoder.shared.encode(perTargetThresholds)
            if let json = String(data: jsonData, encoding: .utf8) {
                dict[Self.perTargetThresholdsKey] = json
            }
        }

        return dict
    }
}

public extension ThresholdSettings {
    enum ThresholdSettingsError: LocalizedError {
        case missing(key: String)
        case invalidValue(key: String, value: String)

        public var errorDescription: String? {
            switch self {
            case let .missing(key):
                return "Threshold settings is missing \(key) key with value"
            case let .invalidValue(key, value):
                return "Threshold settings has invalid value '\(value)' for key \(key)"
            }
        }
    }
}
