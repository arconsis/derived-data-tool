//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import FluentKit

enum CreateCoverageModel {
    typealias FieldKeyStore = ModelDefinition.Coverage.FieldKeys
    static let modelSchema: String = ModelDefinition.Coverage.schema

    static func prepare(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .id()
            .field(FieldKeyStore.report, .uuid, .required, .references(ModelDefinition.Report.schema, "id"))
            .create()
    }

    static func revert(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .delete()
    }
}

