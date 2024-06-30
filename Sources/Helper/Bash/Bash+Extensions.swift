//
//  Bash+Extensions.swift
//
//
//  Created by Moritz Ellerbrock on 05.05.23.
//

import AsyncAlgorithms
import Foundation

extension Bash {}

// extension Bash: CommandExecuting {
//    func run(commandName: String, arguments: [String] = []) throws -> String {
//        return try run(commandName, with: arguments)
//    }
//
//    func run(resolvingCommandName: String, arguments: [String] = []) throws -> String {
//        return try run(resolve(resolvingCommandName), with: arguments)
//    }
//
//    func resolve(_ command: String) throws -> String {
//        guard var bashCommand = try? run("/bin/bash" , with: ["-l", "-c", "which \(command)"]) else {
//            throw BashError.commandNotFound(name: command)
//        }
//        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
//        return bashCommand
//    }
//
//    fileprivate func run(_ command: String, arguments: [String] = []) throws -> String {
//        printCommand(command, arguments: arguments)
//        let outputPipe = Pipe()
//        let errorPipe = Pipe()
//        let process = Process()
//        process.launchPath = command
//        process.arguments = arguments
//        process.standardOutput = outputPipe
//        process.standardError = errorPipe
//        try process.run()
//        process.waitUntilExit()
//
//        var outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
//        if outputData.isEmpty {
//            outputData = outputPipe.fileHandleForReading.availableData
//        }
//
//        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//        if !errorData.isEmpty {
//            let errorDescription = String(decoding: errorData, as: UTF8.self)
//            printOutput(errorDescription)
//            throw BashError.executionError(description: errorDescription)
//        }
//        let output = String(decoding: outputData, as: UTF8.self)
//        printOutput(output)
//        return output
//    }
// }
