#!/usr/bin/env swift
import Foundation

// MARK: - Logging + Exit Functions
// MARK: - GitHub Summary Helper
func updateSummary(_ message: String) {
    if let summaryPath = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] {
        let entry = message + "\n"
        if let data = entry.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: summaryPath)) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? entry.write(toFile: summaryPath, atomically: true, encoding: .utf8)
            }
        }
    }
}
func log(_ message: String) {
    print("[build-executable] \(message)")
}
func writeStandardError(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}
func exitWithError(_ message: String) -> Never {
    writeStandardError("❌ \(message)")
    updateSummary("❌ \(message)")
    exit(1)
}

// MARK: - Shell Helpers
@discardableResult
func system(_ command: String) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus
}
func shellOutput(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    return String(data: data, encoding: .utf8) ?? ""
}

// MARK: - Argument Parsing
var arch: String?
var output: String?
var args = CommandLine.arguments.dropFirst()
while let arg = args.first {
    switch arg {
    case "--arch":
        args = args.dropFirst()
        arch = args.first
    case "--output":
        args = args.dropFirst()
        output = args.first
    default:
        exitWithError("Unknown option: \(arg)")
    }
    args = args.dropFirst()
}
if arch == nil || output == nil {
    exitWithError("Missing required arguments.")
}
// MARK: - Build Logic

let archValue = arch!
let outputValue = output!

// Get the executable name from swift package show-executables
let executablesOutput = shellOutput("swift package show-executables")
let executableNames =
    executablesOutput
    .split(separator: "\n")
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.contains("(") && !$0.isEmpty }
let executableName = executableNames.first ?? "App"

if archValue == "universal" {
    log("Building universal binary (arm64 & x86_64)...")
    let buildStatus = system("swift build -c release --arch arm64 --arch x86_64")
    if buildStatus == 0 {
        updateSummary("✅ Built universal binary (arm64 & x86_64)")
    } else {
        updateSummary("❌ Failed to build universal binary")
        exit(1)
    }
    let binPath = shellOutput("swift build -c release --show-bin-path")
    let appPath = binPath.trimmingCharacters(in: .whitespacesAndNewlines) + "/" + executableName
    let cpStatus = system("cp \(appPath) \(outputValue)")
    if cpStatus == 0 {
        updateSummary("✅ Copied universal binary to output")
    } else {
        updateSummary("❌ Failed to copy universal binary to output")
        exit(1)
    }
} else if archValue == "arm64" || archValue == "x86_64" {
    log("Building for \(archValue)...")
    let buildStatus = system("swift build -c release --arch \(archValue)")
    if buildStatus == 0 {
        updateSummary("✅ Built binary for \(archValue)")
    } else {
        updateSummary("❌ Failed to build binary for \(archValue)")
        exit(1)
    }
    let binPath = shellOutput("swift build -c release --show-bin-path")
    let appPath = binPath.trimmingCharacters(in: .whitespacesAndNewlines) + "/" + executableName
    let cpStatus = system("cp \(appPath) \(outputValue)")
    if cpStatus == 0 {
        updateSummary("✅ Copied binary to output")
    } else {
        updateSummary("❌ Failed to copy binary to output")
        exit(1)
    }
} else {
    exitWithError("Unknown architecture: \(archValue)")
}
log("Build completed: \(outputValue)")
updateSummary("✅ Build completed: \(outputValue)")
