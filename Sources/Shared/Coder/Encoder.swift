//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 19.11.24.
//

import Foundation

public enum SingleEncoder {
    public static var shared: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
