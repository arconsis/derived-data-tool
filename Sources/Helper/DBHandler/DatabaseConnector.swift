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
//        connectionState.stepCompleted()
    }

    deinit {

    }

    static func createDatabase(fileUrl: URL? = nil) -> Fluent {
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
//        print(connectionState.state())
//        try connectionState.reached(state: .setup)
//        connectionState.stepCompleted()
//        print(connectionState.state())
//        try connectionState.ready(for: .connected)
        //        db = try await Self.connect(to: postgres, on: eventLoopGroup.any())
    }

    private func setup() async throws {
//        try connectionState.ready(for: .setup)
        await addMigrations()
        try await fluent.revert()
        try await fluent.migrate()
        optionalDatabase = fluent.db()

//        try connectionState.reached(state: .connected)
    }

    func disconnect() async throws {
        try await fluent.shutdown()
//        try connectionState.ready(for: .disconnected)

    }

    func modify() async throws {
//        try connectionState.reached(state: .connected)

    }
}

private extension DatabaseConnector {
    func addMigrations() async {
        var migrations: [any Migration] = .init()
        migrations.append(InitialMigration())
        await fluent.migrations.add(migrations)
    }
}
