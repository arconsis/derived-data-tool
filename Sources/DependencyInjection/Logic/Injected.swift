//
//  Injected.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation

@propertyWrapper
public struct Injected<T: Sendable>: @unchecked Sendable {
    private let keyPath: WritableKeyPath<InjectedValues, T>

    // Make projectedValue available for Sendable conformance
    public var projectedValue: Injected<T> { self }

    public var wrappedValue: T {
        get { InjectedValues[keyPath] }
        set { InjectedValues[keyPath] = newValue }
    }

    public init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}
