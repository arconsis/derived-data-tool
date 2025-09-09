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
let keychainPassword = UUID().uuidString
let p12Base64 = env["P12_BASE64"] ?? ""
let p12Password = env["P12_PASSWORD"] ?? ""
let productPath = env["PRODUCT_PATH"] ?? ""
let developerIdentity = env["DEVELOPER_IDENTITY"] ?? "Developer ID Application: Your Name (TEAMID)"

if productPath.isEmpty {
    print("❌ PRODUCT_PATH environment variable is not set.")
    exit(1)
}

// Import signing cert
runShell("security create-keychain -p \"\(keychainPassword)\" build.keychain")
runShell("security set-keychain-settings -lut 21600 build.keychain")
runShell("security default-keychain -s build.keychain")
runShell("security unlock-keychain -p \"\(keychainPassword)\" build.keychain")
runShell("echo \"\(p12Base64)\" | base64 --decode > cert.p12")
runShell("security import cert.p12 -k build.keychain -P \"\(p12Password)\" -T /usr/bin/codesign")
runShell("security find-identity -v build.keychain")

// Sign and verify
runShell("codesign --force --timestamp --options=runtime --sign \"\(developerIdentity)\" \"\(productPath)\"")
runShell("codesign --verify --verbose \"\(productPath)\"")
