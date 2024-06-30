//
//  Tag+optionalID.swift
//
//
//  Created by Moritz Ellerbrock on 08.05.23.
//

import Foundation
import SwiftHtml

extension Tag {
    /// Specifies a optional unique id for an element
    func id(_ value: String?) -> Self {
        if let value {
            attribute("id", value)
        }
        return self
    }
}
