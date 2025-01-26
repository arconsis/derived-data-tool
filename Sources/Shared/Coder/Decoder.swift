//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 26.01.25.
//

import Foundation

public enum SingleDecoder {
    public static var shared: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
