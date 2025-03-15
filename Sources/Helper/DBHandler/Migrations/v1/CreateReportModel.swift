//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 29.04.24.
//

import FluentKit

enum CreateReportModel {
    typealias FieldKeyStore = ModelDefinition.Report.FieldKeys
    static let modelSchema: String = ModelDefinition.Report.schema

    static func prepare(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .id()
            .field(FieldKeyStore.type, .string, .required)
            .field(FieldKeyStore.url, .string, .required)
            .field(FieldKeyStore.date, .date, .required)
            .field(FieldKeyStore.application, .string, .required)
            .unique(on: FieldKeyStore.date)
            .create()
    }

    static func revert(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .delete()
    }
}
