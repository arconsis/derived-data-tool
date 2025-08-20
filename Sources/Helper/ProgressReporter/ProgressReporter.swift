//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 19.08.25.
//

import Foundation
import DependencyInjection

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
        report(text: "\(String(format: "%.2f", percentage))%")
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
    let id: String
    let prefix: String

    init(id: String, prefix: String) {
        self.id = id
        self.prefix = prefix
    }

    func report(finished: Bool) {
        report(text: "DONE!")
    }

    func report(text: String, clearLine: Bool = true) {
        if CE.shouldUseProgressUI {
            var textOutput: String = "\(prefix): \(text)"
            if clearLine {
                textOutput = "\u{001B}[2K\r\(textOutput)"
            }
            FileHandle.standardOutput.write(Data(textOutput.utf8))
        } else {
            @Injected(\.logger) var debugLogger
            debugLogger.log(text)
        }
    }

    static func == (lhs: ProgressReporter, rhs: ProgressReporter) -> Bool {
        lhs.id == rhs.id && lhs.prefix == rhs.prefix
    }

    var hashValue: Int { "\(id)\(prefix)".hashValue }
    func hash(into hasher: inout Hasher) {
        hasher.combine("\(id)\(prefix)")
    }
}
