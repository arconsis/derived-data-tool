//
//  DatabaseConnector.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import FluentPostgresDriver
import FluentSQLiteDriver
import Foundation
import HummingbirdFluent

public class DatabaseConnector {
    struct DatabaseCredentials {
        let hostname: String
        let port: Int
        let username: String
        let password: String?
        let database: String?

        init(hostname: String,
             port: Int = 5432,
             username: String,
             password: String? = nil,
             database: String? = nil) {
            self.hostname = hostname
            self.port = port
            self.username = username
            self.password = password
            self.database = database
        }
    }

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

    init(credentials: DatabaseCredentials? = nil) {
        connectionState = .init()
        fluent = Self.createDatabase(credentials: credentials)
//        connectionState.stepCompleted()
    }

    deinit {

    }

    static func createDatabase(credentials: DatabaseCredentials? = nil) -> Fluent {
        let logger = Logger(label: "Repository")
        let fluent = Fluent(logger: logger)

        if let credentials {
            let config = Self.getDBConfig(credentials: credentials)
            let postgresConfig: DatabaseConfigurationFactory = .postgres(configuration: config)
            fluent.databases.use(postgresConfig, as: .psql)
        } else {
            fluent.databases.use(.sqlite(.memory), as: .sqlite)
        }

        return fluent
    }


    private static func getDBConfig(credentials: DatabaseCredentials) -> SQLPostgresConfiguration {
        .init(hostname: credentials.hostname,
              port: credentials.port,
              username: credentials.username,
              password: credentials.password,
              database: credentials.database,
              tls: .disable)
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
//        migrations.append(CreateReportModel())
//        migrations.append(CreateCoverageModel())
//        migrations.append(CreateTargetModel())
//        migrations.append(CreateFileModel())
//        migrations.append(CreateFunctionModel())
//        migrations.append(CreateFileInfoModel())
        await fluent.migrations.add(migrations)
    }

    private func send(_: PostgresRequest) {}

    private static func connect(to postgres: PostgresConnectionSource, on eventLoop: EventLoop) async throws -> PostgresConnection {
        try await withCheckedThrowingContinuation { continuation in
            postgres.makeConnection(logger: Logger(label: "postgres"), on: eventLoop).whenComplete { continuation.resume(with: $0) }
        }
    }

//    private func makeMigrations() -> Migrations {
//        let migrations: Migrations = .init()
//        migrations.add(CreateCoverageModel())
//        if let migration {
//            migrations.add(migration)
//        }
//        return migrations
//    }
}

// import Foundation
//
//// MARK: - Report
// struct Report: Codable {
//    let date: Date
//    let fileInfo: FileInfo
//    let coverage: Coverage
// }
//
//// MARK: - Coverage
// struct Coverage: Codable {
//    let targets: [Target]
// }
//
//// MARK: - Target
// struct Target: Codable {
//    let files: [File]
//    let name: String
// }
//
//// MARK: - File
// struct File: Codable {
//    let name, path: String
//    let functions: [Function]
// }
//
//// MARK: - Function
// struct Function: Codable {
//    let name: String
//    let lineNumber, executableLines, executionCount, coveredLines: Int
// }
//
//// MARK: - FileInfo
// struct FileInfo: Codable {
//    let type, url: String
//    let date: Date
//    let application: String
// }
