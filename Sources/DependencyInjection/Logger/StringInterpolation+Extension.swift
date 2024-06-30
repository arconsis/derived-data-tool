//
//  StringInterpolation+Extension.swift
//
//
//  Created by Moritz Ellerbrock on 30.11.23.
//

import Foundation

// MARK: json

public extension String.StringInterpolation {
    mutating func appendInterpolation(json JSONData: Data) {
        guard
            let JSONObject = try? JSONSerialization.jsonObject(with: JSONData, options: []),
            let jsonData = try? JSONSerialization.data(withJSONObject: JSONObject, options: .prettyPrinted)
        else {
            appendInterpolation("Invalid JSON data")
            return
        }
        appendInterpolation("\n\(String(decoding: jsonData, as: UTF8.self))")
    }
}

// MARK: array

public extension String.StringInterpolation {
    mutating func appendInterpolation(array: [AnyObject]) {
        appendInterpolation("\n[\n")
        for item in array {
            let dictionary = item.dictionaryRepresentation()
            appendInterpolation(dictionary: dictionary)
        }
        appendInterpolation("\n]\n")
    }
}

// MARK: array

public extension String.StringInterpolation {
    mutating func appendInterpolation(dictionary: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
            appendInterpolation("Invalid Dictionary data")
            return
        }
        appendInterpolation(json: jsonData)
    }
}

// MARK: array

public extension String.StringInterpolation {
    mutating func appendInterpolation(error: any Error) {
        appendInterpolation("\(String(reflecting: error))")
    }
}
