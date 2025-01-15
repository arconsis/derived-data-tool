//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import DuckDB
//import Shared

public enum StorageFactory {
    public static func makeStore(dbType: DuckDBConnection.DBTType) async throws -> CoverageReportStore {
        try await CoverageReportStoreImpl.makeStore(dbType: dbType)
    }

    public static func makeKey(from date: Foundation.Date, application: String) -> DBKey {
        DBKey(date: date, application: application)
    }
}
