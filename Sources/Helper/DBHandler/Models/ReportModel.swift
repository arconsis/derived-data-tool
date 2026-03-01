//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import Foundation
import FluentKit

public final class ReportModel: Model {
    typealias FieldKeyStore = ModelDefinition.Report.FieldKeys

    public static let schema = ModelDefinition.Report.schema

    @ID(key: .id)
    public var id: UUID?

    @Field(key: FieldKeyStore.date)
    public var timestamp: String

    @Field(key: FieldKeyStore.type)
    public var type: String

    @Field(key: FieldKeyStore.url)
    public var url: String

    @Field(key: FieldKeyStore.application)
    public var application: String

    @OptionalChild(for: \.$report)
    public var coverage: CoverageModel?

    public init() {}

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

