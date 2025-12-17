//
//  DependencyStorage.swift
//
//
//  Created for Swift 6 concurrency support
//

import Foundation

/// Thread-safe storage for dependency injection values
final class DependencyStorage: @unchecked Sendable {
    static let shared = DependencyStorage()

    private let lock = NSLock()
    private var storage: [ObjectIdentifier: Any] = [:]

    private init() {}

    func get<K: InjectionKey>(for key: K.Type) -> K.Value {
        lock.lock()
        defer { lock.unlock() }

        let id = ObjectIdentifier(key)
        if let value = storage[id] as? K.Value {
            return value
        }

        // If not in storage, get the default value
        let defaultValue = key.currentValue
        storage[id] = defaultValue
        return defaultValue
    }

    func set<K: InjectionKey>(for key: K.Type, value: K.Value) {
        lock.lock()
        defer { lock.unlock() }

        let id = ObjectIdentifier(key)
        storage[id] = value
    }
}
