//
//  DerivedDataCommand+Helpers.swift
//
//
//  Created by Moritz Ellerbrock on 17.12.25.
//

import DependencyInjection
import Foundation
import Helper
import Shared

// MARK: - Default Implementations for Commands

public extension DerivedDataCommand {
    /// Setup logger with verbose flag
    func setupLogger() {
        InjectedValues[\.logger] = MyLogger.makeLogger(verbose: verbose)
    }

    /// Load configuration from the specified path or default location
    func loadConfig() async throws -> Config {
        try await ConfigFactory.getConfig(at: URL(with: configFilePath))
    }

    /// Resolve the working directory based on custom path or git root
    func resolveWorkingDirectory(using fileHandler: FileHandler) async -> URL {
        if let customGitRootpath {
            return URL(with: customGitRootpath)
        } else if let gitRoot = await fileHandler.getGitRootDirectory().value {
            return gitRoot
        } else {
            return fileHandler.getCurrentDirectoryUrl()
        }
    }

    /// Extract filter configuration from config
    func extractFilters(from config: Config) -> FilterConfig {
        FilterConfig(
            excludedTargets: config.excluded?.targets ?? [],
            excludedFiles: config.excluded?.files ?? [],
            excludedFunctions: config.excluded?.functions ?? [],
            includedTargets: config.included?.targets ?? [],
            includedFiles: config.included?.files ?? [],
            includedFunctions: config.included?.functions ?? []
        )
    }

    /// Create a new FileHandler instance
    func makeFileHandler() -> FileHandler {
        FileHandler()
    }

    /// Create a new Tools instance
    func makeTools() -> Tools {
        Tools()
    }
}
