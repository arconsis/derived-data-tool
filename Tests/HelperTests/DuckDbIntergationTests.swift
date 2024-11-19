//
//  DuckDbIntergationTests.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 18.11.24.
//

import XCTest
import Foundation
import Shared
@testable import Helper

final class DuckDbIntergationTests: XCTestCase {
    enum DummyError: Error {
        case dummy
    }


    func testAddEntry() async throws {
        let store = try Self.makeCoverageStore()
        let testData = try Self.makeTestDate()
        let dbKey = CoverageReportStoreImpl.makeKey(from: testData.fileInfo.date, application: testData.fileInfo.application)
        try await store.addEntry(testData.coverage, for: dbKey)
    }
}


extension DuckDbIntergationTests {
    static func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeCoverageStore() throws -> CoverageReportStore {
        let dbConnector = try DuckDBConnection(with: .inMemory)
        return try CoverageReportStoreImpl(duckDBConnection: dbConnector)
    }

    static func makeTestDate() throws -> CoverageMetaReport {
        guard let url = Bundle.module.url(forResource: "TestData-tiny", withExtension: "json") else {
            XCTFail("Resource is missing")
            throw DummyError.dummy
        }

        let urlData = try Data(contentsOf: url)

        guard let savedReport = try? Self.jsonDecoder().decode(CoverageMetaReport.self, from: urlData) else {
            XCTFail("Resource Content is missing")
            throw DummyError.dummy
        }

        return savedReport
    }
}
