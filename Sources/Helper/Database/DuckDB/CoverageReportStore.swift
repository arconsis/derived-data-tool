//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 18.11.24.
//

import Foundation
import Shared

public protocol CoverageReportStore {
    func getAllEntries(for application: String?) async throws -> [DuckDBCoverage]
    func getEntry(for key: DBKey) async throws -> CoverageReport?
    func addEntry(_ entry: CoverageReport, for key: DBKey) async throws
    func replaceEntry(_ entry: CoverageReport, for key: DBKey) async throws
    func removeEntry(for key: DBKey) async throws
}

extension CoverageReportStore {
    public func getAllEntries() async throws -> [DuckDBCoverage] {
        try await getAllEntries(for: nil)
    }

    public static func makeStore(dbType: DuckDBConnection.DBTType) async throws -> CoverageReportStore {
        let dbConnector = try DuckDBConnection(with: dbType)
        let store = try CoverageReportStoreImpl(duckDBConnection: dbConnector)

        try? await store.setup()

        return store
    }
}

