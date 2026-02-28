//
//  Config+Thresholds.swift
//
//
//  Created by Moritz Ellerbrock on 28.02.26.
//

import Foundation

public extension Config {
    struct Thresholds: Codable, CustomStringConvertible {
        public let global: Double?
        public let targets: [String: Double]?

        public var description: String {
            return """
            Global: \(global?.description ?? "N/A")
            Targets: \(targets?.description ?? "N/A")
            """
        }
    }
}
