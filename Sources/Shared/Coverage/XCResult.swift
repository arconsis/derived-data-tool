//
//  XCResult.swift
//
//
//  Created by Moritz Ellerbrock on 02.06.23.
//

import Foundation

public struct XCResult {
    let type: String
    let metrics: Metrics
}

extension XCResult {
    struct Metrics {
        let testsCount: Int
        let testsFailedCount: Int
        let testsSkippedCount: Int
        let warningCount: Int

        static func convert(_ metric: ActionResultMetrics) -> Self {
            .init(testsCount: metric.testsCount?.value.toInt() ?? 0,
                  testsFailedCount: metric.testsFailedCount?.value.toInt() ?? 0,
                  testsSkippedCount: metric.testsSkippedCount?.value.toInt() ?? 0,
                  warningCount: metric.warningCount?.value.toInt() ?? 0)
        }
    }
}

extension String {
    func toInt(_ fallback: Int = -1) -> Int {
        Int(self) ?? fallback
    }
}
