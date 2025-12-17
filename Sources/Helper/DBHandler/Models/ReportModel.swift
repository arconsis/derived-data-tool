//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import Foundation
import FluentKit

final class ReportModel: Model {
    typealias FieldKeyStore = ModelDefinition.Report.FieldKeys

    static let schema = ModelDefinition.Report.schema

    @ID(key: .id)
    var id: UUID?

    @Field(key: FieldKeyStore.date)
    var timestamp: String

    @Field(key: FieldKeyStore.type)
    var type: String

    @Field(key: FieldKeyStore.url)
    var url: String

    @Field(key: FieldKeyStore.application)
    var application: String

    @OptionalChild(for: \.$report)
    private var coverageChild: CoverageModel?

    init() {}

    init(id: UUID? = nil,
        date: Date,
        type: String,
        url: String,
        application: String) {
        self.id = id
        self.timestamp = date.ISO8601Format(.iso8601)
        self.type = type
        self.url = url
        self.application = application
    }
}

// Fluent models are not value-typed or immutable; acknowledge non-thread-safety explicitly.
extension ReportModel: @unchecked Sendable {}

