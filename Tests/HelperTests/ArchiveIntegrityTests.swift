//
//  ArchiveIntegrityTests.swift
//
//
//  Created by Moritz Ellerbrock on 02.03.26.
//

import Foundation
@testable import Helper
import Shared
import XCTest

final class ArchiveIntegrityTests: XCTestCase {
    var fileHandler: FileHandler!
    var coder: CoverageMetaReportCoder!

    let jsonDecoder: JSONDecoder = {
        SingleDecoder.shared
    }()

    let jsonEncoder: JSONEncoder = {
        SingleEncoder.shared
    }()

    override func setUp() {
        super.setUp()
        fileHandler = FileHandler()
        coder = CoverageMetaReportCoder()
    }

    override func tearDown() {
        fileHandler = nil
        coder = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeTestReport() -> CoverageMetaReport {
        // Create a mock XCResultFile using a properly formatted URL
        let dateString = DateFormat.YearMonthDayHoursMinutesSecondsAndTimeZone.string(from: Date())
        let fileName = "Run-TestApp-\(dateString).xcresult"
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(fileName)

        guard let fileInfo = try? XCResultFile(with: url) else {
            fatalError("Failed to create test XCResultFile")
        }

        // Create a simple coverage report with one target
        let function = Function(
            name: "testFunction",
            executableLines: 10,
            coveredLines: 7,
            lineNumber: 1,
            executionCount: 5
        )

        let file = File(
            name: "TestFile.swift",
            path: "/path/to/TestFile.swift",
            functions: [function]
        )

        let target = Target(
            name: "TestTarget",
            files: [file]
        )

        let coverageReport = CoverageReport(targets: [target])

        return CoverageMetaReport(
            fileInfo: fileInfo,
            coverage: coverageReport,
            checksum: nil
        )
    }

    // MARK: - Tests

    func testEncodeWithChecksum() async throws {
        let testReport = makeTestReport()

        // Test uncompressed encoding
        let uncompressedData = try coder.encode(testReport, compressed: false)

        // Decode to verify checksum was added
        let decodedUncompressed = try jsonDecoder.decode(CoverageMetaReport.self, from: uncompressedData)

        XCTAssertNotNil(decodedUncompressed.checksum, "Checksum should be present in uncompressed encoding")
        XCTAssertFalse(decodedUncompressed.checksum!.isEmpty, "Checksum should not be empty")

        // Verify checksum format (SHA-256 produces 64 hex characters)
        XCTAssertEqual(decodedUncompressed.checksum!.count, 64, "SHA-256 checksum should be 64 characters")

        // Verify checksum only contains hex characters
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        XCTAssertTrue(decodedUncompressed.checksum!.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) },
                     "Checksum should only contain hex characters")
    }

    func testEncodeWithChecksumCompressed() async throws {
        let testReport = makeTestReport()

        // Test compressed encoding
        let compressedData = try coder.encode(testReport, compressed: true)

        // Decompress and decode
        let decompressedData = try Compressor.decompress(compressedData)
        let decodedCompressed = try jsonDecoder.decode(CoverageMetaReport.self, from: decompressedData)

        XCTAssertNotNil(decodedCompressed.checksum, "Checksum should be present in compressed encoding")
        XCTAssertFalse(decodedCompressed.checksum!.isEmpty, "Checksum should not be empty")

        // Verify checksum format (SHA-256 produces 64 hex characters)
        XCTAssertEqual(decodedCompressed.checksum!.count, 64, "SHA-256 checksum should be 64 characters")
    }

    func testChecksumValidation() async throws {
        let testReport = makeTestReport()

        // Encode with checksum
        let encodedData = try coder.encode(testReport, compressed: false)
        let decodedReport = try jsonDecoder.decode(CoverageMetaReport.self, from: encodedData)

        guard let checksum = decodedReport.checksum else {
            XCTFail("Checksum should be present")
            return
        }

        // Create a version without checksum to verify against
        let reportWithoutChecksum = CoverageMetaReport(
            fileInfo: decodedReport.fileInfo,
            coverage: decodedReport.coverage,
            checksum: nil
        )

        // Use the same encoder configuration as CoverageMetaReportCoder
        let encoder = SingleEncoder.shared
        encoder.outputFormatting = .prettyPrinted
        let dataWithoutChecksum = try encoder.encode(reportWithoutChecksum)

        // Verify the checksum matches the data without checksum
        let calculatedChecksum = try ArchiveIntegrityValidator.calculateChecksum(for: dataWithoutChecksum)
        XCTAssertEqual(checksum.lowercased(), calculatedChecksum.lowercased(),
                      "Stored checksum should match calculated checksum")

        // Verify using the validator
        let isValid = try ArchiveIntegrityValidator.verifyChecksum(for: dataWithoutChecksum, expectedChecksum: checksum)
        XCTAssertTrue(isValid, "Checksum should be valid")
    }

    func testEncodeWithChecksumToFile() async throws {
        let tempUrl = FileManager().temporaryDirectory.appending(pathComponent: "test-checksum.json")

        do {
            let testReport = makeTestReport()

            // Encode with checksum
            let encodedData = try coder.encode(testReport, compressed: false)

            // Write to file
            try fileHandler.writeData(encodedData, at: tempUrl)

            // Read back from file
            let fileData = try Data(contentsOf: tempUrl)
            let decodedReport = try jsonDecoder.decode(CoverageMetaReport.self, from: fileData)

            // Verify checksum is present and valid
            XCTAssertNotNil(decodedReport.checksum, "Checksum should be present after file round-trip")

            // Verify file integrity using the stored checksum
            // We need to recreate the exact encoding that was used to calculate the checksum
            let reportWithoutChecksum = CoverageMetaReport(
                fileInfo: decodedReport.fileInfo,
                coverage: decodedReport.coverage,
                checksum: nil
            )

            // Use the same encoder configuration as CoverageMetaReportCoder
            let encoder = SingleEncoder.shared
            encoder.outputFormatting = .prettyPrinted
            let dataWithoutChecksum = try encoder.encode(reportWithoutChecksum)

            let isValid = try ArchiveIntegrityValidator.verifyChecksum(
                for: dataWithoutChecksum,
                expectedChecksum: decodedReport.checksum!
            )
            XCTAssertTrue(isValid, "File checksum should be valid")

            try fileHandler.deleteFile(at: tempUrl)
        } catch {
            try? fileHandler.deleteFile(at: tempUrl)
            throw error
        }
    }

    func testEncodeWithChecksumCompressedToFile() async throws {
        let tempUrl = FileManager().temporaryDirectory.appending(pathComponent: "test-checksum.zlib")

        do {
            let testReport = makeTestReport()

            // Encode with checksum (compressed)
            let compressedData = try coder.encode(testReport, compressed: true)

            // Write to file
            try fileHandler.writeData(compressedData, at: tempUrl)

            // Read back from file
            let fileData = try Data(contentsOf: tempUrl)

            // Decompress and decode
            let decompressedData = try Compressor.decompress(fileData)
            let decodedReport = try jsonDecoder.decode(CoverageMetaReport.self, from: decompressedData)

            // Verify checksum is present
            XCTAssertNotNil(decodedReport.checksum, "Checksum should be present in compressed file")

            // Verify file integrity
            let reportWithoutChecksum = CoverageMetaReport(
                fileInfo: decodedReport.fileInfo,
                coverage: decodedReport.coverage,
                checksum: nil
            )

            // For compressed files, the encoder doesn't use prettyPrinted
            let encoder = SingleEncoder.shared
            encoder.outputFormatting = []
            let dataWithoutChecksum = try encoder.encode(reportWithoutChecksum)

            let isValid = try ArchiveIntegrityValidator.verifyChecksum(
                for: dataWithoutChecksum,
                expectedChecksum: decodedReport.checksum!
            )
            XCTAssertTrue(isValid, "Compressed file checksum should be valid")

            try fileHandler.deleteFile(at: tempUrl)
        } catch {
            try? fileHandler.deleteFile(at: tempUrl)
            throw error
        }
    }

    func testChecksumConsistency() async throws {
        let testReport = makeTestReport()

        // Encode the same report multiple times
        let encoded1 = try coder.encode(testReport, compressed: false)
        let encoded2 = try coder.encode(testReport, compressed: false)

        let decoded1 = try jsonDecoder.decode(CoverageMetaReport.self, from: encoded1)
        let decoded2 = try jsonDecoder.decode(CoverageMetaReport.self, from: encoded2)

        // Checksums should be identical for the same data
        XCTAssertEqual(decoded1.checksum, decoded2.checksum,
                      "Checksums should be consistent for identical data")
    }
}
