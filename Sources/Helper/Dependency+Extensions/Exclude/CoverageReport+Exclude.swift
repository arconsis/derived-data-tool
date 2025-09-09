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

    func exclude(targets: [String]) -> Self {
        let globs = targets.globify()
        var filteredTarget: [Target] = []

        for target in self.targets {
            if !globs.matches(target.name) {
                filteredTarget.append(target)
            }
        }

        if self.targets.count != filteredTarget.count {
            logger.debug("Targets: \(self.targets.count) reducedBy: \(filteredTarget.count)")
        }
        return .init(targets: filteredTarget)
    }

    func exclude(files: [String]) -> Self {
        var filteredTargets: [Target] = []
        for target in targets {
            filteredTargets.append(target.exclude(files: files))
        }

        return .init(targets: filteredTargets)
    }

    func exclude(functions: [String]) -> Self {
        var filteredTargets: [Target] = []
        for target in targets {
            filteredTargets.append(target.exclude(functions: functions))
        }

        return .init(targets: filteredTargets)
    }
}




