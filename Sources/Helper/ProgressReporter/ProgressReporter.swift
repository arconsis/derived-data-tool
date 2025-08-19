//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 19.08.25.
//

import Foundation

public protocol ProgressReporting {
    func report(percentage: Double)
    func report(step: Int, of totalSteps: Int, inPercentage: Bool)
    func report(finished: Bool)
    func report(text: String, clearLine: Bool)
}

extension ProgressReporting {
    func report(step: Int, of totalSteps: Int) {
        report(step: step, of: totalSteps, inPercentage: true)
    }

    func report(text: String) {
        report(text: text, clearLine: true)
    }

    func report(percentage: Double) {
        report(text: "\(percentage)%")
    }

    func report(step: Int, of totalSteps: Int, inPercentage: Bool = true) {
        if inPercentage {
            let percentage = Double(step) / Double(totalSteps) * 100
            report(percentage: percentage)
        } else {
            report(text: "\(step)/\(totalSteps)")
        }
    }
}

class ProgressReporter: ProgressReporting, Hashable {
    static func == (lhs: ProgressReporter, rhs: ProgressReporter) -> Bool {
        lhs.id == rhs.id && lhs.prefix == rhs.prefix
    }

    var hashValue: Int { "\(id)\(prefix)".hashValue }

    let id: String
    let prefix: String
    var alive: Bool = true

    init(id: String, prefix: String) {
        self.id = id
        self.prefix = prefix
    }

    func report(finished: Bool) {
        report(text: "DONE!")
        alive = false
    }

    func report(text: String, clearLine: Bool = true) {
        if alive {
            var textOutput: String = "\(prefix): \(text)"
            if clearLine {
                textOutput = "\u{001B}[2K\r\(textOutput)"
            }
            FileHandle.standardOutput.write(Data(textOutput.utf8))
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine("\(id)\(prefix)")
    }
}
