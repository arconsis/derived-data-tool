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


struct ReportModelRepository {
    let db: any Database
    init(db: any Database) {
        self.db = db
    }
}

private extension ReportModelRepository {
    func reportModelQuery() -> QueryBuilder<ReportModel> {
        ReportModel.query(on: db)
    }

    func coverageModelQuery() -> QueryBuilder<CoverageModel> {
        CoverageModel.query(on: db)
    }

    func fileModelQuery() -> QueryBuilder<FileModel> {
        FileModel.query(on: db)
    }

    func functionModelQuery() -> QueryBuilder<FunctionModel> {
        FunctionModel.query(on: db)
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

    func createCoverageModel(report: ReportModel.IDValue) async throws -> CoverageModel.IDValue {
        let model = CoverageModel(report: report)
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }

    func createTargetModel(coverageId: CoverageModel.IDValue, name: String) async throws -> TargetModel.IDValue {
        let model = TargetModel(coverageId: coverageId, name: name)
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }

    func createFileModel(targetId: TargetModel.IDValue, name: String, path: String, gitRoot gitPath: String) async throws -> FileModel.IDValue {
        let model = FileModel(targetId: targetId, name: name, path: path.sanitize(by: gitPath))
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }

    func createFunctionModel(fileId: FileModel.IDValue, name: String, lineNumber: Int, executableLines: Int, executionCount: Int, coveredLines: Int) async throws -> FunctionModel.IDValue {
        let model = FunctionModel(fileId: fileId, name: name, lineNumber: lineNumber, executableLines: executableLines, executionCount: executionCount, coveredLines: coveredLines)
        try await model.save(on: db)
        guard let modelId = model.id else {
            throw ReportModelRepositoryError.entityNotCreated
        }
        return modelId
    }
}

extension ReportModelRepository {
    func add(report: CoverageMetaReport) async throws {
        do {
            let gitPath = report.coverage.commonPathPrefix()

            let reportId = try await createReportModel(fileInfo: report.fileInfo, gitRoot: gitPath)
            try await make(report.coverage, parent: reportId, gitRoot: gitPath)
        } catch {
            print(String(reflecting: error))
            throw error
        }
    }

    private func make(_ coverage: CoverageReport, parent: ReportModel.IDValue, gitRoot gitPath: String) async throws {
        do {
            let modelId = try await createCoverageModel(report: parent)

            for target in coverage.targets {
                try await make(target, parent: modelId, gitRoot: gitPath)
            }
        } catch {
            print(String(reflecting: error))
            throw error
        }
    }

    private func make(_ target: Target, parent: CoverageModel.IDValue, gitRoot gitPath: String) async throws {
        do {
            let targetId = try await createTargetModel(coverageId: parent, name: target.name)

            for file in target.files {
                try await make(file, parent: targetId, gitRoot: gitPath)
            }
        } catch {
            print(String(reflecting: error))
        }
    }

    private func make(_ file: File, parent: TargetModel.IDValue, gitRoot gitPath: String) async throws {
        do {
            let targetId = try await createFileModel(targetId: parent,
                                                     name: file.name,
                                                     path: file.path,
                                                     gitRoot: gitPath)
            for function in file.functions {
                let _ = try await createFunctionModel(fileId: targetId,
                                                               name: function.name,
                                                               lineNumber: function.lineNumber,
                                                               executableLines: function.executableLines,
                                                               executionCount: function.executionCount,
                                                               coveredLines: function.coveredLines)
            }
        } catch {
            print(String(reflecting: error))
        }
    }
}
