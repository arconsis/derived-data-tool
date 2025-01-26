//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 26.01.25.
//

import Foundation

public enum SingleEncoder {
    public static var shared: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
