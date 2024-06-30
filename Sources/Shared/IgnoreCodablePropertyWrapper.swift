//
//  IgnoreCodablePropertyWrapper.swift
//
//
//  Created by Moritz Ellerbrock on 05.07.23.
//

import Foundation

/// A property wrapper for properties of a type that should be "skipped" when the type is encoded or decoded.
@propertyWrapper
public struct IgnoreOptionalCodable<Value> {
    private var value: Value?
    public init(wrappedValue: Value?) {
        value = wrappedValue
    }

    public var wrappedValue: Value? {
        get { value }
        set { value = newValue }
    }
}

extension IgnoreOptionalCodable: Codable {
    public func encode(to _: Encoder) throws {
        // Skip encoding the wrapped value.
    }

    public init(from _: Decoder) throws {
        // The wrapped value is simply initialised to nil when decoded.
        value = nil
    }
}
