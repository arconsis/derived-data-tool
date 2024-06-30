//
//  TableGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 08.05.23.
//

import Foundation
import SwiftHtml

typealias TCData = TableData.CellData
struct TableData {
    let title: String?
    let cssID: String?
    let cssClasses: [String]?
    let data: [[CellData]] // [row][column]
    let headerRows: Int

    init(title: String? = nil,
         cssID: String? = nil,
         cssClasses: [String]? = nil,
         data: [[CellData]],
         headerRows: Int = 0)
    {
        self.title = title
        self.cssID = cssID
        self.cssClasses = cssClasses
        self.data = data
        self.headerRows = headerRows
    }

    struct CellData {
        let value: String
        let cssID: String?
        let cssClasses: [String]?

        init(value: String,
             cssID: String? = nil,
             cssClasses: [String]? = nil)
        {
            self.value = value
            self.cssID = cssID
            self.cssClasses = cssClasses
        }
    }
}

class TableGenerator: HtmlTagGenerating {
    @TagBuilder
    func buildTag(_ dataSource: TableData) -> Tag {
        if let cssClasses = dataSource.cssClasses, !cssClasses.isEmpty {
            Div {
                createTable(dataSource)
            }
            .id(dataSource.cssID)
            .class(cssClasses)

        } else {
            Div {
                createTable(dataSource)
            }
            .id(dataSource.cssID)
        }
    }

    @TagBuilder
    func buildTag() -> Tag {
        Div {
            Text("WRONG METHOD")
        }
    }

    @TagBuilder
    private func createTable(_ dataSource: TableData) -> Tag {
        Table {
            if let title = dataSource.title {
                Thead {
                    Text(title)
                }
            }
            for (index, values) in dataSource.data.enumerated() {
                Tr {
                    for columnData in values {
                        if index < dataSource.headerRows {
                            Th {
                                TextOptionalClasses(columnData)
                            }
                        } else {
                            Td {
                                TextOptionalClasses(columnData)
                            }
                        }
                    }
                }
            }
        }
    }
}

class TextOptionalClasses: GroupTag {
    public init(_ data: TCData) {
        super.init()
        if let cssClasses = data.cssClasses {
            setContents(data.value)
                .setAttributes([
                    Attribute(key: "class", value: cssClasses.joined(separator: " ")),
                    Attribute(key: "id", value: data.cssID),
                ])
        } else {
            setContents(data.value)
                .setAttributes([
                    Attribute(key: "id", value: data.cssID),
                ])
        }
    }
}
