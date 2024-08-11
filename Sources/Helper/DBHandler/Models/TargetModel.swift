//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import Foundation
import FluentKit

final class TargetModel: Model {
    typealias FieldKeyStore = ModelDefinition.Target.FieldKeys

    static let schema = ModelDefinition.Target.schema

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeyStore.coverage)
    var coverage: CoverageModel
    
    @Children(for: \.$target)
    var files: [FileModel]

    @Field(key: FieldKeyStore.name)
    var name: String

    init() {}

    init(id: UUID? = nil, coverageId: CoverageModel.IDValue, name: String) {
        self.id = id
        self.$coverage.id = coverageId
        self.name = name
    }
}
