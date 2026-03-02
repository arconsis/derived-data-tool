import ArgumentParser
import Build
import Compare
import Config
import Coverage
import Foundation
import Migrate
import Prototype
import Report
import Trend

@main
struct App: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Xcode code coverage analyzer with trend tracking and CI/CD integration",
        discussion: """
            A comprehensive code coverage tool for Xcode projects that analyzes test results, \
            tracks coverage metrics over time, and validates coverage thresholds. Features include \
            historical trend visualization, GitHub Actions integration, and configurable filtering \
            for targets and files.
            """,
        version: "0.0.0",
        subcommands: Self.subcommands
    )

    private static var subcommands: [ParsableCommand.Type] {
        #if DEBUG
            return [
                CoverageCommand.self,
                PrototypeCommand.self,
                BuildCommand.self,
                ConfigCommand.self,
                ReportCommand.self,
                CompareCommand.self,
                MigrateCommand.self,
                TrendCommand.self,
            ]
        #else
            return [
                CoverageCommand.self,
                BuildCommand.self,
                ConfigCommand.self,
                MigrateCommand.self,
                ReportCommand.self,
                TrendCommand.self,
            ]
        #endif
    }
}
