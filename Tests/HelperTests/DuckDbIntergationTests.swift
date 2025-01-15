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
        let store = try await Self.makeCoverageStore()
        let testData = try Self.makeTestDate()
        let dbKey = CoverageReportStoreImpl.makeKey(from: testData.fileInfo.date, application: testData.fileInfo.application)
        try await store.addEntry(testData.coverage, for: dbKey)
        let result = try await store.getEntry(for: dbKey)
        let expected = testData.coverage
        XCTAssertEqual(result, expected)
    }

    func testRemovingEntry() async throws {
        let store = try await Self.makeCoverageStore()
        let testData = try Self.makeTestDate()
        let dbKey = CoverageReportStoreImpl.makeKey(from: testData.fileInfo.date, application: testData.fileInfo.application)
        try await store.addEntry(testData.coverage, for: dbKey)
        let entries = try await store.getAllEntries()
        let result = entries.first
        XCTAssertEqual(result?.coverage, testData.coverage)
        try await store.removeEntry(for: dbKey)
        let emptyEntries = try await store.getAllEntries()
        guard let _ = emptyEntries.first else {
            return
        }
        XCTFail("Empty entries should not be empty")
    }

    func testApplicationNoInDataset() async throws {
        let store = try await Self.makeCoverageStore()
        let testData = try Self.makeTestDate()
        let dbKey = CoverageReportStoreImpl.makeKey(from: testData.fileInfo.date, application: testData.fileInfo.application)
        try await store.addEntry(testData.coverage, for: dbKey)
        let entries = try await store.getAllEntries()
        let result = entries.first
        XCTAssertEqual(result?.coverage, testData.coverage)
        let emptyEntries = try await store.getAllEntries(for: "FantasyApp")
        guard let _ = emptyEntries.first else {
            return
        }
        XCTFail("Empty entries should not be empty")
    }
}


extension DuckDbIntergationTests {
    static func makeCoverageStore() async throws -> CoverageReportStore {
        let dbConnector = try DuckDBConnection(with: .inMemory)
        let store = try CoverageReportStoreImpl(duckDBConnection: dbConnector)
        try await store.setup()
        return store
    }

    static func makeTestDate() throws -> CoverageMetaReport {
        guard let url = Bundle.module.url(forResource: "TestData-tiny", withExtension: "json") else {
            XCTFail("Resource is missing")
            throw DummyError.dummy
        }

        let urlData = try Data(contentsOf: url)

        guard let savedReport = try? SingleDecoder.shared.decode(CoverageMetaReport.self, from: urlData) else {
            XCTFail("Resource Content is missing")
            throw DummyError.dummy
        }

        return savedReport
    }
}
