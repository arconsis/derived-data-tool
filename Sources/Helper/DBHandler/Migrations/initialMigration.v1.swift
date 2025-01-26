//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 25.06.24.
//

import FluentKit

struct InitialMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await CreateReportModel.prepare(on: database)
        try await CreateCoverageModel.prepare(on: database)
        try await CreateTargetModel.prepare(on: database)
    }

    func revert(on database: any Database) async throws {
        try await CreateTargetModel.prepare(on: database)
        try await CreateCoverageModel.prepare(on: database)
        try await CreateReportModel.prepare(on: database)
    }
}

