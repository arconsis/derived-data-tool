//
//  CompressionTests.swift
//
//
//  Created by Moritz Ellerbrock on 10.07.23.
//

import Foundation
@testable import Helper
import Shared
import XCTest

final class CompressionTests: XCTestCase {
    struct TestObject: Codable, Equatable {
        struct EmbeddedTestObject: Codable, Equatable {
            let embeddedName: String
        }

        let name: String
        let embedded: EmbeddedTestObject
    }

    let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    var fileHandler: FileHandler!

    static func makeObject() -> TestObject {
        .init(name: "Test", embedded: TestObject.EmbeddedTestObject(embeddedName: "embedded"))
    }

    func testCompressObject() async throws {
        fileHandler = .init()

        let testObject = Self.makeObject()
        let jsonObject = try jsonEncoder.encode(testObject)

        let compressedData = try Compressor.compress(jsonObject)

        let tempUrl = FileManager().temporaryDirectory.appending(pathComponent: "test.zlib")

        print(tempUrl.absoluteString)

        try fileHandler.writeData(compressedData, at: tempUrl)

        let data = try Data(contentsOf: tempUrl)

        let uncompressedData = try Compressor.decompress(data)

        let uncompressedObject = try jsonDecoder.decode(TestObject.self, from: uncompressedData)

        XCTAssertEqual(testObject, uncompressedObject)

        try fileHandler.deleteFile(at: tempUrl)
    }

    func testCompressObjectData() async throws {
        let tempUrl = FileManager().temporaryDirectory.appending(pathComponent: "test.zlib")

        do {
            fileHandler = .init()

            guard let url = Bundle.module.url(forResource: "TestData", withExtension: "json") else {
                XCTFail("Resource is missing")
                return
            }

            let urlData = try Data(contentsOf: url)

            guard let savedReport = try? jsonDecoder.decode(CoverageMetaReport.self, from: urlData) else {
                XCTFail("Resource Content is missing")
                return
            }

            let jsonData = try jsonEncoder.encode(savedReport)
            print("RAW data: \(jsonData.count)")

            let compressedData = try Compressor.compress(jsonData)
            print("COMPRESSED data: \(compressedData.count)")

            print(tempUrl.absoluteString)

            try fileHandler.writeData(compressedData, at: tempUrl)

            let data = try Data(contentsOf: tempUrl, options: Data.ReadingOptions.mappedIfSafe)
            print("COMPRESSED data: \(data.count)")
            if compressedData.count != data.count { print("COMPRESSED diff: \(compressedData.count - data.count)") }

            let uncompressedData = try Compressor.decompress(data)
            print("RAW data: \(uncompressedData.count)")
            if uncompressedData.count != jsonData.count { print("RAW diff: \(uncompressedData.count - jsonData.count)") }

            let uncompressedJsonObject = try jsonDecoder.decode(CoverageMetaReport.self, from: uncompressedData)

            XCTAssertEqual(savedReport, uncompressedJsonObject)

        } catch {
            try? fileHandler.deleteFile(at: tempUrl)
            print(error.localizedDescription)
            throw error
        }

        try? fileHandler.deleteFile(at: tempUrl)
    }
}
