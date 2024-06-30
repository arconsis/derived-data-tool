//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import FluentKit

final class FileModel: Model {
    typealias FieldKeyStore = ModelDefinition.File.FieldKeys

    static let schema = ModelDefinition.File.schema

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeyStore.target)
    var target: TargetModel

    @Field(key: FieldKeyStore.name)
    var name: String

    @Field(key: FieldKeyStore.path)
    var path: String

    @Children(for: \.$file)
    var functions: [FunctionModel]

    init() {}

    init(id: UUID? = nil, targetId: TargetModel.IDValue, name: String, path: String) {
        self.id = id
        self.$target.id = targetId
        self.name = name
        self.path = path

    }
}
