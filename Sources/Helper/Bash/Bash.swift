import DependencyInjection
import Foundation
import Shared

public typealias ExecutingResult = Result<String, CCCLIError>

public protocol Executing {
    func run(_ commandName: String, with arguments: [String]) async -> ExecutingResult
}

enum BashError: Errorable {
    case commandNotFound(name: String)
    case noCommandProvided
    case executionError(description: String)
    case unexpectedTermination(Int, String)
    case unknownFutureError(Int, String)
    case undefinedThrowingError(String)

    var printsHelp: Bool { false }
}

public class Bash {
    @Injected(\.logger) private var logger: Loggerable

    private var resolvedCommands: [String: String] = [:]
    public init() {}

    private func log(_ command: String, arguments: [String]) {
        let cleanCommand = command.replacingOccurrences(of: "/usr/bin/", with: "").replacingOccurrences(of: "/bin/bash", with: "sh")
        let argumentString: String = arguments.joined(separator: " ")
        logger.debug("\(cleanCommand) \(argumentString)")
    }

    private func execute(_ commandName: String, arguments: [String]) async -> ExecutingResult {
        await runAsync(commandName, arguments: arguments)
    }

    private func resove(_ command: String) async -> ExecutingResult {
        let resolvedCommandResult = await resolveAsync(command)
        if let resolvedCommand = try? resolvedCommandResult.get() {
            resolvedCommands[command] = resolvedCommand
        }
        return resolvedCommandResult
    }

    private func resolveAsync(_ command: String) async -> ExecutingResult {
        let commandResult = await runAsync("/bin/bash", arguments: ["-l", "-c", "which \(command)"])
        switch commandResult {
            case let .success(success):
                let output = success.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                return .success(output)
            case let .failure(failure):
                return .failure(.init(with: BashError.executionError(description: failure.localizedDescription)))
        }
    }

    @MainActor
    private func runAsync(_ command: String, arguments: [String] = []) async -> ExecutingResult {
        do {
            log(command, arguments: arguments)
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            let process = Process()
            process.launchPath = command
            process.arguments = arguments
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try? process.run()

            var outLines = [String]()
            for try await line in outputPipe.fileHandleForReading.bytes.lines {
                outLines.append(line)
            }

            // add the stderr task
            var errLines = [String]()
            for try await line in errorPipe.fileHandleForReading.bytes.lines {
                errLines.append(line)
            }

            while process.isRunning {
                logger.log("still waiting to finish")
            }

            let exitCode = process.terminationReason

            switch exitCode {
                case .exit where errLines.count == 0:
                    let outputString = outLines.toString()
                    return .success(outputString)

                case .exit:
                    let outputString = errLines.toString()
                    return .failure(.init(with: BashError.executionError(description: outputString)))

                case .uncaughtSignal:
                    let outputString = errLines.toString()
                    return .failure(.init(with: BashError.unexpectedTermination(exitCode.rawValue, outputString)))

                @unknown default:
                    let outputString = errLines.toString()
                    return .failure(.init(with: BashError.unknownFutureError(exitCode.rawValue, outputString)))
            }
        } catch {
            return .failure(.init(with: BashError.undefinedThrowingError(error.localizedDescription)))
        }
    }
}

extension Bash: Executing {
    public func run(_ commandName: String, with arguments: [String]) async -> ExecutingResult {
        if let resolvedCommand = resolvedCommands[commandName] {
            return await execute(resolvedCommand, arguments: arguments)
        } else if let resolvedResult = await resove(commandName).value {
            return await execute(resolvedResult, arguments: arguments)
        } else {
            return .failure(.init(with: BashError.commandNotFound(name: commandName)))
        }
    }
}

extension Collection where Element == String {
    func toString() -> String {
        joined(separator: "\n")
    }
}
