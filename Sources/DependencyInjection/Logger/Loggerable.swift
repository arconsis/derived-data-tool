//
//  Loggerable.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation

public protocol Loggerable: Decodable, Sendable {
    static func log(_ level: LogLevel, message: String, fileId: String)

    var verbose: Bool { get set }
}

extension Loggerable {
    func isLoggable(with logLevel: LogLevel) -> Bool {
        if verbose { return true }
        return logLevel.isLoggable
    }

    func _log(_ level: LogLevel, message: String, fileId: String) {
        if isLoggable(with: level), !message.isEmpty {
            Self.log(level, message: message, fileId: fileId)
        }
    }
}

public extension Loggerable {
    func log(_ items: Any..., fileId: String = #fileID) {
        let messages = items.map { String(describing: $0) }
        _log(.log, message: messages.joined(separator: " "), fileId: fileId)
    }

    func log(_ output: String, fileId: String = #fileID) {
        _log(.log, message: output, fileId: fileId)
    }

    func log(_ output: String ..., fileId: String = #fileID) {
        let output = convert(output)
        log(output, fileId: fileId)
    }

    func log(_ outputs: [String], fileId: String = #fileID) {
        let output = outputs.joined(separator: " ")
        log(output, fileId: fileId)
    }

    func log(_ error: Error, fileId: String = #fileID) {
        log(String(reflecting: error), fileId: fileId)
    }

    func debug(_ items: Any..., fileId: String = #fileID) {
        let messages = items.map { String(describing: $0) }
        _log(.debug, message: messages.joined(separator: " "), fileId: fileId)
    }

    func debug(_ output: String, fileId: String = #fileID) {
        _log(.debug, message: output, fileId: fileId)
    }

    func debug(_ output: String ..., fileId: String = #fileID) {
        let output = convert(output)
        debug(output, fileId: fileId)
    }

    func debug(_ outputs: [String], fileId: String = #fileID) {
        let output = outputs.joined(separator: " ")
        debug(output, fileId: fileId)
    }

    func debug(_ error: Error, fileId: String = #fileID) {
        debug(String(reflecting: error), fileId: fileId)
    }

    func warn(_ items: Any..., fileId: String = #fileID) {
        let messages = items.map { String(describing: $0) }
        _log(.warning, message: messages.joined(separator: " "), fileId: fileId)
    }

    func warn(_ output: String, fileId: String = #fileID) {
        _log(.warning, message: output, fileId: fileId)
    }

    func warn(_ output: String ..., fileId: String = #fileID) {
        let output = convert(output)
        warn(output, fileId: fileId)
    }

    func warn(_ outputs: [String], fileId: String = #fileID) {
        let output = outputs.joined(separator: " ")
        warn(output, fileId: fileId)
    }

    func warn(_ error: Error, fileId: String = #fileID) {
        warn(String(reflecting: error), fileId: fileId)
    }

    func error(_ items: Any..., fileId: String = #fileID) {
        let messages = items.map { String(describing: $0) }
        _log(.error, message: messages.joined(separator: " "), fileId: fileId)
    }

    func error(_ output: String, fileId: String = #fileID) {
        _log(.warning, message: output, fileId: fileId)
    }

    func error(_ output: String..., fileId: String = #fileID) {
        let output = convert(output)
        error(output, fileId: fileId)
    }

    func error(_ outputs: [String], fileId: String = #fileID) {
        let output = outputs.joined(separator: " ")
        error(output, fileId: fileId)
    }

    func error(_ err: Error, fileId: String = #fileID) {
        error(String(reflecting: err), fileId: fileId)
    }

    func convert(_ output: [String]) -> String {
        var array = [""]
        for part in output {
            array.append(part)
        }
        if !array.isEmpty {
            array.append("\n")
        }
        return array.joined(separator: " ")
    }

    func convert(_ output: String...) -> String {
        var array = [""]
        for part in output {
            array.append(part)
        }
        if !array.isEmpty {
            array.append("\n")
        }
        return array.joined(separator: " ")
    }
}

public enum LogLevel: Int {
    case none = 0
    case error = 1
    case warning = 2
    case log = 3
    case verbose = 4
    case debug = 5

    init(rawValue: String?) {
        self = .none

        if let rawValue {
            if rawValue == "verbose" {
                self = .verbose
            } else if rawValue == "debug" {
                self = .debug
            } else if rawValue == "warning" {
                self = .warning
            } else if rawValue == "error" {
                self = .error
            } else if rawValue == "log" {
                self = .log
            } else {
                self = .none
            }
        }
    }

    public var isLoggable: Bool {
        let value = ProcessInfo.processInfo.environment["LOG_LEVEL"] ?? "log"
        let systemLevel = LogLevel(rawValue: value)
        return systemLevel.rawValue >= rawValue
    }
}
