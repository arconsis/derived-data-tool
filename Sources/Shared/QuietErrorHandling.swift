//
//  QuietErrorHandling.swift
//
//
//  Created by Moritz Ellerbrock on 10.03.24.
//

import Foundation

public protocol QuietErrorHandling {}

public extension QuietErrorHandling {
    func handle(error: any Error, quietly isQuietly: Bool, helpMessage: String) throws {
        if !isQuietly {
            if let errorable = error as? any Errorable {
                handle(error: errorable, helpMessage: helpMessage)
            }

            throw error
        }
    }

    private func handle(error: any Errorable, helpMessage: String) {
        if error.printsHelp {
            print(helpMessage)
        }
    }
}
