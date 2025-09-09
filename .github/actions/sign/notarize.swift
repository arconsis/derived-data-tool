#!/usr/bin/env swift
import Foundation

func runShell(_ command: String, env: [String: String] = [:]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", command]
    process.environment = env.isEmpty ? nil : env
    try? process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        print("❌ Command failed: \(command)")
        exit(1)
    }
}

let env = ProcessInfo.processInfo.environment
let productPath = env["PRODUCT_PATH"] ?? ""
let toolName = env["TOOL_NAME"] ?? "YourToolName"
let appleID = env["APPLE_ID"] ?? ""
let teamID = env["TEAMID"] ?? ""
let appSpecificPassword = env["APPLE_APP_SPECIFIC_PASSWORD"] ?? ""

if productPath.isEmpty {
    print("❌ PRODUCT_PATH environment variable is not set.")
    exit(1)
}

// Notarize
let zipName = "\(toolName).zip"
runShell("ditto -c -k --keepParent \"\(productPath)\" \(zipName)")
runShell("xcrun notarytool submit \(zipName) --apple-id \"\(appleID)\" --team-id \"\(teamID)\" --password \"\(appSpecificPassword)\" --wait")
runShell("xcrun stapler staple \(zipName)")
