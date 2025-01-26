//
//  DBConnector.swift
//
//
//  Created by Moritz Ellerbrock on 27.03.24.
//

//import FluentKit
//// import Fluent
//import FluentPostgresDriver
//import Foundation
//import Logging
//
//public class DBConnector {
//    private var connectionState: ConnectionState
//
//    init() {
//        connectionState = .init()
//    }
//
//    func setup() {
//        let logger = Logger(label: "Repository")
//        let fluent = Fluent(logger: logger)
//
//        let postgresConfig: DatabaseConfigurationFactory = .postgres(configuration: getPostgresConfig())
//        fluent.databases.use(postgresConfig, as: .psql)
//
//        fluent.r
//    }
//
//    private func getPostgresConfig() -> SQLPostgresConfiguration {
//        .init(hostname: Secrets.dbHost,
//              port: Int(Secrets.dbPort) ?? 5432,
//              username: Secrets.dbUsername,
//              password: Secrets.dbPassword,
//              database: Secrets.dbName,
//              tls: .disable)
//    }
//}
