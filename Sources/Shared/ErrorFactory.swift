//
//  ErrorFactory.swift
//
//
//  Created by Moritz Ellerbrock on 09.03.24.
//

import Foundation

public protocol Errorable: LocalizedError {
    var printsHelp: Bool { get }
}

public struct BaseError: Errorable {
    init(printsHelp: Bool,
         errorDescription: String? = nil,
         failureReason: String? = nil,
         recoverySuggestion: String? = nil,
         helpAnchor: String? = nil)
    {
        self.printsHelp = printsHelp
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
    }

    public var printsHelp: Bool
    public var errorDescription: String?
    public var failureReason: String?
    public var recoverySuggestion: String?
    public var helpAnchor: String?
}

public enum ErrorFactory {
    public static func intern(error: Error) -> BaseError {
        if let localizedError = error as? any LocalizedError {
            .init(printsHelp: true,
                  errorDescription: localizedError.errorDescription,
                  failureReason: localizedError.failureReason,
                  recoverySuggestion: localizedError.recoverySuggestion,
                  helpAnchor: localizedError.helpAnchor)
        } else {
            dependency(error: error, name: "internal")
        }
    }

    public static func dependency(error: Error, name: String) -> BaseError {
        if let localizedError = error as? any LocalizedError {
            .init(printsHelp: false,
                  errorDescription: name + ": " + (localizedError.errorDescription ?? ""),
                  failureReason: localizedError.failureReason,
                  recoverySuggestion: localizedError.recoverySuggestion,
                  helpAnchor: localizedError.helpAnchor)
        } else {
            .init(printsHelp: false,
                  errorDescription: name + ": " + error.localizedDescription,
                  failureReason: "",
                  recoverySuggestion: "",
                  helpAnchor: "")
        }
    }

    public static func failing(error: Errorable) -> BaseError {
        baseError(printsHelp: error.printsHelp,
                  errorDescription: error.errorDescription,
                  failureReason: error.failureReason,
                  recoverySuggestion: error.recoverySuggestion,
                  helpAnchor: error.helpAnchor)
    }

    public static func baseError(printsHelp: Bool,
                                 errorDescription: String? = nil,
                                 failureReason: String? = nil,
                                 recoverySuggestion: String? = nil,
                                 helpAnchor: String? = nil) -> BaseError
    {
        .init(printsHelp: printsHelp,
              errorDescription: errorDescription,
              failureReason: failureReason,
              recoverySuggestion: recoverySuggestion,
              helpAnchor: helpAnchor)
    }
}
