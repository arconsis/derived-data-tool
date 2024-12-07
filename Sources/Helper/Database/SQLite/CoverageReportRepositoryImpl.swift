//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import Shared
import SQLite3


class CoverageReportRepositoryImpl {
    private let database: SQLiteDatabase

    init(type: DatabaseType) throws {
        database = try SQLiteDatabase(databasePath: type.path)
    }
}


extension CoverageReportRepositoryImpl: CoverageReportRepository {
    func getAllEntries(for application: String?) async throws -> [SQLiteCoverage] {
        fatalError("Not yet implemented")
    }

    func getEntry(for key: DBKey) async throws -> SQLiteCoverage? {
        fatalError("Not yet implemented")
    }

    func addEntry(_ entry: Shared.CoverageReport, for key: DBKey) async throws {
        fatalError("Not yet implemented")
    }

    func replaceEntry(_ entry: Shared.CoverageReport, for key: DBKey) async throws {
        fatalError("Not yet implemented")
    }

    func removeEntry(for key: DBKey) async throws {
        fatalError("Not yet implemented")
    }
}

extension CoverageReportRepositoryImpl {
    enum DatabaseType {
        case inMemory
        case local(String)

        var path: String {
            switch self {
            case .inMemory: return ":memory:"
            case .local(let path): return path
            }
        }
    }
}
