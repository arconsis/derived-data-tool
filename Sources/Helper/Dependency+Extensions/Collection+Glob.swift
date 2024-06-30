//
//  Collection+Glob.swift
//
//
//  Created by Moritz Ellerbrock on 11.05.23.
//

import Foundation
import GlobPattern
import Shared

public extension Collection where Element == Glob.Pattern {
    func matches(_ string: String) -> Bool {
        for glob in self {
            if glob.match(string) {
                return true
            }
        }
        return false
    }
}

public extension Collection where Element == String {
    func globify() -> [Glob.Pattern] {
        compactMap { text in
            try? .init(text)
        }
    }
}
