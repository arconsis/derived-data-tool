#!/usr/bin/env swift
import Foundation

// MARK: - Logging + Exit Functions
// MARK: - GitHub Summary Helper
// func updateSummary(_ message: String, logOutput: Bool = true) {
// Import helpers
// If running as a script, use: -I../../.github-helpers and then: import helpers
// Otherwise, you may need to use #include or other Swift scripting import methods
// MARK: - Argument Parsing
guard CommandLine.arguments.count == 2 else {
    exitWithError("Usage: \(CommandLine.arguments[0]) <tag>")
}
let tag = CommandLine.arguments[1]

// MARK: - Git Tagging
log("Configuring git user...")
runShell("git config user.name github-actions", logOutput: false)
runShell("git config user.email github-actions@github.com", logOutput: false)
log("Tagging with version \(tag)...")
runShell("git tag \(tag)")
// Print and stash uncommitted changes before rebasing
log("Checking for uncommitted changes...")
runShell("git status --short")
runShell("git stash --include-untracked")
runShell("git pull --rebase")
runShell("git push --tags")
log("Tag \(tag) added and pushed.")
