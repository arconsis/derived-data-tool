//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import Foundation
import FluentKit

public final class CoverageModel: Model {
    typealias FieldKeyStore = ModelDefinition.Coverage.FieldKeys

    public static let schema = ModelDefinition.Coverage.schema

    @ID(key: .id)
    public var id: UUID?

    @Parent(key: FieldKeyStore.report)
    public var report: ReportModel

    @Children(for: \.$coverage)
    public var targets: [TargetModel]

    public init() {}

    init(id: UUID? = nil,
         report reportId: ReportModel.IDValue) {
        self.id = id
        self.$report.id = reportId
    }
}

// Fluent models are not value-typed or immutable; acknowledge non-thread-safety explicitly.
extension CoverageModel: @unchecked Sendable {}
