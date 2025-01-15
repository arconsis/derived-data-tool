//
//  ReportGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 29.04.23.
//

import Foundation
import Shared

public enum ReportGenerator {
    public static func decodeXCOV(with contentString: String) -> Result<TargetReports, CCCLIError> {
        guard let data = contentString.data(using: .utf8) else {
            return .failure(.init(with: ReportError.couldNotBeDecoded))
        }
        return decodeXCOV(from: data)
    }

    public static func decodeXCOV(from contentData: Data) -> Result<TargetReports, CCCLIError> {
        if let targetReports: TargetReports = try? decode(contentData) {
            return .success(targetReports)
        }

        return .failure(.init(with: ReportError.couldNotBeDecoded))
    }

    public static func decodeFullXCOV(with contentString: String) -> Result<FullCoverageReport, CCCLIError> {
        guard let data = contentString.data(using: .utf8) else {
            return .failure(.init(with: ReportError.couldNotBeDecoded))
        }
        return decodeFullXCOV(from: data)
    }

    public static func decodeFullXCOV(from contentData: Data) -> Result<FullCoverageReport, CCCLIError> {
        if let targetReports: FullCoverageReport = try? decode(contentData) {
            return .success(targetReports)
        }

        return .failure(.init(with: ReportError.couldNotBeDecoded))
    }

    public static func decodeReport(with contentString: String) -> Result<JSONReport, CCCLIError> {
        guard let data = contentString.data(using: .utf8) else {
            return .failure(.init(with: ReportError.couldNotBeDecoded))
        }
        return decodeReport(from: data)
    }

    public static func decodeReport(from contentData: Data) -> Result<JSONReport, CCCLIError> {
        if let report = try? SingleDecoder.shared.decode(JSONReport.self, from: contentData) {
            return .success(report)
        }

        return .failure(.init(with: ReportError.couldNotBeDecoded))
    }
}

extension ReportGenerator {
    @available(*, deprecated, message: "use Result-version")
    public static func decodeXCOV(with contentString: String) throws -> TargetReports {
        guard let data = contentString.data(using: .utf8) else {
            throw ErrorFactory.failing(error: ReportError.couldNotBeDecoded)
        }
        return try decodeXCOV(from: data)
    }

    @available(*, deprecated, message: "use Result-version")
    public static func decodeXCOV(from contentData: Data) throws -> TargetReports {
        if let targetReports: TargetReports = try? decode(contentData) {
            return targetReports
        }

        throw ErrorFactory.failing(error: ReportError.couldNotBeDecoded)
    }

    @available(*, deprecated, message: "use Result-version")
    public static func decodeFullXCOV(with contentString: String) throws -> FullCoverageReport {
        guard let data = contentString.data(using: .utf8) else {
            throw ErrorFactory.failing(error: ReportError.couldNotBeDecoded)
        }
        return try decodeFullXCOV(from: data)
    }

    @available(*, deprecated, message: "use Result-version")
    public static func decodeFullXCOV(from contentData: Data) throws -> FullCoverageReport {
        if let targetReports: FullCoverageReport = try? decode(contentData) {
            return targetReports
        }

        throw ErrorFactory.failing(error: ReportError.couldNotBeDecoded)
    }

    @available(*, deprecated, message: "use Result-version")
    public static func decodeReport(with contentString: String) throws -> JSONReport {
        guard let data = contentString.data(using: .utf8) else {
            throw ErrorFactory.failing(error: ReportError.couldNotBeDecoded)
        }
        return try decodeReport(from: data)
    }

    @available(*, deprecated, message: "use Result-version")
    public static func decodeReport(from contentData: Data) throws -> JSONReport {
        if let report = try? SingleDecoder.shared.decode(JSONReport.self, from: contentData) {
            return report
        }

        throw ErrorFactory.failing(error: ReportError.couldNotBeDecoded)
    }
}

public extension ReportGenerator {
    enum ReportError: Errorable {
        case couldNotBeDecoded

        public var printsHelp: Bool { false }
        public var errorDescription: String? { localizedDescription }
    }
}

private extension ReportGenerator {
    static func decode<T: Decodable>(_ data: Data) throws -> T {
        try SingleDecoder.shared.decode(T.self, from: data)
    }

    static func encode(_ encodable: any Encodable) throws -> Data {
        return try SingleEncoder.shared.encode(encodable)
    }

    static func encode(targetReports: TargetReports) throws -> Data {
        try encode(targetReports)
    }

    static func encode(report: JSONReport) throws -> Data {
        try encode(report)
    }
    
    static func printable(report: JSONReport, pretty: Bool = true) throws -> String {
        let data = try encode(report: report)
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let jsonData = pretty ? try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) : try JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
        return String(decoding: jsonData, as: UTF8.self)
    }

    static func printable(encodable: any Encodable, pretty: Bool = true) throws -> String {
        let data = try encode(encodable)
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let jsonData = pretty ? try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) : try JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
        return String(decoding: jsonData, as: UTF8.self)
    }
}
