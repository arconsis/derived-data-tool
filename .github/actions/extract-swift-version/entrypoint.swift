#!/usr/bin/env swift
import Foundation

// MARK: - Logging
func log(_ message: String) {
    print("[extract-swift-version] \(message)")
}

// MARK: - Read First Line
let packageSwiftPath = "Package.swift"
guard let file = FileHandle(forReadingAtPath: packageSwiftPath) else {
    print("❌ Package.swift not found.")
    exit(1)
}
let firstLine =
    String(data: file.readData(upToCount: 256) ?? Data(), encoding: .utf8)?.components(
        separatedBy: "\n"
    ).first ?? ""
file.closeFile()
log("First line: \(firstLine)")

// MARK: - Extract Swift Version
let regex = try! NSRegularExpression(
    pattern: "// swift-tools-version: ([0-9]+\\.[0-9]+(\\.[0-9]+)?)")
if let match = regex.firstMatch(
    in: firstLine, range: NSRange(firstLine.startIndex..., in: firstLine)),
    let range = Range(match.range(at: 1), in: firstLine)
{
    let swiftVersion = String(firstLine[range])
    log("Swift version detected: \(swiftVersion)")
    if let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"] {
        try? "swift-version=\(swiftVersion)\n".write(
            toFile: githubOutput, atomically: true, encoding: .utf8)
    }
    if let githubStepSummary = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] {
        try? "Swift \(swiftVersion) Detected\n".write(
            toFile: githubStepSummary, atomically: true, encoding: .utf8)
    }
} else {
    print("❌ Could not extract Swift version.")
    exit(1)
}
