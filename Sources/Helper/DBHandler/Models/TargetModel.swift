//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import Foundation
import FluentKit

public final class TargetModel: Model {
    typealias FieldKeyStore = ModelDefinition.Target.FieldKeys

    public static let schema = ModelDefinition.Target.schema

    @ID(key: .id)
    public var id: UUID?

    @Field(key: FieldKeyStore.executableLines)
    public var executableLines: Int

    @Field(key: FieldKeyStore.coveredLines)
    public var coveredLines: Int

    @Parent(key: FieldKeyStore.coverage)
    public var coverage: CoverageModel

    @Field(key: FieldKeyStore.name)
    public var name: String

    public init() {}

    init(id: UUID? = nil, name: String, executableLines: Int, coveredLines: Int, coverageId: CoverageModel.IDValue) {
        self.id = id
        self.name = name
        self.executableLines = executableLines
        self.coveredLines = coveredLines
        self.$coverage.id = coverageId
    }
}

extension TargetModel: @unchecked Sendable {}
