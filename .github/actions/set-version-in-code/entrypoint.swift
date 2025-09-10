import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    print("Usage: set-version-in-code.swift <version>")
    exit(1)
}

let newVersion = arguments[1]
let filePath = "Sources/Command/Version/VersionCommand.swift"
let fullPath = FileManager.default.currentDirectoryPath + "/" + filePath

do {
    var content = try String(contentsOfFile: fullPath, encoding: .utf8)
    let pattern = "0.0.0"
    if content.contains(pattern) {
        content = content.replacingOccurrences(of: pattern, with: newVersion)
        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        print("Version updated to \(newVersion) in \(filePath)")
    } else {
        print("Pattern \(pattern) not found in \(filePath)")
        exit(2)
    }
} catch {
    print("Error: \(error)")
    exit(3)
}
