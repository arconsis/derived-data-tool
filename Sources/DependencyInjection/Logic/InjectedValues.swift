//
//  InjectedValues.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation

/// Provides access to injected dependencies.
/// Thread-safe and can be used from any context (MainActor, async, background threads).
public struct InjectedValues: Sendable {
    /// Container for accessing the instance through keypaths.
    /// This is a workaround for the keypath subscript pattern.
    private final class CurrentContainer: @unchecked Sendable {
        var value = InjectedValues()
    }

    private static let currentContainer = CurrentContainer()

    /// This is only used as an accessor to the computed properties within extensions of `InjectedValues`.
    private static var current: InjectedValues {
        get { currentContainer.value }
        set { currentContainer.value = newValue }
    }

    /// A static subscript for updating the `currentValue` of `InjectionKey` instances.
    /// Values are stored in a thread-safe storage container.
    public static subscript<K>(key: K.Type) -> K.Value where K: InjectionKey {
        get { DependencyStorage.shared.get(for: key) }
        set { DependencyStorage.shared.set(for: key, value: newValue) }
    }

    /// A static subscript accessor for updating and references dependencies directly.
    public static subscript<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T {
        get { current[keyPath: keyPath] }
        set { current[keyPath: keyPath] = newValue }
    }
}
