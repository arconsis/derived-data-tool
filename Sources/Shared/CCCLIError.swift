//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 28.04.24.
//

import Foundation

public struct CCCLIError: Error {
    public var printsHelp: Bool
    public var errorDescription: String?
    public var failureReason: String?
    public var recoverySuggestion: String?
    public var helpAnchor: String?
    
    public init(with errorable: Errorable) {
        self.printsHelp = errorable.printsHelp
        self.errorDescription = errorable.errorDescription
        self.failureReason = errorable.failureReason
        self.recoverySuggestion = errorable.recoverySuggestion
        self.helpAnchor = errorable.helpAnchor
    }
    
    public init(printsHelp: Bool,
                errorDescription: String? = nil,
                failureReason: String? = nil,
                recoverySuggestion: String? = nil,
                helpAnchor: String? = nil) {
        self.printsHelp = printsHelp
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
    }

    public init(printsHelp: Bool,
                error: Error) {
        self.printsHelp = printsHelp
        self.errorDescription = error.localizedDescription
        self.failureReason = nil
        self.recoverySuggestion = nil
        self.helpAnchor = nil
    }
}
