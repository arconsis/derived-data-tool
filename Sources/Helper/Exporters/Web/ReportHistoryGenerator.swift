//
//  ReportHistoryGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 05.05.23.
//

import Foundation
import Shared
import SwiftHtml

struct ReportHistoryGenerator: HtmlDocumentGenerating {
    typealias GraphGenerating = HtmlScriptPartGenerating & HtmlTagGenerating
    let jsonReports: [JSONReport]

    let graphGenerator: GraphGenerating

    let tableGenerator: TableGenerator

    let lastReport: JSONReport

    init(reports: [JSONReport]) {
        jsonReports = reports.sorted(by: { $0.creationDate > $1.creationDate })
        graphGenerator = GraphGenerator(reports: reports)
        tableGenerator = TableGenerator()

        let report = reports.sorted(by: { $0.creationDate > $1.creationDate }).first
        if let report {
            lastReport = report
        } else {
            lastReport = JSONReport(name: "INVALID", reports: [], creationDate: Date())
        }
    }

    func generate() -> String {
        let doc = Document(.html) {
            build()
        }

        return DocumentRenderer(minify: false, indent: 4)
            .render(doc)
    }

    @TagBuilder
    func build() -> Tag {
        Html {
            Head {
                graphGenerator.buildScriptPart()
            }
            Body {
                graphGenerator.buildTag()
                tableGenerator.buildTag(self.makeTop5())
                tableGenerator.buildTag(self.makeLast5())
            }
        }
    }

    func makeTop5() -> TableData {
        let title = "TOP 5"
        let sortedTargets = lastReport.reports.sorted(by: { $0.coverage > $1.coverage }).prefix(5)
        let dataSource: [[TCData]] = createCellData(from: Array(sortedTargets))
        return .init(title: title,
                     data: dataSource,
                     headerRows: 1)
    }

    func makeLast5() -> TableData {
        let title = "LAST 5"
        let sortedTargets = lastReport.reports.sorted(by: { $0.coverage < $1.coverage }).prefix(5)
        let dataSource: [[TCData]] = createCellData(from: Array(sortedTargets))
        return .init(title: title,
                     data: dataSource,
                     headerRows: 1)
    }

    private func createCellData(from targets: [TargetReportElement]) -> [[TCData]] {
        var dataSource: [[TCData]] = [[TCData(value: "RANK"), TCData(value: "NAME"), TCData(value: "Coverage")]]
        for (index, target) in targets.enumerated() {
            let row: [TCData] = [TCData(value: "#\(index)"), TCData(value: target.name),
                                 makeCoverageCell(target)]
            dataSource.append(row)
        }
        return dataSource
    }

    private func makeCoverageCell(_ element: TargetReportElement) -> TCData {
        .init(value: element.printableCoverage,
              cssClasses: [className(for: element.coverage)])
    }

    private func className(for coverage: Double) -> String {
        if coverage > 1 || coverage < 0 {
            return "normal_coverage"
        } else if coverage >= 0.8 {
            return "high_coverage"
        } else if coverage >= 0.3 {
            return "normal_coverage"
        } else if coverage >= 0.15 {
            return "lower_coverage"
        } else {
            return "low_coverage"
        }
    }
}
