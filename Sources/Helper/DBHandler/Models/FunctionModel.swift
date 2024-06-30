//
//  File 2.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import FluentKit

final class FunctionModel: Model {
    typealias FieldKeyStore = ModelDefinition.Function.FieldKeys

    static let schema = ModelDefinition.Function.schema

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeyStore.file)
    var file: FileModel

    @Field(key: FieldKeyStore.name)
    var name: String

    @Field(key: FieldKeyStore.lineNumber)
    var lineNumber: Int

    @Field(key: FieldKeyStore.executableLines)
    var executableLines: Int

    @Field(key: FieldKeyStore.executionCount)
    var executionCount: Int

    @Field(key: FieldKeyStore.coveredLines)
    var coveredLines: Int

    init() {}

    init(id: UUID? = nil,
        fileId: FileModel.IDValue,
        name: String,
        lineNumber: Int,
        executableLines: Int,
        executionCount: Int,
        coveredLines: Int) {
        self.id = id
        self.$file.id = fileId
        self.name = name
        self.lineNumber = lineNumber
        self.executableLines = executableLines
        self.executionCount = executionCount
        self.coveredLines = coveredLines
    }
}
