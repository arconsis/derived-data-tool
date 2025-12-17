//
//  Target+Exclude.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 08.09.25.
//

import Shared
import DependencyInjection

extension File {
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    public func include(functions: [String]) -> Self {
        guard !functions.isEmpty else { return self }
        let globs = functions.globify()
        var filteredFunctions: [Function] = []
        for function in self.functions {
            if globs.matches(function.name) {
                filteredFunctions.append(function)
            }
        }

        if self.functions.count != filteredFunctions.count {
            logger.debug("Functions: \(self.functions.count) reducedBy: \(filteredFunctions.count)")
        }
        return .init(name: name,
                     path: path,
                     functions: filteredFunctions)
    }
}
