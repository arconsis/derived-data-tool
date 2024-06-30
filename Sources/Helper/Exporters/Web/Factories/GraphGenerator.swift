//
//  GraphGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 08.05.23.
//

import Foundation
import Shared
import SwiftHtml

class GraphGenerator: HtmlTagGenerating, HtmlScriptPartGenerating {
    let jsonReports: [JSONReport]

    var sortedReports: [JSONReport] {
        jsonReports.sorted(by: { $0.creationDate > $1.creationDate })
    }

    var historyElements: [GraphElement] {
        sortedReports.reversed().map { report in
            let value = report.coverage / 100.0
            return GraphElement(label: report.calendarWeek, value: value)
        }
    }

    init(reports: [JSONReport]) {
        jsonReports = reports
    }

    @TagBuilder
    func buildTag() -> Tag {
        Div {}
            .id("chartContainer")
        Script().src("https://cdn.canvasjs.com/canvasjs.min.js")
    }

    @TagBuilder
    func buildScriptPart() -> Tag {
        Script {
            Text(script(historyElements))
        }.type("text/javascript")
    }

    @TagBuilder
    func makeHead() -> Tag {
        Script {}
            .src("https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.3.0/chart.min.js")
    }

    private func script(_ history: [GraphElement]) -> String {
        let scriptData = history.map { $0.printable() }
        let scriptableData = scriptData.joined(separator: ",\n")
        return """
        window.onload = function () {

         var chart = new CanvasJS.Chart("chartContainer", {
         theme: "light1", // "light2", "dark1", "dark2"
         animationEnabled: false, // change to true
         title: {
         text: "Code Coverage History"
         },
         data: [
         {
         // Change type to "bar", "area", "spline", "pie", "column" ,etc.
         type: "spline",
         dataPoints: [
         \(scriptableData)
         ]
         }
         ]
         });
         chart.render();
         }
        """
    }
}

extension GraphGenerator {
    struct GraphElement {
        let label: String
        let value: Double

        func printable() -> String {
            var formattedLabel = "\""
            formattedLabel = formattedLabel.appending(label)
            formattedLabel = formattedLabel.appending("\"")
            return "{ label: \(formattedLabel), y: \(Int(value * 100)) }"
        }
    }
}
