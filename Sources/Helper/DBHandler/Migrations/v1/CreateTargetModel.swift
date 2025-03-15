//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 29.04.24.
//

import FluentKit

enum CreateTargetModel {
    typealias FieldKeyStore = ModelDefinition.Target.FieldKeys
    static let modelSchema: String = ModelDefinition.Target.schema

    static func prepare(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .id()
            .field(FieldKeyStore.name, .string, .required)
            .field(FieldKeyStore.executableLines, .int, .required)
            .field(FieldKeyStore.coveredLines, .int, .required)
            .field(FieldKeyStore.coverage, .uuid, .required, .references(ModelDefinition.Coverage.schema, "id"))
            .create()
    }

    static func revert(on database: any Database) async throws {
        try await database.schema(modelSchema)
            .delete()
    }
}
