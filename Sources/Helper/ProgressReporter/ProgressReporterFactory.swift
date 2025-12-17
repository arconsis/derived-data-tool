//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 19.08.25.
//

import Foundation

public final class ProgressReporterFactory {
    public static var `default`: ProgressReporterFactory {
        ProgressReporterFactory()
    }

    private var reporters: Set<ProgressReporter> = []

    init() {

    }

    public func addReporter(with id: String, prefix: String) {
        let reporter = ProgressReporter(id: id, prefix: prefix)
        guard !reporters.contains(reporter) else { return }
        reporters.insert(reporter)
    }

    public func removeReporter(with id: String) {
        if let reporter = reporters.first(where: { $0.id == id }) {
            reporters.remove(reporter)
        }
    }

    private func getReporter(with id: String) -> ProgressReporter? {
        return reporters.first(where: { $0.id == id })
    }

    public func report(percentage: Double, onReporterWith reporterId: String) {
        getReporter(with: reporterId)?.report(percentage: percentage)
    }

    public func report(step: Int, of totalSteps: Int, inPercentage: Bool = true, onReporterWith reporterId: String) {
        getReporter(with: reporterId)?.report(step: step, of: totalSteps, inPercentage: inPercentage)
    }

    public func report(finished: Bool, onReporterWith reporterId: String) {
        getReporter(with: reporterId)?.report(finished: finished)
    }

    public func report(text: String, clearLine: Bool = true, onReporterWith reporterId: String) {
        getReporter(with: reporterId)?.report(text: text, clearLine: clearLine)
    }
}
