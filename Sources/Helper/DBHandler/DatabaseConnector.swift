//
//  DatabaseConnector.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import FluentSQLiteDriver
import Foundation
import HummingbirdFluent

public class DatabaseConnector {

    private let fluent: Fluent
    private var optionalDatabase: Database?
    var db: Database {
        guard let optionalDatabase else {
            preconditionFailure("Setup process did not setup correctly")
        }
        return optionalDatabase
    }
    private var connectionState: ConnectionState
    private var migration: Migration?

    init(fileUrl: URL? = nil) {
        connectionState = .init()
        fluent = Self.createDatabase(fileUrl: fileUrl)
        try? connectionState.transition(event: .setup)
    }

    private static func createDatabase(fileUrl: URL? = nil) -> Fluent {
        let logger = Logger(label: "Repository")
        let fluent = Fluent(logger: logger)

        if let filePath = fileUrl?.path() {
            fluent.databases.use(.sqlite(.file(filePath)), as: .sqlite)
        } else {
            logger.warning("⚠ Using in memory SQLite database")
            fluent.databases.use(.sqlite(.memory), as: .sqlite)
        }

        return fluent
    }

    func connect() async throws {
        try await setup()
    }

    private func setup() async throws {
        await addMigrations()
        try await fluent.migrate()
        optionalDatabase = fluent.db()
        try connectionState.transition(event: .connect)
    }

    public func disconnect() async throws {
        try await fluent.shutdown()
        try connectionState.transition(event: .disconnect)
    }
}

private extension DatabaseConnector {
    func addMigrations() async {
        var migrations: [any Migration] = .init()
        migrations.append(InitialMigration())
        await fluent.migrations.add(migrations)
    }
}
