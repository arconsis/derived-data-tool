//
//  CoverageReport.swift
//
//
//  Created by Moritz Ellerbrock on 09.05.23.
//

import Foundation

public enum CoverageType: String, Codable {
    case report, target, file, function
}

public protocol Coverage: Codable, Hashable {
    var coveredLines: Int { get }
    var executableLines: Int { get }
    var printableCoverage: String { get }
    var coverage: Double { get }
    var name: String { get }
    var printableName: String { get }
    var type: CoverageType { get }
}

public extension Coverage {
    var printableCoverage: String {
        return String(format: "%.2f", coverage * 100.0)
    }

    var coverage: Double {
        let coverage = Double(coveredLines) / Double(executableLines)
        guard !coverage.isNaN else { return 0.0 }
        return coverage
    }

    var printableName: String {
        name
    }

    func decodeReport(from contentData: Data) throws -> TargetReports {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TargetReports.self, from: contentData)
    }

    func formattedJsonContent(from report: JSONReport, prettyPrint: Bool = true) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(report)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: prettyPrint ? .prettyPrinted : .sortedKeys)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return nil
        }
    }
}

// MARK: - CoverageReport

public struct CoverageReport: Coverage {
    public let targets: [Target]

    public var name: String { "CoverageReport" }
    public var executableLines: Int { targets.map { $0.executableLines }.reduce(0, +) }
    public var coveredLines: Int { targets.map { $0.coveredLines }.reduce(0, +) }
    public var type: CoverageType { .report }

    public init(targets: [Target]) {
        self.targets = targets
    }

    public var mostCoveredTarget: Target? {
        targets.sorted { $0.coverage > $1.coverage }.first
    }

    public var printableName: String {
        name.replacingOccurrences(of: ".framework", with: "")
    }

    func getPaths() -> [String] {
        targets.flatMap { $0.files.map(\.path) }
    }

    public func commonPathPrefix() -> String {
        let paths = targets.flatMap { $0.files.map(\.path) }

        guard !paths.isEmpty else { return "" }

        // Find the common prefix
        var commonPrefix = paths[0]
        for path in paths {
            commonPrefix = commonPrefix.commonPrefix(with: path)
            if commonPrefix.isEmpty {
                break
            }
        }

        return commonPrefix
    }
}

// MARK: - Target

public struct Target: Coverage {
    public let name: String
    public var files: [File] = []
    public var type: CoverageType { .target }

    public var executableLines: Int { files.map { $0.executableLines }.reduce(0, +) }
    public var coveredLines: Int { files.map { $0.coveredLines }.reduce(0, +) }

    public init(name: String, files: [File]) {
        self.name = name
        self.files = files
    }
}

// MARK: - File

public struct File: Coverage {
    public let name: String
    public let path: String
    public let functions: [Function]
    public var type: CoverageType { .file }

    public var executableLines: Int { functions.map { $0.executableLines }.reduce(0, +) }
    public var coveredLines: Int { functions.map { $0.coveredLines }.reduce(0, +) }

    public init(name: String, path: String, functions: [Function]) {
        self.name = name
        self.path = path
        self.functions = functions
    }
}

// MARK: - Function

public struct Function: Coverage {
    public let name: String
    public let executableLines: Int
    public let coveredLines: Int
    public let lineNumber: Int
    public let executionCount: Int
    public var type: CoverageType { .function }

    public var coverage: Double {
        Double(coveredLines) / Double(executableLines)
    }

    public init(name: String, executableLines: Int, coveredLines: Int, lineNumber: Int, executionCount: Int) {
        self.name = name
        self.executableLines = executableLines
        self.coveredLines = coveredLines
        self.lineNumber = lineNumber
        self.executionCount = executionCount
    }
}
