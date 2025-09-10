//
//  ConfigCommand.swift
//
//
//  Created by Moritz Ellerbrock on 15.06.23.
//

import ArgumentParser
import Foundation

public class VersionCommand: AsyncParsableCommand {
    // MARK: - AsyncParsableCommand
    @Flag(name: [.customShort("v"), .customLong("version")], help: "Display Version number")
    private var displayVersion: Bool = false

    // MARK: - Implementation

    public required init() {}

    public func run() async throws {
        if displayVersion {
            FileHandle.standardOutput.write("0.0.0".data(using: .utf8)!)
        }
    }
}
