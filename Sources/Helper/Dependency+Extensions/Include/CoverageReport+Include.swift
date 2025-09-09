//
//  CoverageReport+Exclude.swift
//
//
//  Created by Moritz Ellerbrock on 11.05.23.
//

import DependencyInjection
import Foundation
import Shared

public extension CoverageReport {
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    func include(targets: [String]) -> Self {
        let globs = targets.globify()
        var filteredTarget: [Target] = []

        for target in self.targets {
            if globs.matches(target.name) {
                filteredTarget.append(target)
            }
        }

        if self.targets.count != filteredTarget.count {
            logger.debug("Targets: \(self.targets.count) reducedBy: \(filteredTarget.count)")
        }
        return .init(targets: filteredTarget)
    }

    func include(files: [String]) -> Self {
        var filteredTargets: [Target] = []
        for target in targets {
            filteredTargets.append(target.include(files: files))
        }

        return .init(targets: filteredTargets)
    }

    func include(functions: [String]) -> Self {
        var filteredTargets: [Target] = []
        for target in targets {
            filteredTargets.append(target.include(functions: functions))
        }

        return .init(targets: filteredTargets)
    }
}




