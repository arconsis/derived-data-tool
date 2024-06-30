//
//  WebExportTests.swift
//
//
//  Created by Moritz Ellerbrock on 07.05.23.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class WebExportTests: XCTestCase {
    func testJSONHTML() throws {
        let reports: [JSONReport] = []
        let generator: HtmlDocumentGenerating = ReportHistoryGenerator(reports: reports)
        print(generator.generate())
    }

    func testJSONReportExportHTML() throws {
        let titles = Self.makeTargetTitles(5)
        let target = TargetReport(targetNames: titles, lowCoverage: 25, highestCoverage: 95)
        let mock = Self.makeJSONReports(appName: "TestApp", weeksInThePast: 10, predefinedTargets: target)
        let generator: HtmlDocumentGenerating = ReportHistoryGenerator(reports: mock)
        let content = generator.build()
        let html = generator.generate()
        print(html)
    }
}

extension WebExportTests {
    static func makeJSONReports(appName: String, weeksInThePast: Int, predefinedTargets: TargetReport) -> [JSONReport] {
        var mocks = [JSONReport]()
        let dates = makeDatesForPastWeeks(weeksInThePast)

        for date in dates {
            let reports = makeTargetReportElements(predefinedTargets)
            mocks.append(JSONReport(name: appName, reports: reports, creationDate: date))
        }

        return mocks
    }

    private static func makeTargetReportElements(_ targetReport: TargetReport) -> [TargetReportElement] {
        var mocks = [TargetReportElement]()

        for targetName in targetReport.targetNames {
            let targetReport = makeTargetReport(targetName, detailedReport: targetReport)
            mocks.append(targetReport)
        }

        //            mocks.append(TargetReportElement(coveredLines: <#T##Int#>, executableLines: 100, lineCoverage: <#T##Double#>, name: <#T##String#>)(name: targetName, reports: TargetReports, creationDate: <#T##Date#>))

        return mocks
    }

    private static func makeTargetReport(_ name: String, detailedReport: TargetReport) -> TargetReportElement {
        let coverage = detailedReport.randomCoverage()
        let executableLines = 1000
        let coveredLines = Int(coverage * Double(executableLines))
        return TargetReportElement(coveredLines: coveredLines, executableLines: executableLines, name: name)
    }

    private static func makeDatesForPastWeeks(_ amount: Int) -> [Date] {
        let referenceTimeIntervalSince1970 = Date().timeIntervalSince1970
        return (0 ..< amount).map {
            Date(timeIntervalSince1970: referenceTimeIntervalSince1970 - (Double($0) * 604_800.0))
        }
    }

    private static func makeTargetTitles(_ amount: Int) -> [String] {
        (0 ..< amount).map { _ in
            String.randomString(length: 5, include: [.lowercaseLetters, .uppercaseLetters]).capitalized
        }
    }

    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*.!@#$%^&(){}[]:;<>,.?/~+-=|\\"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }
}

extension WebExportTests {
    struct TargetReport {
        let targetNames: [String]
        var lowCoverage: Int = 0
        var highestCoverage: Int = 99

        func randomCoverage() -> Double {
            Double.random(in: Double(lowCoverage) ..< Double(highestCoverage))
        }
    }
}

public extension String {
    static func randomString(length: Int) -> String {
        randomString(
            length: length,
            with: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*.!@#$%^&(){}[]:;<>,.?/~+-=|\\"
        )
    }

    static func randomString(length: Int, include characterSet: [Characters]) -> String {
        var letters = [String]()
        for character in characterSet {
            switch character {
            case .lowercaseLetters:
                letters.append("abcdefghijklmnopqrstuvwxyz")
            case .uppercaseLetters:
                letters.append("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            case .numbers:
                letters.append("0123456789")
            case .symbols:
                letters.append("*.!@#$%^&(){}[]:;<>,.?/~+-=|\\")
            }
        }
        return randomString(length: length, with: letters.joined())
    }

    private static func randomString(length: Int, with letters: String) -> String {
        String((0 ..< length).map { _ in letters.randomElement()! })
    }
}

public enum Characters {
    case lowercaseLetters
    case uppercaseLetters
    case numbers
    case symbols
}
