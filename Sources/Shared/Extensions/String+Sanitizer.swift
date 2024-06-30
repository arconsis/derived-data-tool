//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 25.06.24.
//

import Foundation

public extension String {
    func sanitize(by gitRootPath: String) -> String {
        self.replacingOccurrences(of: gitRootPath, with: "")
    }
}
