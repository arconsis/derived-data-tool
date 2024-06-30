//
//  HTMLGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 28.04.23.
//

import Foundation
import Shared
import SwiftHtml

public class HTMLGenerator {
    let reports: [JSONReport]

    init(with reports: [JSONReport]) {
        self.reports = reports.sorted(by: { $0.creationDate > $1.creationDate })
    }

    public static func generateHTML(_ jsonReport: JSONReport) -> String {
        let doc = Document(.html) {
            buildHTML(jsonReport)
        }
        return DocumentRenderer(minify: false, indent: 4)
            .render(doc)
    }

    @TagBuilder
    private static func buildHTML(_ jsonReport: JSONReport) -> Tag {
        JSONReportGenerator(jsonReport: jsonReport).buildTag()
    }

    static func makeHTMLReport(reports: [DetailedReport]) -> String {
        let sortedReports = reports.sorted { $0.creationDate.timeIntervalSince1970 > $1.creationDate.timeIntervalSince1970 }
        if let latest = sortedReports.first,
           let old = sortedReports.dropFirst().first
        {
            let date = latest.creationDate

            let doc = Document(.html) {
                makeHeader(date)
                makeTopAll(latest.reports)
                makeLastAll(latest.reports)
                makeTopChanges(latest.reports, old: old.reports)
                makeLastChanges(latest.reports, old: old.reports)
            }
            let body = DocumentRenderer(
                minify: false,
                indent: 4
            )
            .render(doc)
            return body
        }
        fatalError("should not be reached")
    }

    @TagBuilder
    private static func makeTopAll(_ latest: TargetReports) -> Tag {
        let sortedTargets = latest.sorted(by: { $0.coverage > $1.coverage }).prefix(5)
        Section {
            Table {
                Thead {
                    Text("TOP 5")
                }
                Tr {
                    Th {
                        Text("RANK")
                    }
                    Th {
                        Text("Name")
                    }
                    Th {
                        Text("Coverage")
                    }
                    for (index, target) in sortedTargets.enumerated() {
                        Td {
                            Text("#\(index + 1)")
                        }
                        Td {
                            Text(target.name)
                        }
                        makeCoverageCell(target)
                    }
                }
            }
        }
    }

    @TagBuilder
    private static func makeCoverageCell(_ element: TargetReportElement) -> Tag {
        let text = "\(element.printableCoverage) %"
        let color: ColorScheme = .init(element.coverage)
        Td {
            Text(text)
        }.class(color.className)
    }

    @TagBuilder
    private static func makeLastAll(_ latest: TargetReports) -> Tag {
        let sortedTargets = latest.sorted(by: { $0.coverage > $1.coverage }).suffix(5)
        Section {
            Table {
                Thead {
                    Text("LAST 5")
                }
                Tr {
                    Th {
                        Text("RANK")
                    }
                    Th {
                        Text("Name")
                    }
                    Th {
                        Text("Coverage")
                    }
                    for (index, target) in sortedTargets.enumerated() {
                        Td {
                            Text("#\(index + 1)")
                        }
                        Td {
                            Text(target.name)
                        }
                        makeCoverageCell(target)
                    }
                }
            }
        }
    }

    @TagBuilder
    private static func makeTopChanges(_: TargetReports, old _: TargetReports) -> Tag {
        Div {
            Text("")
        }
    }

    @TagBuilder
    private static func makeLastChanges(_: TargetReports, old _: TargetReports) -> Tag {
        Div {
            Text("")
        }
    }

//    static func createHTML(from targets: TargetReports) -> String {
//        let doc = Document(.html) {
//            makeHeader()
//            for element in targets {
//                makeTarget(from: element)
//            }
//        }
//        let body = DocumentRenderer(
//            minify: false,
//            indent: 4)
//            .render(doc)
//        return body
//    }

    @TagBuilder
    private static func makeHeader(_: Date) -> Tag {
        Div {
            Text("")
        }
    }

    @TagBuilder
    private static func makeTarget(from _: TargetReportElement) -> Tag {
        Div {
            Text("")
        }
    }

//    func makeNewsletter(_ newsletter: Newsletter) -> String {
//        return makeNewsletter(for: newsletter.name, items: newsletter.items)
//    }
//
//    private func makeNewsletter(for name: String, items: [Item]) -> String {
//        let doc = Document(.html) {
//            Html {
//                Head {
//                    Title(name)
//                    Meta().charset("utf-8")
//                    Meta().name(.viewport).content("width=device-width, initial-scale=1")
//
//                }
//                Style {
//
//                }
//                Body {
//                    Text("d")
//                }
//            }
//        }
//        let body = DocumentRenderer(
//            minify: false,
//            indent: 4)
//            .render(doc)
//        return body
//    }
//
//    @TagBuilder
//    private func makeHeader(_ welcomeMessage: String, name newsletterName: String) -> Tag {
//        Div {
//
//        }
//    }
}

extension HTMLGenerator {
    enum ColorScheme {
        case green, none, orange, red

        var className: String {
            switch self {
            case .green:
                return "high_coverage"
            case .none:
                return "normal_coverage"
            case .orange:
                return "lower_coverage"
            case .red:
                return "low_coverage"
            }
        }

        init(_ coverage: Double) {
            if coverage > 1 || coverage < 0 {
                self = .none
            } else if coverage >= 0.8 {
                self = .green
            } else if coverage >= 0.3 {
                self = .none
            } else if coverage >= 0.15 {
                self = .orange
            } else {
                self = .red
            }
        }
    }
}
