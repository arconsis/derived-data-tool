//
//  File.swift
//
//
//  Created by Moritz Ellerbrock on 29.04.24.
//

import Foundation
import FluentKit
import Shared

enum ReportModelRepositoryError: Error {
    case entityNotCreated
}

public protocol ReportModelRepository {
    func add(report: CoverageMetaReport) async throws
    func shutDownDatabaseConnection() async throws
}

struct ReportModelRepositoryImpl {
    let db: any Database
    let logger = Logger(label: "RepositoryImpl")
    init(db: any Database) {
        self.db = db
    }
}

private extension ReportModelRepositoryImpl {
    func reportModelQuery() -> QueryBuilder<ReportModel> {
        ReportModel.query(on: db)
    }

    func coverageModelQuery() -> QueryBuilder<CoverageModel> {
        CoverageModel.query(on: db)
    }

    func targetModelQuery() -> QueryBuilder<TargetModel> {
        TargetModel.query(on: db)
    }

    func createReportModel(fileInfo: XCResultFile, gitRoot gitPath: String) async throws -> ReportModel.IDValue {
        let model = ReportModel(
            date: fileInfo.date,
            type: fileInfo.type,
            url: fileInfo.url.path().sanitize(by: gitPath),
            application: fileInfo.application
        )
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }

    func createCoverageModel(report reportId: ReportModel.IDValue) async throws -> CoverageModel.IDValue {
        let model = CoverageModel(report: reportId)
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }

    func createTargetModel(name: String, executableLines: Int, coveredLines: Int, coverageId: CoverageModel.IDValue) async throws -> TargetModel.IDValue {
        let model = TargetModel(name: name,
                                executableLines: executableLines,
                                coveredLines: coveredLines,
                                coverageId: coverageId)
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }
}

extension ReportModelRepositoryImpl: ReportModelRepository {
    func add(report: CoverageMetaReport) async throws {
        do {
            let gitPath = report.coverage.commonPathPrefix()

            let reportId = try await createReportModel(fileInfo: report.fileInfo, gitRoot: gitPath)
            try await make(report.coverage, parent: reportId, gitRoot: gitPath)
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    func shutDownDatabaseConnection() async throws {
        
    }

    private func make(_ coverage: CoverageReport, parent: ReportModel.IDValue, gitRoot gitPath: String) async throws {
        do {
            let cleanedUpCoverageReport = coverage.removingCommonPrefix()

            let modelId = try await createCoverageModel(report: parent)

            for target in cleanedUpCoverageReport.targets {
                try await make(target, parent: modelId, gitRoot: gitPath)
            }
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    private func make(_ target: Target, parent: CoverageModel.IDValue, gitRoot gitPath: String) async throws {
        do {
            let _ = try await createTargetModel(name: target.name,
                                                       executableLines: target.executableLines,
                                                       coveredLines: target.coveredLines,
                                                       coverageId: parent)
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }
}
