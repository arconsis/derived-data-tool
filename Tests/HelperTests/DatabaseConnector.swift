//
//  DatabaseConnector.swift
//  
//
//  Created by Moritz Ellerbrock on 26.04.24.
//

import XCTest
@testable import Helper
import Shared

final class DatabaseConnectorTests: XCTestCase {

    var dbConnector: DatabaseConnector!

    let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    override func setUp() async throws {
        let credentials = DatabaseConnector.DatabaseCredentials(hostname: "localhost", username: "postgres", password: "mysecretpassword", database: "postgres")
        dbConnector = DatabaseConnector(credentials: credentials)
        try await dbConnector.connect()
    }

    override func tearDown() async throws {
        try await dbConnector.disconnect()
    }

    func testExample() async throws {
        let sut = ReportModelRepository(db: dbConnector.db)

        guard let url = Bundle.module.url(forResource: "TestData", withExtension: "json") else {
            XCTFail("Resource is missing")
            return
        }

        let urlData = try Data(contentsOf: url)

        guard let savedReport = try? jsonDecoder.decode(CoverageMetaReport.self, from: urlData) else {
            XCTFail("Resource Content is missing")
            return
        }

        try await sut.add(report: savedReport)

        print("HIT")
    }
}
