//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 07.12.24.
//

import Foundation
import SQLite3
import Shared

class SQLiteDatabase {
    private var db: OpaquePointer?

    init(databasePath: String) throws {
        try openDatabase(at: databasePath)
    }

    deinit {
        closeDatabase()
    }

    // MARK: - Database Management
    private func openDatabase(at path: String) throws {
        if sqlite3_open(path, &db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.openDatabase(message: errorMessage)
        }
    }

    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
        }
    }

    // MARK: - Filters
    enum CoverageReportFilter {
        case id(Int)
        case date(String)
    }

    // MARK: - Fetch with a Filter
    private func fetchCoverageReports(filter: CoverageReportFilter) throws -> [SQLiteCoverage] {
        var baseQuery = """
        SELECT
            CoverageReports.id AS coverage_report_id,
            CoverageReports.date AS coverage_report_date,
            Targets.id AS target_id,
            Targets.coverage_report_id AS target_coverage_report_id,
            Targets.name AS target_name,
            Targets.executable_lines AS target_executable_lines,
            Targets.covered_lines AS target_covered_lines
        FROM CoverageReports
        LEFT JOIN Targets
        ON CoverageReports.id = Targets.coverage_report_id
        """

        // Adjust the query based on the filter
        switch filter {
        case .id(let reportID):
            baseQuery += " WHERE CoverageReports.id = \(reportID);"
        case .date(let reportDate):
            baseQuery += " WHERE CoverageReports.date = \(reportDate);"
        }

        var statement: OpaquePointer?
        defer {
            sqlite3_finalize(statement)
        }

        if sqlite3_prepare_v2(db, baseQuery, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.prepare(message: errorMessage)
        }

        // Bind the parameter
        switch filter {
        case .id(let reportID):
            sqlite3_bind_int(statement, 1, Int32(reportID))
        case .date(let reportDate):
            sqlite3_bind_text(statement, 1, (reportDate as NSString).utf8String, -1, nil)
        }

        // Dictionary to group targets by coverage report
        var coverageReportsDict: [Int: SQLiteCoverage] = [:]

        while sqlite3_step(statement) == SQLITE_ROW {
            let coverageReportID = Int(sqlite3_column_int(statement, 0))
            let coverageReportDate = String(cString: sqlite3_column_text(statement, 1))

            let targetID = sqlite3_column_type(statement, 2) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 2)) : nil
            let targetName = sqlite3_column_type(statement, 4) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 4)) : nil
            let targetExecutableLines = sqlite3_column_type(statement, 5) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 5)) : nil
            let targetCoveredLines = sqlite3_column_type(statement, 6) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 6)) : nil

            var coverageReport = coverageReportsDict[coverageReportID] ?? SQLiteCoverage(
                id: coverageReportID,
                date: coverageReportDate,
                targets: []
            )

            if let targetID = targetID,
               let targetName = targetName,
               let targetExecutableLines = targetExecutableLines,
               let targetCoveredLines = targetCoveredLines {
                let target = SQLiteCoverage.Target(
                    id: targetID,
                    coverageReportID: coverageReportID,
                    name: targetName,
                    executableLines: targetExecutableLines,
                    coveredLines: targetCoveredLines
                )
                coverageReport.targets.append(target)
            }

            coverageReportsDict[coverageReportID] = coverageReport
        }

        return Array(coverageReportsDict.values)
    }

    // Convenience functions:
    func fetchCoverageReport(byID id: Int) throws -> CoverageReport? {
        let reports: [SQLiteCoverage] = try fetchCoverageReports(filter: .id(id))
        return reports.first?.toDTO()
    }

    func fetchCoverageReports(onDate date: Date) throws -> CoverageReport? {
        let dateString: String = DateFormat.yearMontDay.string(from: date)
        let reports: [SQLiteCoverage] = try fetchCoverageReports(filter: .date(dateString))
        return reports.first?.toDTO()
    }

    func addCoverageReport(_ report: FullCoverageReport) throws {

    }

    // MARK: - SQLite Errors
    enum SQLiteError: Error {
        case openDatabase(message: String)
        case prepare(message: String)
        case execution(message: String)
    }
}
