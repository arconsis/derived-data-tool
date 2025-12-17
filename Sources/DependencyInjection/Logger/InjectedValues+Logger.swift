//
//  InjectedValues+Logger.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation

public extension InjectedValues {
    var logger: Loggerable {
        get { Self[LoggerKey.self] }
        set { Self[LoggerKey.self] = newValue }
    }
}

private struct LoggerKey: InjectionKey {
    static var currentValue: Loggerable {
        MyLogger()
    }
}
