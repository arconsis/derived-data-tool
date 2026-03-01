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
    func fetchReports(limit: Int) async throws -> [ReportModel]
    func fetchReports(since date: Date) async throws -> [ReportModel]
    func fetchReports(between startDate: Date, and endDate: Date) async throws -> [ReportModel]
}

struct ReportModelRepositoryImpl {
    let db: any Database
    let connector: DatabaseConnector
    let logger = Logger(label: "RepositoryImpl")
    init(db: any Database, connector: DatabaseConnector) {
        self.db = db
        self.connector = connector
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
        do {
            let model = ReportModel(
                date: fileInfo.date,
                type: fileInfo.type,
                url: fileInfo.url.lastPathComponent,
                application: fileInfo.application
            )
            try await model.save(on: db)
            guard let modelId = model.id else {
                throw ReportModelRepositoryError.entityNotCreated
            }
            return modelId
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw ReportModelRepositoryError.entityNotCreated
        }
    }

    func createCoverageModel(report reportId: ReportModel.IDValue) async throws -> CoverageModel.IDValue {
        do {
            let model = CoverageModel(report: reportId)

            try await model.save(on: db)
            guard let modelId = model.id else {
                throw ReportModelRepositoryError.entityNotCreated
            }
            return modelId
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    @discardableResult
    func createTargetModel(name: String, executableLines: Int, coveredLines: Int, coverageId: CoverageModel.IDValue) async throws -> TargetModel.IDValue {
        do {
            let model = TargetModel(name: name,
                                    executableLines: executableLines,
                                    coveredLines: coveredLines,
                                    coverageId: coverageId)
            try await model.save(on: db)
            guard let modelId = model.id else {
                throw ReportModelRepositoryError.entityNotCreated
            }
            return modelId
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }
}

extension ReportModelRepositoryImpl: ReportModelRepository {
    func add(report: CoverageMetaReport) async throws {
        do {
            let gitPath = report.coverage.commonPathPrefix()

            let reportId = try await createReportModel(fileInfo: report.fileInfo, gitRoot: gitPath)
            try await make(report.coverage, parent: reportId)
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    func shutDownDatabaseConnection() async throws {
        try await connector.disconnect()
    }

    func fetchReports(limit: Int) async throws -> [ReportModel] {
        do {
            return try await reportModelQuery()
                .with(\.$coverage) { coverage in
                    coverage.with(\.$targets)
                }
                .sort(\.$timestamp, .descending)
                .limit(limit)
                .all()
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    func fetchReports(since date: Date) async throws -> [ReportModel] {
        do {
            let dateString = date.ISO8601Format(.iso8601)
            return try await reportModelQuery()
                .with(\.$coverage) { coverage in
                    coverage.with(\.$targets)
                }
                .filter(\.$timestamp >= dateString)
                .sort(\.$timestamp, .descending)
                .all()
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    func fetchReports(between startDate: Date, and endDate: Date) async throws -> [ReportModel] {
        do {
            let startDateString = startDate.ISO8601Format(.iso8601)
            let endDateString = endDate.ISO8601Format(.iso8601)
            return try await reportModelQuery()
                .with(\.$coverage) { coverage in
                    coverage.with(\.$targets)
                }
                .filter(\.$timestamp >= startDateString)
                .filter(\.$timestamp <= endDateString)
                .sort(\.$timestamp, .descending)
                .all()
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }

    private func make(_ coverage: CoverageReport, parent: ReportModel.IDValue) async throws {
        do {
            let cleanedUpCoverageReport = coverage.removingCommonPrefix()

            let modelId = try await createCoverageModel(report: parent)

            for target in cleanedUpCoverageReport.targets {
                try await createTargetModel(name: target.name,
                                            executableLines: target.executableLines,
                                            coveredLines: target.coveredLines,
                                            coverageId: modelId)
            }
        } catch {
            logger.error(.init(stringLiteral: String(reflecting: error)))
            throw error
        }
    }
}
