//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import DuckDB
import Shared
import TabularData

public final class CoverageReportStoreImpl {
    private let table: Query.Table = .named("coverage_reports")
    private let applicationField: Query.Field = .named("application", type: "VARCHAR(255) NOT NULL")
    private let dateField: Query.Field = .named("date", type: "VARCHAR(16) NOT NULL UNIQUE PRIMARY KEY")
    private let coverageField: Query.Field = .named("coverage", type: "JSON NOT NULL")

    let duckDBConnection: DuckDBConnection

    init(duckDBConnection: DuckDBConnection) throws {
        self.duckDBConnection = duckDBConnection
    }

    func connection() async -> Connection {
        duckDBConnection.connection
    }

    func setup() async throws {
        let query = Query()
            .create(table: table,
                    with: applicationField,
                    dateField,
                    coverageField)
            .build()

        _ = try duckDBConnection.connection.query(query)
    }
}

extension CoverageReportStoreImpl: CoverageReportStore {
    public func getAllEntries(for application: String?) async throws -> [DuckDBCoverage] {
        var queryBuilder = Query()
            .getAll(from: table)

        if let application, !application.isEmpty {
            queryBuilder = queryBuilder.whereCondition(.equals(applicationField, application))
        }

        let query = queryBuilder.build()
        let result = try await connection().query(query)

        let applicationColumn = result[0].cast(to: String.self)
        let dateColumn = result[1].cast(to: String.self)
        let coverageColumn = result[2].cast(to: String.self)

        let dataFrame = DataFrame(columns: [
            TabularData.Column(applicationColumn).eraseToAnyColumn(),
            TabularData.Column(dateColumn).eraseToAnyColumn(),
            TabularData.Column(coverageColumn).eraseToAnyColumn(),
        ])

        var dCoverage: [DuckDBCoverage] = []
        for row in dataFrame.rows {
            guard
                let application = row[applicationField.name, String.self],
                let dateString = row[dateField.name, String.self],
                let date = DateFormat.yearMontDay.date(from: dateString),
                let json = row[coverageField.name, String.self],
                let coverage = decode(json)
            else {
                continue
            }

            dCoverage.append(.init(application: application, date: date, coverage: coverage))

        }

        return dCoverage
    }

    public func getEntry(for key: DBKey) async throws -> Shared.CoverageReport? {
        let query = Query()
            .select(coverageField)
            .from(table)
            .whereCondition(.equals(dateField, key.value))
            .build()
        let result = try await connection().query(query)
        return decode(result.first)
    }

    public func addEntry(_ entry: Shared.CoverageReport, for key: DBKey) async throws {
        let query = Query()
            .insert(into: table, values: [applicationField.name: key.application,
                                          dateField.name: key.value,
                                          coverageField.name: encode(entry)]).build()

        _ = try await connection().query(query)
    }

    public func replaceEntry(_ entry: Shared.CoverageReport, for key: DBKey) async throws {
        try await removeEntry(for: key)
        try await addEntry(entry, for: key)
    }

    public func removeEntry(for key: DBKey) async throws {
        let query = Query()
            .delete(from: table)
            .whereCondition(.equals(dateField, key.value))
            .build()

        _ = try await connection().query(query)
    }

    private func encode(_ value: Codable) -> String {
        do {
            let data = try SingleEncoder.shared.encode(value)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return "Encoding error: \(error.localizedDescription)"
        }
    }

    private func decode(_ resultElement: ResultSet.Element?) -> Shared.CoverageReport? {
        guard let resultElement else { return nil }
        let coverageColumn = resultElement.cast(to: String.self)
        let dataFrame = DataFrame(columns: [
            TabularData.Column(coverageColumn).eraseToAnyColumn()
        ])

        guard
            let firstObject = dataFrame.columns.first,
            let object = firstObject.assumingType(String.self).first,
            let jsonString = object
        else {
            return nil
        }

        return decode(jsonString)
    }

    private func decode(_ json: String) -> Shared.CoverageReport? {
        do {
            guard let data = json.data(using: .utf8) else { return nil }
            return try SingleDecoder.shared.decode(Shared.CoverageReport.self, from: data)
        } catch {
            return nil
        }
    }
}
