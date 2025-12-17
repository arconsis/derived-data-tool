//
//  InjectionKey.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation

public protocol InjectionKey: Sendable {
    /// The associated type representing the type of the dependency injection key's value.
    associatedtype Value: Sendable

    /// The default value for the dependency injection key.
    /// This is now used only for providing the initial default value.
    /// Actual storage is managed by the thread-safe DependencyStorage.
    static var currentValue: Self.Value { get }
}
