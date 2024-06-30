//
//  Config+Excluded.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public extension Config {
    struct Excluded: Codable, CustomStringConvertible {
        public let targets: [String]?
        public let files: [String]?
        public let functions: [String]?

        public var description: String {
            return """
            Targets: \(targets?.description ?? "N/A")
            Files: \(files?.description ?? "N/A")
            Functions: \(functions?.description ?? "N/A")
            """
        }
    }
}
