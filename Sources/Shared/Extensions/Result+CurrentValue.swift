//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 28.04.24.
//

import Foundation

public extension Result where Failure == CCCLIError {
    var value: Success? {
        do {
            return try self.get()
        } catch {
            return nil
        }
    }

    func forcedValue() throws -> Success {
        try self.get()
    }
}

public extension Result {
    func throwError() throws {
        if case .failure(let failure) = self {
            throw failure
        }
    }
}
