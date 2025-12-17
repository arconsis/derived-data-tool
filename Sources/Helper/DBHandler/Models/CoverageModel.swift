//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import Foundation
import FluentKit

final class CoverageModel: Model {
    typealias FieldKeyStore = ModelDefinition.Coverage.FieldKeys

    static let schema = ModelDefinition.Coverage.schema

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeyStore.report)
    var report: ReportModel

    @Children(for: \.$coverage)
    var targets: [TargetModel]

    init() {}

    init(id: UUID? = nil,
         report reportId: ReportModel.IDValue) {
        self.id = id
        self.$report.id = reportId
    }
}

// Fluent models are not value-typed or immutable; acknowledge non-thread-safety explicitly.
extension CoverageModel: @unchecked Sendable {}
