//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import Shared

public protocol CoverageReportRepository {
    func getAllEntries(for application: String?) async throws -> [SQLiteCoverage]
    func getEntry(for key: DBKey) async throws -> SQLiteCoverage?
    func addEntry(_ entry: CoverageReport, for key: DBKey) async throws
    func replaceEntry(_ entry: CoverageReport, for key: DBKey) async throws
    func removeEntry(for key: DBKey) async throws
}
