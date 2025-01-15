//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 19.11.24.
//

import Foundation

// MARK: - SQL DSL Components

struct Query {
    struct Field {
        let name: String
        let type: String? // For table creation

        init(name: String, type: String? = nil) {
            self.name = name
            self.type = type
        }
    }

    struct Table {
        let name: String
    }

    struct Condition {
        let statement: String
    }

    private var components: [String] = []

    // MARK: - SELECT Query Methods
    func select(_ fields: Field..., as castType: String? = nil) -> Query {
        var newQuery = self
        let fieldsString = fields.map { $0.name }.joined(separator: ", ")
        var query = "SELECT \(fieldsString)"
        if let castType {
            query.append(" AS \(castType)")
        }
        newQuery.components.append(query)
        return newQuery
    }

    func from(_ table: Table) -> Query {
        var newQuery = self
        newQuery.components.append("FROM \(table.name)")
        return newQuery
    }

    func whereCondition(_ condition: Condition) -> Query {
        var newQuery = self
        if let whereIndex = newQuery.components.firstIndex(where: { $0.starts(with: "WHERE") }) {
            newQuery.components[whereIndex].append(" AND \(condition.statement)")
        } else {
            newQuery.components.append("WHERE \(condition.statement)")
        }
        return newQuery
    }

    // MARK: - CREATE TABLE
    func create(table: Table, with fields: Field..., constraints: [String] = []) -> Self {
        var newQuery = self
        let fieldsDefinition = fields.map { "\($0.name) \($0.type ?? "TEXT")" }.joined(separator: ", ")
        let constraintsString = constraints.joined(separator: ", ")
        newQuery.components = [
            "CREATE TABLE \(table.name) (\(fieldsDefinition)\(constraintsString.isEmpty ? "" : ", \(constraintsString)"))"
        ]
        return newQuery
    }

    // MARK: - INSERT INTO
    func insert(into table: Table, values: [String: Any]) -> Self {
        var newQuery = self
        let columns = values.keys.joined(separator: ", ")
        let valuesString = values.values.map { formatValue($0) }.joined(separator: ", ")
        newQuery.components = ["INSERT INTO \(table.name) (\(columns)) VALUES (\(valuesString))"]
        return newQuery
    }

    // MARK: - UPDATE
    func update(_ table: Table, set values: [String: Any]) -> Self {
        var newQuery = self
        let updateString = values.map { "\($0.key) = \(formatValue($0.value))" }.joined(separator: ", ")
        newQuery.components = ["UPDATE \(table.name) SET \(updateString)"]
        return newQuery
    }

    // MARK: - DELETE
    func delete(from table: Table) -> Self {
        var newQuery = self
        newQuery.components = ["DELETE FROM \(table.name)"]
        return newQuery
    }

    // MARK: - Get All
    func getAll(from table: Table) -> Self {
        var newQuery = self
        newQuery.components = ["SELECT * FROM \(table.name)"]
        return newQuery
    }

    // Builds the final SQL string
    func build() -> String {
        components.joined(separator: " ") + ";"
    }

    // MARK: - Helper Methods
    private func formatValue(_ value: Any) -> String {
        if let string = value as? String {
            return "'\(string)'"
        } else {
            return "\(value)"
        }
    }
}

// MARK: - Convenience Builders

extension Query.Field {
    static func named(_ name: String, type: String? = nil) -> Query.Field {
        Query.Field(name: name, type: type)
    }
}

extension Query.Table {
    static func named(_ name: String) -> Query.Table {
        Query.Table(name: name)
    }
}

extension Query.Condition {
    static func equals(_ field: Query.Field, _ value: Any) -> Query.Condition {
        Query.Condition(statement: "\(field.name) = \(formatValue(value))")
    }

    static func greaterThan(_ field: Query.Field, _ value: Int) -> Query.Condition {
        Query.Condition(statement: "\(field.name) > \(value)")
    }

    private static func formatValue(_ value: Any) -> String {
        if let string = value as? String {
            return "'\(string)'"
        } else {
            return "\(value)"
        }
    }
}

// MARK: - Database Schema

extension Query {
    static func createCoverageReportsTable() -> Query {
        Query()
            .create(
                table: .named("CoverageReports"),
                with: .named("id", type: "INTEGER NOT NULL PRIMARY KEY"),
                      .named("date", type: "VARCHAR(500) NOT NULL UNIQUE")
            )
    }

    static func createTargetsTable() -> Query {
        Query()
            .create(
                table: .named("Targets"),
                with: .named("id", type: "INTEGER NOT NULL PRIMARY KEY"),
                      .named("coverage_report_id", type: "INTEGER NOT NULL"),
                      .named("name", type: "VARCHAR(500) NOT NULL"),
                      .named("executable_lines", type: "INTEGER NOT NULL"),
                      .named("covered_lines", type: "INTEGER NOT NULL"),
                constraints: ["FOREIGN KEY (coverage_report_id) REFERENCES CoverageReports (id)"]
            )
    }
}
