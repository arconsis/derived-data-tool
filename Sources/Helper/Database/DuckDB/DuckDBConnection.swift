//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 07.11.24.
//

import Foundation
import DuckDB

public enum DuckDBConnectionError: Error {
    case initializationFailed(String)
}

public actor DuckDBConnection {
    public enum DBTType {
        case inMemory
        case local(url: URL)
    }

    private let type: DBTType
    let database: Database
    let connection: Connection


    public init(with dbType: DBTType) throws {
        self.type = dbType
        self.database = try Self.makeDatabase(type: self.type)
        self.connection = try database.connect()
    }

    private static func makeDatabase(type: DBTType) throws -> Database {
        do {
            switch type {
            case .inMemory:
                return try Database.init(store: .inMemory)
            case let .local(url):
                return try Database.init(store: .file(at: url))
            }
        } catch {
            throw DuckDBConnectionError.initializationFailed("Database creation failed with: \(error)")
        }
    }
}
