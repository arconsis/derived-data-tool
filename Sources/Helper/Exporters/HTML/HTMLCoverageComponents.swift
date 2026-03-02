//
//  HTMLCoverageComponents.swift
//
//
//  Created by auto-claude on 02.03.26.
//

import Foundation
import SwiftHtml

// MARK: - Coverage Bar Component

typealias CoverageBarData = CoverageBar.Data

struct CoverageBar {
    struct Data {
        let percentage: Double
        let label: String?
        let cssID: String?
        let cssClasses: [String]?

        init(percentage: Double,
             label: String? = nil,
             cssID: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.percentage = percentage
            self.label = label
            self.cssID = cssID
            self.cssClasses = cssClasses
        }
    }
}

class CoverageBarGenerator: HtmlTagGenerating {
    @TagBuilder
    func buildTag(_ dataSource: CoverageBarData) -> Tag {
        let colorClass = getCoverageColorClass(dataSource.percentage)
        let widthPercent = Int(dataSource.percentage * 100)
        let displayLabel = dataSource.label ?? "\(widthPercent)%"

        Div {
            Div {
                Text(displayLabel)
            }
            .class(["coverage-bar", colorClass])
            .style("width: \(widthPercent)%")
        }
        .id(dataSource.cssID)
        .class(dataSource.cssClasses ?? ["coverage-bar-container"])
    }

    @TagBuilder
    func buildTag() -> Tag {
        Div {
            Text("WRONG METHOD")
        }
    }

    private func getCoverageColorClass(_ coverage: Double) -> String {
        if coverage >= 0.8 {
            return "high"
        } else if coverage >= 0.3 {
            return "normal"
        } else if coverage >= 0.15 {
            return "lower"
        } else {
            return "low"
        }
    }
}

// MARK: - Sortable Table Header Component

typealias SortableHeaderData = SortableTableHeader.Data

struct SortableTableHeader {
    struct Data {
        let headers: [HeaderCell]
        let cssID: String?
        let cssClasses: [String]?

        init(headers: [HeaderCell],
             cssID: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.headers = headers
            self.cssID = cssID
            self.cssClasses = cssClasses
        }
    }

    struct HeaderCell {
        let title: String
        let sortable: Bool
        let columnKey: String?
        let cssClasses: [String]?

        init(title: String,
             sortable: Bool = false,
             columnKey: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.title = title
            self.sortable = sortable
            self.columnKey = columnKey
            self.cssClasses = cssClasses
        }
    }
}

class SortableTableHeaderGenerator: HtmlTagGenerating {
    @TagBuilder
    func buildTag(_ dataSource: SortableHeaderData) -> Tag {
        let thead = Thead {
            Tr {
                for header in dataSource.headers {
                    Th {
                        Text(header.title)
                    }
                    .class(buildHeaderClasses(header))
                    .attribute("data-column", header.columnKey)
                }
            }
        }
        .id(dataSource.cssID)

        if let cssClasses = dataSource.cssClasses {
            thead.class(cssClasses)
        } else {
            thead
        }
    }

    @TagBuilder
    func buildTag() -> Tag {
        Thead {
            Text("WRONG METHOD")
        }
    }

    private func buildHeaderClasses(_ header: SortableTableHeader.HeaderCell) -> [String] {
        var classes: [String] = header.cssClasses ?? []
        if header.sortable {
            classes.append("sortable")
        }
        return classes
    }
}

// MARK: - Expandable File Section Component

typealias ExpandableFileSectionData = ExpandableFileSection.Data

struct ExpandableFileSection {
    struct Data {
        let fileName: String
        let fileID: String
        let coverage: Double
        let coveredLines: Int
        let executableLines: Int
        let cssID: String?
        let cssClasses: [String]?

        init(fileName: String,
             fileID: String,
             coverage: Double,
             coveredLines: Int,
             executableLines: Int,
             cssID: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.fileName = fileName
            self.fileID = fileID
            self.coverage = coverage
            self.coveredLines = coveredLines
            self.executableLines = executableLines
            self.cssID = cssID
            self.cssClasses = cssClasses
        }
    }
}

