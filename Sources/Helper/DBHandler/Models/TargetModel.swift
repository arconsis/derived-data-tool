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

    @Field(key: FieldKeyStore.executableLines)
    var executableLines: Int
    
    @Field(key: FieldKeyStore.coveredLines)
    var coveredLines: Int

    @Parent(key: FieldKeyStore.coverage)
    var coverage: CoverageModel

    @Field(key: FieldKeyStore.name)
    var name: String

    init() {}

    init(id: UUID? = nil, name: String, executableLines: Int, coveredLines: Int, coverageId: CoverageModel.IDValue) {
        self.id = id
        self.name = name
        self.executableLines = executableLines
        self.coveredLines = coveredLines
        self.$coverage.id = coverageId
    }
}
