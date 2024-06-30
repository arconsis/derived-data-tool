//
//  JSONCompareGenerate.swift
//
//
//  Created by Moritz Ellerbrock on 05.05.23.
//

import Foundation
import Shared
import SwiftHtml

struct JSONCompareGenerator: HtmlTagGenerating {
    init(currentReport: JSONReport, previousReport: JSONReport) {
        self.currentReport = currentReport
        self.previousReport = previousReport
    }

    let currentReport: JSONReport
    let previousReport: JSONReport

    func generate() -> String {
        ""
    }

    @TagBuilder
    func buildTag() -> Tag {
        Text("JSONCompareGenerator")
    }
}
