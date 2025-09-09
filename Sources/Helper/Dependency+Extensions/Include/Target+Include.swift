//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 08.09.25.
//

import DependencyInjection
import Foundation
import Shared

public extension Target {
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    func include(files: [String]) -> Self {
        let globs = files.globify()
        var filteredFiles: [File] = []
        for file in self.files {
            if globs.matches(file.name) {
                filteredFiles.append(file)
            }
        }

        if self.files.count != filteredFiles.count {
            logger.debug("Files: \(self.files.count) reducedBy: \(filteredFiles.count)")
        }
        return .init(name: name,
                     files: filteredFiles)
    }

    func include(functions: [String]) -> Self {
        var filteredFiles: [File] = []
        for file in files {
            filteredFiles.append(file.include(functions: functions))
        }

        return .init(name: name,
                     files: filteredFiles)
    }
}
