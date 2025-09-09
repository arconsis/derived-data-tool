//
//  MatchPatternConfig.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 08.09.25.
//


public struct MatchPatternConfig {
    public let targets: [String]
    public let files: [String]
    public let functions: [String]

    public init(targets: [String], files: [String], functions: [String]) {
        self.targets = targets
        self.files = files
        self.functions = functions
    }
}