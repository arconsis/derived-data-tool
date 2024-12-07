//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 07.12.24.
//

import Foundation

// MARK: - Query States
enum Start {}          // Initial state
enum SelectState {}    // After SELECT fields
enum FromState {}      // After FROM table
enum WhereState {}     // After WHERE clause
enum InsertState {}    // After INSERT INTO
enum UpdateState {}    // After UPDATE
enum DeleteState {}    // After DELETE FROM

// MARK: - SQLQuery Structure
struct SQLQuery<State> {
    private var queryComponents: [String]

    private init(components: [String] = []) {
        self.queryComponents = components
    }

    // MARK: - State-specific Initializers
    static func start() -> SQLQuery<Start> {
        SQLQuery<Start>()
    }
}

// MARK: - State Transitions for SELECT
extension SQLQuery where State == Start {
    func select(_ fields: String...) -> SQLQuery<SelectState> {
        let components = queryComponents + ["SELECT \(fields.joined(separator: ", "))"]
        return SQLQuery<SelectState>(components: components)
    }
}

extension SQLQuery where State == SelectState {
    func from(_ table: String) -> SQLQuery<FromState> {
        let components = queryComponents + ["FROM \(table)"]
        return SQLQuery<FromState>(components: components)
    }
}

extension SQLQuery where State == FromState {
    func whereCondition(_ condition: String) -> SQLQuery<WhereState> {
        let components = queryComponents + ["WHERE \(condition)"]
        return SQLQuery<WhereState>(components: components)
    }
}

extension SQLQuery where State == WhereState {
    func andCondition(_ condition: String) -> SQLQuery<WhereState> {
        let components = queryComponents + ["AND \(condition)"]
        return SQLQuery<WhereState>(components: components)
    }
}

// MARK: - State Transitions for INSERT
extension SQLQuery where State == Start {
    func insert(into table: String, columns: String...) -> SQLQuery<InsertState> {
        let components = queryComponents + ["INSERT INTO \(table) (\(columns.joined(separator: ", ")))"]
        return SQLQuery<InsertState>(components: components)
    }
}

extension SQLQuery where State == InsertState {
    func values(_ values: Any...) -> SQLQuery<InsertState> {
        let formattedValues = values.map { value -> String in
            if let string = value as? String { return "'\(string)'" }
            return "\(value)"
        }
        let components = queryComponents + ["VALUES (\(formattedValues.joined(separator: ", ")))"]
        return SQLQuery<InsertState>(components: components)
    }
}

// MARK: - State Transitions for UPDATE
extension SQLQuery where State == Start {
    func update(_ table: String) -> SQLQuery<UpdateState> {
        let components = queryComponents + ["UPDATE \(table)"]
        return SQLQuery<UpdateState>(components: components)
    }
}

extension SQLQuery where State == UpdateState {
    func set(_ updates: [String: Any]) -> SQLQuery<UpdateState> {
        let updateComponents = updates.map { "\($0.key) = \(formatValue($0.value))" }.joined(separator: ", ")
        let components = queryComponents + ["SET \(updateComponents)"]
        return SQLQuery<UpdateState>(components: components)
    }

    func whereCondition(_ condition: String) -> SQLQuery<WhereState> {
        let components = queryComponents + ["WHERE \(condition)"]
        return SQLQuery<WhereState>(components: components)
    }
}

// MARK: - State Transitions for DELETE
extension SQLQuery where State == Start {
    func delete(from table: String) -> SQLQuery<DeleteState> {
        let components = queryComponents + ["DELETE FROM \(table)"]
        return SQLQuery<DeleteState>(components: components)
    }
}

extension SQLQuery where State == DeleteState {
    func whereCondition(_ condition: String) -> SQLQuery<WhereState> {
        let components = queryComponents + ["WHERE \(condition)"]
        return SQLQuery<WhereState>(components: components)
    }
}

// MARK: - Finalization in Any State
extension SQLQuery {
    func build() -> String {
        queryComponents.joined(separator: " ") + ";"
    }

    // MARK: - Helper Functions
    private func formatValue(_ value: Any) -> String {
        if let string = value as? String {
            return "'\(string)'"
        }
        return "\(value)"
    }
}
