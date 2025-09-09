#!/usr/bin/env swift
import Foundation

// MARK: - Logging + Exit Functions
func log(_ message: String) {
    print("[sign-and-notarize] \(message)")
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
// MARK: - Argument Parsing
var executable: String?
var identity: String?
log(CommandLine.arguments.dropFirst().joined(separator: ", "))
var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next()?.trimmingCharacters(in: .whitespacesAndNewlines) {
    switch arg {
    case "--executable":
        executable = args.next()
    case "--identity":
        identity = args.next()
    default:
        exitWithError("Unknown option: \(arg)")
    }
}
if executable == nil || identity == nil || appleID == nil || teamID == nil
    || appSpecificPassword == nil
{
    exitWithError("Missing required arguments.")
}
// MARK: - Sign
let exec = executable!
let id = identity!
log("Signing \(exec) with identity \(id)...")
runShell("codesign --timestamp --options runtime --sign \(id) \(exec)")
log("Sign process completed.")
// MARK: - Shell Helper
@discardableResult
func runShell(_ command: String) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus
}
