//
//  Loggerable+Implementation.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation
import OSLog

public struct MyLogger: Loggerable, Sendable {
    public static func makeLogger(verbose: Bool = false) -> Self {
        MyLogger(verbose: verbose)
    }

    public var verbose: Bool = false

    public static func log(_ level: LogLevel, message: String, fileId: String) {
        let logger = Self.output(fileId: fileId)
        switch level {
        case .none:
            break
        case .error:
            logger.error("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .log:
            logger.log("\(message)")
        case .verbose:
            logger.info("\(message)")
        case .debug:
            logger.debug("\(message)")
        }
    }

    private static func output(fileId: String) -> Logger {
        let parts = fileId.components(separatedBy: "/")
        let subsystem = parts.first ?? "subsystem"
        let module = (parts.dropFirst().first ?? "second").replacingOccurrences(of: ".swift", with: "")
        return Logger(subsystem: subsystem, category: module)
    }
}
