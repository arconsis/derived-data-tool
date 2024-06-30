//
//  Encodable+Dictionary.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public extension Encodable {
    func toDictionary() -> [String: String] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        let anyDict = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: String] }
        return anyDict ?? [:]
    }
}
