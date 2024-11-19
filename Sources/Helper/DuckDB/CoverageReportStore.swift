//
//  File.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 18.11.24.
//

import Foundation
import DuckDB
import Shared
import TabularData

public struct DBKey {
    let value: String
    let application: String
    init (date: Foundation.Date, application: String) {
        value = DateFormat.yearMontDay.string(from: date)
        self.application = application
    }
}

public protocol CoverageReportStore {
    func getAllEntries(for application: String) async throws -> [CoverageReport]
    func getEntry(for key: DBKey) async throws -> CoverageReport?
    func addEntry(_ entry: CoverageReport, for key: DBKey) async throws
    func updateEntry(_ entry: CoverageReport, for key: DBKey) async throws
    func removeEntry(for key: DBKey) async throws

    static func makeKey(from date: Foundation.Date, application: String) -> DBKey
    static func makeStore(dbType: DuckDBConnection.DBTType) async throws -> CoverageReportStore
}

extension CoverageReportStore {
    public static func makeKey(from date: Foundation.Date, application: String) -> DBKey {
        DBKey(date: date, application: application)
    }

    public static func makeStore(dbType: DuckDBConnection.DBTType) async throws -> CoverageReportStore {
        let dbConnector = try DuckDBConnection(with: dbType)
        let store = try CoverageReportStoreImpl(duckDBConnection: dbConnector)

        try await store.setup()

        return store
    }
}

public final class CoverageReportStoreImpl {

    let duckDBConnection: DuckDBConnection

    init(duckDBConnection: DuckDBConnection) throws {
        self.duckDBConnection = duckDBConnection
    }

    func connection() async -> Connection {
        duckDBConnection.connection
    }

    func setup() async throws {
        do {
            _ = try duckDBConnection.connection.query(
            """
                CREATE TABLE coverage_reports (
                application VARCHAR(255) NOT NULL,
                date VARCHAR(15) NOT NULL UNIQUE,
                coverage JSON NOT NULL,
                PRIMARY KEY (date)
                );
            """
            )
        } catch {
            print(error)
            throw error
        }
    }
}

extension CoverageReportStoreImpl: CoverageReportStore {
    public func getAllEntries(for application: String) async throws -> [Shared.CoverageReport] {
        let result = try await connection().query("""
            SELECT * FROM coverage_reports
            GROUP BY date
            ORDER BY date;
        """)

        print(result)

        return []
    }

    public func getEntry(for key: DBKey) async throws -> Shared.CoverageReport? {
        let result = try await connection().query("""
        SELECT coverage
        FROM coverage_reports
        WHERE date = \(key.value);
        """)

        print(result)
        return nil
    }

    public func addEntry(_ entry: Shared.CoverageReport, for key: DBKey) async throws {
        do {
            let result = try await connection().query(
                "INSERT INTO coverage_reports (application, date, coverage) VALUES (\(key.application), \(key.value), \(encodeToJSONString(entry));")

            print(result)
            print("DONE")
        } catch {
            print(error)
            print(encodeToJSONString(entry))
            throw error
        }
    }

    public func updateEntry(_ entry: Shared.CoverageReport, for key: DBKey) async throws {
        let result = try await connection().query("""
        INSERT INTO coverage_reports (application, date, coverage)
        VALUES (\(key.application), \(key.value), \(entry)
        ON DUPLICATE KEY UPDATE
        coverage = VALUES(\(entry));
        """)

        print(result)
        print("DONE")
    }

    public func removeEntry(for key: DBKey) async throws {
        let result = try await connection().query("""
        DELETE FROM coverage_reports 
        WHERE date = \(key.value);

        """)

        print(result)
        print("DONE")
    }

    private func encodeToJSONString(_ value: Codable) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return "Encoding error: \(error.localizedDescription)"
        }
    }


}
