import FluentKit
import FluentSQLiteDriver
import Foundation

enum Uninitialised {}
enum Setup {}
enum Connected {}
enum Disconnected {}

struct DatabaseConnection<State> {
    private(set) var isConnected: Bool

    private init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}

extension DatabaseConnection where State == Uninitialised {
    init() {
        self.init(isConnected: false)
    }

    func setup() -> DatabaseConnection<Setup> {
        DatabaseConnection<Setup>(isConnected: false)
    }
}

extension DatabaseConnection where State == Setup {
    func connect() -> DatabaseConnection<Connected> {
        DatabaseConnection<Connected>(isConnected: true)
    }
}

extension DatabaseConnection where State == Connected {
    func disconnect() -> DatabaseConnection<Disconnected> {
        DatabaseConnection<Disconnected>(isConnected: false)
    }
}

extension DatabaseConnection where State == Disconnected {
    func reset() -> DatabaseConnection<Setup> {
        DatabaseConnection<Setup>(isConnected: false)
    }
}

/// Define events that trigger transitions.
enum ConnectionEvent {
    case setup
    case connect
    case disconnect
    case reset
}

/// A simplified state machine for our database connection.
enum ConnectionState: Copyable {
    enum SimpleState {
        case uninitialised, setup, connected, disconnected
    }

    enum ConnectionStateError: Error {
        case hasNotReachedState(SimpleState)
        case invalidTransition(from: SimpleState, event: ConnectionEvent)
    }

    case uninitialised(DatabaseConnection<Uninitialised>)
    case setup(DatabaseConnection<Setup>)
    case connected(DatabaseConnection<Connected>)
    case disconnected(DatabaseConnection<Disconnected>)

    init() {
        self = .uninitialised(DatabaseConnection<Uninitialised>())
    }

    /// Returns the current state as a simple enum.
    mutating func state() -> SimpleState {
        switch self {
        case .uninitialised(let connection):
            self = .uninitialised(connection)
            return .uninitialised
        case .setup(let connection):
            self = .setup(connection)
            return .setup
        case .connected(let connection):
            self = .connected(connection)
            return .connected
        case .disconnected(let connection):
            self = .disconnected(connection)
            return .disconnected
        }
    }

    /// Transition to the next state based on the event.
    mutating func transition(event: ConnectionEvent) throws {
        switch (self, event) {
        case (.uninitialised(let connection), .setup):
            self = .setup(connection.setup())
        case (.setup(let connection), .connect):
            self = .connected(connection.connect())
        case (.connected(let connection), .disconnect):
            self = .disconnected(connection.disconnect())
        case (.disconnected(let connection), .reset):
            self = .setup(connection.reset())
        default:
            throw ConnectionStateError.invalidTransition(from: self.state(), event: event)
        }
    }
}
