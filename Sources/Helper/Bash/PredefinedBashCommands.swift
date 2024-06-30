//
//  PredefinedBashCommands.swift
//
//
//  Created by Moritz Ellerbrock on 23.05.23.
//

import Foundation

enum PredefinedBashCommands {
    case gitRootDirectory
    case findXCResultAt(URL)
    case findFiles(url: URL, fileExtension: String)
    case findFile(filename: String, url: URL)
    case findFilesWithExtensions(url: URL, fileExtensions: [String])
    case xccov(file: URL)
    case xccovTargetsOnly(file: URL)
    case xcresulttool(file: URL)

    var completeCommand: String {
        switch self {
        case .gitRootDirectory:
            return "git rev-parse --show-toplevel"
        case let .findXCResultAt(url):
            return "find \(url.fullPath) -name *.xcresult"
        case let .findFiles(url, fileExtension):
            return "find \(url.fullPath) -name *.\(fileExtension)"
        case let .findFilesWithExtensions(url, extensions):
            let extensionsCommands = extensions.map { "-name \"*.\($0)\"" }
            return "find \(url.fullPath) -type f \\( \(extensionsCommands.joined(separator: " -o ")) \\)"
        case let .findFile(filename, url):
            return "find \(url.fullPath) -name \(filename)"
        case let .xccov(url):
            return "xcrun xccov view --json --report \(url.fullPath)"
        case let .xccovTargetsOnly(url):
            return "xcrun xccov view --json --only-targets --report \(url.fullPath)"
        case let .xcresulttool(url):
            return "xcrun xcresulttool get --path \(url.fullPath) --format json"
        }
    }

    var command: String {
        separatedCommand.first!
    }

    var arguments: [String] {
        separatedCommand.dropFirst().compactMap { String($0) }
    }

    var separatedCommand: [String] {
        switch self {
        case let .findFilesWithExtensions(url, fileExtensions):
            let extensionsCommands = fileExtensions.map { "-name \"*.\($0)\"" }
            return ["find", "\(url.fullPath)", "-type f", "\\( \(extensionsCommands.joined(separator: " -o ")) \\)"]
        default:
            return completeCommand.split(separator: " ").map(String.init)
        }
    }
}
