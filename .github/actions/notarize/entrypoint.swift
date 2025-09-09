#!/usr/bin/env swift
import Foundation

func log(_ message: String) {
    print("[notarize] \(message)")
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

var executable: String?
var appleID: String?
var teamID: String?
var appSpecificPassword: String?

var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next()?.trimmingCharacters(in: .whitespacesAndNewlines) {
    switch arg {
    case "--executable":
        executable = args.next()
    case "--apple_id":
        appleID = args.next()
    case "--team_id":
        teamID = args.next()
    case "--password":
        appSpecificPassword = args.next()
    default:
        exitWithError("Unknown option: \(arg)")
    }
}
if executable == nil || appleID == nil || teamID == nil || appSpecificPassword == nil {
    exitWithError("Missing required arguments.")
}
let exec = executable!
let apple = appleID!
let team = teamID!
let pw = appSpecificPassword!
log("Submitting \(exec) for notarization...")
runShell("xcrun notarytool submit \(exec) --apple-id \(apple) --team-id \(team) --password \(pw) --wait")
log("Stapling notarization ticket to \(exec)...")
runShell("xcrun stapler staple \(exec)")
log("Notarization process completed.")

@discardableResult
func runShell(_ command: String) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", command]
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus
}
