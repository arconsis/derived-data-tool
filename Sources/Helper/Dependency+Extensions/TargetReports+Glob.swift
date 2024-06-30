//
//  TargetReports+Glob.swift
//
//
//  Created by Moritz Ellerbrock on 11.05.23.
//

import Foundation
import Shared

public extension TargetReports {
    func exclude(targets: [String]) -> Self {
        let globs = targets.globify()
        var filteredTarget: [TargetReportElement] = []
        for target in self {
            if !globs.matches(target.name) {
                filteredTarget.append(target)
            }
        }

        return filteredTarget
    }
}
