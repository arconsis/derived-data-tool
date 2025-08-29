#!/usr/bin/env swift
import Foundation

// MARK: - Logging + Exit Functions

func writeStandardError(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func exitWithError(_ message: String) -> Never {
    writeStandardError("❌ \(message)")
    exit(1)
}

func exitWith(error: any Error) -> Never {
    writeStandardError("❌ \(error.localizedDescription)")
    exit(1)
}

func printInfo(_ message: String) {
    print("ℹ️ \(message)")
}

func printSuccess(_ message: String) {
    print("✅ \(message)")
}

// MARK: - Version Helpers

func parseVersion(_ version: String) -> [Int]? {
    let components = version.split(separator: ".").map(String.init)
    guard (1...4).contains(components.count),
          components.allSatisfy({ Int($0) != nil }) else {
        return nil
    }
    return components.compactMap { Int($0) }
}

func formatVersion(_ version: [Int]) -> String {
    version.map(String.init).joined(separator: ".")
}

enum VersionPart: String {
    case major, minor, bugfix, build

    var index: Int {
        switch self {
        case .major: 0
        case .minor: 1
        case .bugfix: 2
        case .build: 3
        }
    }
}

func increment(version: [Int], part: VersionPart) -> [Int] {
    var newVersion = version
    let index = part.index

    // Ensure version has enough components
    while newVersion.count <= index {
        newVersion.append(0)
    }

    newVersion[index] += 1

    // Only reset less significant components for major/minor/bugfix
    if part != .build {
        for i in (index + 1)..<3 {
            if i < newVersion.count {
                newVersion[i] = 0
            }
        }

        if newVersion.count == 4 {
            newVersion[3] += 1 // Increment build version if it exists
        }
    }

    return newVersion
}

// MARK: - Entry Point

enum Mode: String {
    case check, bugfix, minor, major, build

    var versionPart: VersionPart {
        switch self {
        case .check: .build // Check does not change the version
        case .bugfix: .bugfix
        case .minor: .minor
        case .major: .major
        case .build: .build
        }
    }
}

guard CommandLine.arguments.count == 3 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <check|bugfix|minor|major|build> <version>")
}

let modeRaw = CommandLine.arguments[1].lowercased()
let versionInput = CommandLine.arguments[2]

guard let mode = Mode(rawValue: modeRaw) else {
    exitWithError("Unknown mode: '\(modeRaw)'. Must be one of check, bugfix, minor, major, build.")
}

guard var parsed = parseVersion(versionInput) else {
    exitWithError("Invalid version: '\(versionInput)'. Must be 1 to 4 dot-separated integers.")
}

switch mode {
case .check:
    printSuccess("Version is valid: \(formatVersion(parsed))")
case .bugfix, .minor, .major, .build:
    let incremented = increment(version: parsed, part: mode.versionPart)
    FileHandle.standardOutput.write((formatVersion(incremented)).data(using: .utf8)!)
}
