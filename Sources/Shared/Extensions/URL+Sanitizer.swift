//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 25.06.24.
//

import Foundation

public extension URL {
    func sanitize(by gitRootUrl: URL) -> String {
        self.path().replacingOccurrences(of: gitRootUrl.path(), with: "")
    }
}
