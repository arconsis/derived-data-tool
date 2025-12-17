//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 26.01.25.
//

import Foundation

public enum Repository {
    public static func make(with dbConnector: DatabaseConnector) async throws -> ReportModelRepository {
        return ReportModelRepositoryImpl(db: dbConnector.db)
    }

    public static func makeConnector(with databaseUrl: URL) async throws -> DatabaseConnector {
        let dbConnector = DatabaseConnector(fileUrl: databaseUrl)
        try await dbConnector.connect()
        return dbConnector
    }
}
