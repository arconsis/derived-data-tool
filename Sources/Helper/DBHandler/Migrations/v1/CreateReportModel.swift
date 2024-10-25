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
            .field(FieldKeyStore.date, .string, .required)
            .field(FieldKeyStore.application, .string, .required)
            .field(FieldKeyStore.coverage, .custom("JSONB"), .required)
            .create()
    }

    static func revert(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .delete()
    }
}
