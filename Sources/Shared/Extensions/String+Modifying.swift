//
//  File 2.swift
//  
//
//  Created by Moritz Ellerbrock on 28.04.24.
//

import Foundation

public extension String {
    func nonOptionalSplitting(at separator: String) -> [String] {
        self.components(separatedBy: separator).compactMap { $0.isEmpty ? nil : $0 }
    }
}
