//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 29.04.24.
//

import FluentKit

//enum CreateFunctionModel {
//    typealias FieldKeyStore = ModelDefinition.Function.FieldKeys
//    static let modelSchema: String = ModelDefinition.Function.schema
//
//    static func prepare(on database: any Database) async throws {
//        try await database.schema(modelSchema)
//            .id()
//            .field(FieldKeyStore.name, .string, .required)
//            .field(FieldKeyStore.lineNumber, .int64, .required)
//            .field(FieldKeyStore.executableLines, .int64, .required)
//            .field(FieldKeyStore.executionCount, .int64, .required)
//            .field(FieldKeyStore.coveredLines, .int64, .required)
//            .field(FieldKeyStore.file, .uuid, .required, .references(ModelDefinition.File.schema, "id"))
//            .create()
//    }
//
//    static func revert(on database: any Database) async throws {
//        try await database.schema(modelSchema)
//            .delete()
//    }
//}
