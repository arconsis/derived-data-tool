//
//  Config+Error.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public extension Config {
    enum ConfigError: LocalizedError {
        case settingObjectNotConfigured(String)
    }
}
