#!/usr/bin/env swift
import Foundation

// MARK: - Logging + Exit Functions

func log(_ message: String) {
    print("[create-release-branch] \(message)")
}

func writeStandardError(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func exitWithError(_ message: String) -> Never {
    writeStandardError("❌ \(message)")
    exit(1)
}

// MARK: - Shell Command Helper

@discardableResult
func runShell(_ command: String, printOutput: Bool = true) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    try? task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if printOutput, let output = String(data: data, encoding: .utf8), !output.isEmpty {
        print(output)
    }
    task.waitUntilExit()
    return task.terminationStatus
}

// MARK: - Main Logic

guard CommandLine.arguments.count == 2 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <release-version>")
}

let releaseVersion = CommandLine.arguments[1]
let branchName = "releases/\(releaseVersion)"

// Delete remote branch if it exists
if runShell("git ls-remote --exit-code --heads origin \(branchName)", printOutput: false) == 0 {
    log("Remote branch \(branchName) already exists. Deleting it.")
    runShell("git push origin --delete \(branchName)")
}

// Delete local branch if it exists
if runShell("git show-ref --verify --quiet refs/heads/\(branchName)", printOutput: false) == 0 {
    log("Local branch \(branchName) already exists. Deleting it.")
    runShell("git branch -D \(branchName)")
}

// Create and checkout new branch
log("Creating and checking out new branch \(branchName)")
runShell("git checkout -b \(branchName)")

// Push new branch to remote
log("Pushing new branch to remote")
runShell("git push --set-upstream origin \(branchName)")

// Update .version file with the new release version
log("Updating .version file")
do {
    try releaseVersion.write(toFile: ".version", atomically: true, encoding: .utf8)
} catch {
    exitWithError("Failed to write .version file: \(error)")
}

// Update version in App.swift
log("Updating version in Sources/App/App.swift")
let appSwiftPath = "Sources/App/App.swift"
let newAppSwiftPath = "Sources/App/new_App.swift"
do {
    let appSwiftContent = try String(contentsOfFile: appSwiftPath)
    let updatedContent = appSwiftContent.replacingOccurrences(
        of: #"version: ".*""#,
        with: #"version: "\(releaseVersion)""#,
        options: .regularExpression
    )
    try updatedContent.write(toFile: newAppSwiftPath, atomically: true, encoding: .utf8)
    try FileManager.default.removeItem(atPath: appSwiftPath)
    try FileManager.default.moveItem(atPath: newAppSwiftPath, toPath: appSwiftPath)
} catch {
    exitWithError("Failed to update App.swift: \(error)")
}

// Show git status after changes
log("Git status after changes")
runShell("git status")

// Commit bumped version
log("Committing bumped version")
runShell("git add .version Sources/App/App.swift")
runShell("git commit -m \"[BOT] update App version to \(releaseVersion)\" --author=\"Moritz Ellerbrock <github@elmoritz.eu>\"")
runShell("git config user.name \"github-release[bot]\"")
runShell("git config user.email \"github.release@elmoritz.eu\"")
runShell("git push")

log("Release branch creation and version bump complete.")
