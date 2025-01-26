//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 29.04.24.
//

import FluentKit

//enum CreateFileModel {
//    typealias FieldKeyStore = ModelDefinition.File.FieldKeys
//    static let modelSchema: String = ModelDefinition.File.schema
//
//    static func prepare(on database: any Database) async throws {
//        try await database.schema(modelSchema)
//            .id()
//            .field(FieldKeyStore.name, .string, .required)
//            .field(FieldKeyStore.path, .string, .required)
//            .field(FieldKeyStore.target, .uuid, .required, .references(ModelDefinition.Target.schema, "id"))
//            .create()
//    }
//
//    static func revert(on database: any Database) async throws {
//        try await database.schema(modelSchema)
//            .delete()
//    }
//}
