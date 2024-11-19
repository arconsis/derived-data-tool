//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 19.11.24.
//

import Foundation

public enum SingleDecoder {
    public static var shared: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
