import ArgumentParser
import Build
import Compare
import Config
import Coverage
import Foundation
import Migrate
import Prototype
import Report

@main
struct App: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Code coverage tool",
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
            ]
        #else
            return [
                CoverageCommand.self,
                BuildCommand.self,
                ConfigCommand.self,
                ReportCommand.self,
            ]
        #endif
    }
}
