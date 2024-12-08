//
//  FullCoverageReport+Exclude.swift
//
//
//  Created by Moritz Ellerbrock on 11.05.23.
//

import DependencyInjection
import Foundation
import Shared

public extension FullCoverageReport {
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

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

public extension Target {
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    func exclude(files: [String]) -> Self {
        let globs = files.globify()
        var filteredFiles: [File] = []
        for file in self.files {
            if !globs.matches(file.name) {
                filteredFiles.append(file)
            }
        }

        if self.files.count != filteredFiles.count {
            logger.debug("Files: \(self.files.count) reducedBy: \(filteredFiles.count)")
        }
        return .init(name: name,
                     files: filteredFiles)
    }

    func exclude(functions: [String]) -> Self {
        var filteredFiles: [File] = []
        for file in files {
            filteredFiles.append(file.exclude(functions: functions))
        }

        return .init(name: name,
                     files: filteredFiles)
    }
}

extension File {
    private var logger: Loggerable {
        InjectedValues[\.logger]
    }

    public func exclude(functions: [String]) -> Self {
        let globs = functions.globify()
        var filteredFunctions: [Function] = []
        for function in self.functions {
            if !globs.matches(function.name) {
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
