//
//  XCResultFile.swift
//
//
//  Created by Moritz Ellerbrock on 11.05.23.
//

import Foundation

public enum XCResultFileError: Error {
    case fileNameMismatch
}

public struct XCResultFile: Codable, Equatable {
    public let application: String
    public let date: Date
    public let type: String
    public let url: URL

    public init(with url: URL) throws {
        // "Run-ApplicationName-2023.05.08_15-14-43-+0200.xcresult"
        let filename = url.lastPathComponent.replacingOccurrences(of: ".xcresult", with: "")
        // "Run-ApplicationName-2023.05.08_15-14-43-+0200"
        let parts = filename.split(separator: "-").map(String.init)
        // ["Run", "ApplicationName", "2023.05.08_15-14-43-+0200"]
        guard
            let type = parts.first?.lowercased(),
            let application = parts.dropFirst().first
        else {
            throw XCResultFileError.fileNameMismatch
        }

        let dateString = parts.dropFirst(2).joined(separator: "-")
        guard let date = DateFormat.date(from: dateString) else {
            throw XCResultFileError.fileNameMismatch
        }
        // "2023.05.10_16-56-02-+0200"
        self.type = type
        self.application = application
        self.date = date
        self.url = url
    }

    public func toFileName() -> String {
        "\(type.capitalized)-\(application)-\(DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: date)).xcresult"
    }
}

public extension Collection where Element == XCResultFile {
    func include(applications: [String]) -> [XCResultFile] {
        guard !applications.isEmpty else { return self as? [XCResultFile] ?? [] }
        var filteredApplications: [XCResultFile] = []
        for element in self {
            if applications.contains(element.application) {
                filteredApplications.append(element)
            }
        }
        return filteredApplications
    }
}