class ExpandableFileSectionGenerator: HtmlTagGenerating {
    @TagBuilder
    func buildTag(_ dataSource: ExpandableFileSectionData) -> Tag {
        let coveragePercent = String(format: "%.2f", dataSource.coverage * 100.0)
        let colorClass = getCoverageColorClass(dataSource.coverage)

        Tr {
            Td {
                Span {
                    Text("▶")
                }
                .class(["expand-icon"])
                Span {
                    Text(dataSource.fileName)
                }
                .class(["file-name"])
            }
            Td {
                Text("\(coveragePercent)%")
            }
            .class([colorClass, "text-center"])
            Td {
                Text("\(dataSource.coveredLines)")
            }
            .class(["text-center"])
            Td {
                Text("\(dataSource.executableLines)")
            }
            .class(["text-center"])
            Td {
                CoverageBarGenerator().buildTag(
                    CoverageBarData(percentage: dataSource.coverage)
                )
            }
        }
        .id(dataSource.cssID)
        .class((dataSource.cssClasses ?? []) + ["expandable"])
        .attribute("data-file-id", dataSource.fileID)
    }

    @TagBuilder
    func buildTag() -> Tag {
        Tr {
            Text("WRONG METHOD")
        }
    }

    private func getCoverageColorClass(_ coverage: Double) -> String {
        if coverage >= 0.8 {
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

// MARK: - Line Coverage Row Component

typealias LineCoverageRowData = LineCoverageRow.Data

struct LineCoverageRow {
    struct Data {
        let lineNumber: Int
        let hitCount: Int?
        let code: String
        let cssID: String?
        let cssClasses: [String]?

        init(lineNumber: Int,
             hitCount: Int?,
             code: String,
             cssID: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.lineNumber = lineNumber
            self.hitCount = hitCount
            self.code = code
            self.cssID = cssID
            self.cssClasses = cssClasses
        }
    }
}

class LineCoverageRowGenerator: HtmlTagGenerating {
    func buildTag(_ dataSource: LineCoverageRowData) -> Tag {
        let coverageClass: String
        let hitDisplay: String

        if let hits = dataSource.hitCount {
            if hits > 0 {
                coverageClass = "line-covered"
                hitDisplay = "\(hits)"
            } else {
                coverageClass = "line-uncovered"
                hitDisplay = "0"
            }
        } else {
            coverageClass = "line-neutral"
            hitDisplay = ""
        }

        let row = Tr {
            Td {
                Text("\(dataSource.lineNumber)")
            }
            .class(["line-number", coverageClass])
            Td {
                Text(hitDisplay)
            }
            .class(["line-hits", coverageClass])
            Td {
                Text(dataSource.code)
            }
            .class(["line-code", coverageClass])
        }
        .id(dataSource.cssID)

        if let cssClasses = dataSource.cssClasses {
            return row.class(cssClasses)
        } else {
            return row
        }
    }

    @TagBuilder
    func buildTag() -> Tag {
        Tr {
            Text("WRONG METHOD")
        }
    }
}

// MARK: - Summary Card Component

typealias SummaryCardData = SummaryCard.Data

struct SummaryCard {
    struct Data {
        let title: String
        let items: [SummaryItem]
        let cssID: String?
        let cssClasses: [String]?

        init(title: String,
             items: [SummaryItem],
             cssID: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.title = title
            self.items = items
            self.cssID = cssID
            self.cssClasses = cssClasses
        }
    }

    struct SummaryItem {
        let label: String
        let value: String
        let cssClasses: [String]?

        init(label: String,
             value: String,
             cssClasses: [String]? = nil)
        {
            self.label = label
            self.value = value
            self.cssClasses = cssClasses
        }
    }
}

class SummaryCardGenerator: HtmlTagGenerating {
    @TagBuilder
    func buildTag(_ dataSource: SummaryCardData) -> Tag {
        Div {
            H2 {
                Text(dataSource.title)
            }
            Div {
                for item in dataSource.items {
                    Div {
                        Div {
                            Text(item.label)
                        }
                        .class(["summary-label"])
                        Div {
                            Text(item.value)
                        }
                        .class((item.cssClasses ?? []) + ["summary-value"])
                    }
                    .class(["summary-item"])
                }
            }
            .class(["summary-grid"])
        }
        .id(dataSource.cssID)
        .class((dataSource.cssClasses ?? []) + ["summary-card"])
    }

    @TagBuilder
    func buildTag() -> Tag {
        Div {
            Text("WRONG METHOD")
        }
    }
}

// MARK: - Helper Tag Classes

class CoverageTextWithClass: GroupTag {
    public init(coverage: Double, text: String) {
        super.init()
        let colorClass = getCoverageColorClass(coverage)
        setContents(text)
            .setAttributes([
                Attribute(key: "class", value: colorClass),
            ])
    }

    private func getCoverageColorClass(_ coverage: Double) -> String {
        if coverage >= 0.8 {
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
