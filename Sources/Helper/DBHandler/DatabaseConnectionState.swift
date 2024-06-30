//
//  DatabaseConnectionState.swift
//
//
//  Created by Moritz Ellerbrock on 12.03.24.
//

import FluentKit
import FluentPostgresDriver
import Foundation

enum Uninitialised {}
enum Setup {}
enum Connected {}
enum Disconnected {}

struct DatabaseConnection<State>: ~Copyable {
    private(set) var isConnected: Bool

    private init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}

extension DatabaseConnection where State == Uninitialised {
    init() {
        self.init(isConnected: false)
    }

    consuming func setup() -> DatabaseConnection<Setup> {
        DatabaseConnection<Setup>(isConnected: false)
    }
}

extension DatabaseConnection where State == Setup {
    consuming func connect() -> DatabaseConnection<Connected> {
        DatabaseConnection<Connected>(isConnected: true)
    }
}

extension DatabaseConnection where State == Connected {
    consuming func disconnect() -> DatabaseConnection<Disconnected> {
        DatabaseConnection<Disconnected>(isConnected: false)
    }
}

extension DatabaseConnection where State == Disconnected {
    consuming func reset() -> DatabaseConnection<Setup> {
        DatabaseConnection<Setup>(isConnected: false)
    }
}

enum ConnectionState: ~Copyable {
    enum SimpleState {
        case uninitialised
        case setup
        case connected
        case disconnected
    }

    enum ConnectionStateError: Error {
        case hasNotReachedState(SimpleState)
    }

    case uninitialised(DatabaseConnection<Uninitialised>)
    case setup(DatabaseConnection<Setup>)
    case connected(DatabaseConnection<Connected>)
    case disconnected(DatabaseConnection<Disconnected>)

    init() {
        self = .uninitialised(DatabaseConnection<Uninitialised>())
    }

    mutating func isConnected() -> Bool {
        var isConnected: Bool
        switch consume self {
        case let .uninitialised(connection):
            isConnected = connection.isConnected
            self = .uninitialised(connection)
        case let .setup(connection):
            isConnected = connection.isConnected
            self = .setup(connection)
        case let .connected(connection):
            isConnected = connection.isConnected
            self = .connected(connection)
        case let .disconnected(connection):
            isConnected = connection.isConnected
            self = .disconnected(connection)
        }

        return isConnected
    }

    mutating func state() -> SimpleState {
        switch consume self {
        case let .uninitialised(connection):
            self = .uninitialised(connection)
            return .uninitialised
        case let .setup(connection):
            self = .setup(connection)
            return .setup
        case let .connected(connection):
            self = .connected(connection)
            return .connected
        case let .disconnected(connection):
            self = .disconnected(connection)
            return .disconnected
        }
    }
    
    /// Check if the given state has been reached
    /// - Parameter state: state that should be checked
    mutating func reached(state: SimpleState) throws {
        var hasReachedState = false
        switch consume self {
        case let .uninitialised(connection):
            if state == .uninitialised {
                hasReachedState = true
            }
            hasReachedState = connection.isConnected
            self = .uninitialised(connection)
        case let .setup(connection):
            if state == .setup {
                hasReachedState = true
            }
            hasReachedState = connection.isConnected
            self = .setup(connection)
        case let .connected(connection):
            if state == .connected {
                hasReachedState = true
            }
            hasReachedState = connection.isConnected
            self = .connected(connection)
        case let .disconnected(connection):
            if state == .disconnected {
                hasReachedState = true
            }
            hasReachedState = connection.isConnected
            self = .disconnected(connection)
        }

        guard hasReachedState else { throw ConnectionStateError.hasNotReachedState(state) }
    }
    
    /// Check if the given state is ready to be processed
    /// - Parameter state: state that should be reached
    mutating func ready(for state: SimpleState) throws {
        var hasReachedState = false
        switch consume self {
        case let .uninitialised(connection):
            if state == .setup {
                hasReachedState = true
            }
            self = .uninitialised(connection)
        case let .setup(connection):
            if state == .connected {
                hasReachedState = true
            }
            self = .setup(connection)
        case let .connected(connection):
            if state == .disconnected {
                hasReachedState = true
            }
            self = .connected(connection)
        case let .disconnected(connection):
            self = .disconnected(connection)
        }

        guard hasReachedState else { throw ConnectionStateError.hasNotReachedState(state) }
    }

    mutating func stepCompleted() {
        switch consume self {
        case let .uninitialised(connection):
            self = .setup(connection.setup())
        case let .setup(connection):
            self = .connected(connection.connect())
        case let .connected(connection):
            self = .disconnected(connection.disconnect())
        case let .disconnected(connection):
            self = .setup(connection.reset())
        }
    }

    mutating func reset() {
        self = .uninitialised(DatabaseConnection<Uninitialised>())
    }
}
