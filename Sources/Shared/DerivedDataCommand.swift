//
//  DerivedDataCommand.swift
//
//
//  Created by Moritz Ellerbrock on 17.12.25.
//

import ArgumentParser
import Foundation

/// Shared protocol for all derived-data-tool commands
/// Provides common structure for commands that use configuration and logging
public protocol DerivedDataCommand: AsyncParsableCommand {
    var verbose: Bool { get }
    var configFilePath: String? { get }
    var customGitRootpath: String? { get }
}

// MARK: - Supporting Types

/// Configuration for filtering targets, files, and functions
public struct FilterConfig {
    public let excludedTargets: [String]
    public let excludedFiles: [String]
    public let excludedFunctions: [String]
    public let includedTargets: [String]
    public let includedFiles: [String]
    public let includedFunctions: [String]

    public init(
        excludedTargets: [String] = [],
        excludedFiles: [String] = [],
        excludedFunctions: [String] = [],
        includedTargets: [String] = [],
        includedFiles: [String] = [],
        includedFunctions: [String] = []
    ) {
        self.excludedTargets = excludedTargets
        self.excludedFiles = excludedFiles
        self.excludedFunctions = excludedFunctions
        self.includedTargets = includedTargets
        self.includedFiles = includedFiles
        self.includedFunctions = includedFunctions
    }
}
