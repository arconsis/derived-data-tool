//
//  File.swift
//  DerivedDataTool
//
//  Created by Moritz Ellerbrock on 06.12.24.
//

import Foundation
import Shared

public protocol CoverageReportRepository {
    func getAllEntries(for application: String?) async throws -> [CoverageReport]
    func getEntry(for key: DBKey) async throws -> CoverageReport?
    func addEntry(_ entry: FullCoverageReport, for key: DBKey) async throws
    func replaceEntry(_ entry: FullCoverageReport, for key: DBKey) async throws
    func removeEntry(for key: DBKey) async throws
}
