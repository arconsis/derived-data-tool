//
//  DatabaseConnector_OLD.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

// import Foundation
// import PostgresKit

/*
 Steps to do:

 */

// public class DatabaseConnector {
//    let eventLoopGroup: MultiThreadedEventLoopGroup
//    let configuration: SQLPostgresConfiguration
//    let postgres: PostgresConnectionSource
//    private var db: PostgresConnection?
//
//    init(hostname: String,
//         port: Int = 5432,
//         username: String,
//         password: String? = nil,
//         database: String? = nil,
//         tls: PostgresConnection.Configuration.TLS) {
//
//        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        configuration = SQLPostgresConfiguration(hostname: hostname, port: port, username: username, password: password, database: database, tls: tls)
//        postgres = PostgresConnectionSource(sqlConfiguration: configuration)
//    }
//
//    func connect() async throws {
//        db = try await Self.connect(to: postgres, on: eventLoopGroup.any())
//    }
//
//    func disconnect() async throws {
//        try await eventLoopGroup.shutdownGracefully()
//    }
//
//    func modify() async throws {
////        db.
////        db.withConnection { conn in
////            conn.simpleQuery("INSERT INTO your_table (column1, column2) VALUES ($1, $2)", ["value1", "value2"])
////        }.wait() // Be careful with wait() in real applications
//
//    }
//
//    private func send(_ request: PostgresRequest) {
//
//    }
//
//    private static func connect(to postgres: PostgresConnectionSource, on eventLoop: EventLoop) async throws -> PostgresConnection {
//        try await withCheckedThrowingContinuation { continuation in
//            postgres.makeConnection(logger: Logger(label: "postgres"), on: eventLoop).whenComplete { continuation.resume(with: $0) }
//        }
//    }
// }
//
//
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
