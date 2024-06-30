//
//  JSONReportGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 05.05.23.
//

import Foundation
import Shared
import SwiftHtml

struct JSONReportGenerator: HtmlTagGenerating {
    let jsonReport: JSONReport

    init(jsonReport: JSONReport) {
        self.jsonReport = jsonReport
    }

    func generate() -> String {
        ""
    }

    @TagBuilder
    func buildTag() -> Tag {
        Text("")
    }
}
