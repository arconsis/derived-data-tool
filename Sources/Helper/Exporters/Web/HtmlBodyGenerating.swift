//
//  HtmlBodyGenerating.swift
//
//
//  Created by Moritz Ellerbrock on 05.05.23.
//

import Foundation
import SwiftHtml

protocol HtmlBodyGenerating {
    func buildBody() -> Tag
}

protocol HtmlTagGenerating {
    func buildTag() -> Tag
}

protocol HtmlScriptGenerating {
    func buildScript() -> Tag
}

protocol HtmlScriptPartGenerating {
    func buildScriptPart() -> Tag
}

protocol HtmlDocumentGenerating {
    func generate() -> String
    func build() -> Tag
}

extension HtmlDocumentGenerating {
    func generate() -> String {
        let doc = Document(.html) {
            build()
        }
        return DocumentRenderer(minify: false, indent: 4)
            .render(doc)
    }
}
