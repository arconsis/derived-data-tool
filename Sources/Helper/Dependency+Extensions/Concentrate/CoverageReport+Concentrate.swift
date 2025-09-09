//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 08.09.25.
//

import Foundation
import Shared


public extension CoverageReport {
    func concentrate(on includedTargets: [Target]) -> Self {
        let targetNames = includedTargets.map { $0.name }
        return concentrate(on: targetNames)
    }

    func concentrate(on includedTargets: [String]) -> Self {
        var filteredTarget: [Target] = []

        for target in targets {
            if includedTargets.contains(target.name) {
                filteredTarget.append(target)
            }
        }

        return .init(targets: filteredTarget)
    }
}
