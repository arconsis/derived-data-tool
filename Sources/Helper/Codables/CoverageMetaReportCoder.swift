//
//  CoverageMetaReportCoder.swift
//
//
//  Created by Moritz Ellerbrock on 26.06.23.
//

import DependencyInjection
import Foundation
import Shared

struct CoverageMetaReportCoder {
    enum CoverageMetaReportCoderError: Errorable {
        case decodingFailed
        case decodingFailedWithDetails(String)
        case checksumMismatch(expected: String, actual: String)
        case checksumCalculationFailed

        var printsHelp: Bool { false }
        var errorDescription: String? { localizedDescription }

        var localizedDescription: String {
            switch self {
            case .decodingFailed: return "decodingFailed"
            case let .decodingFailedWithDetails(filename): return "decodingFailed: \(filename)"
            case let .checksumMismatch(expected, actual): return "checksumMismatch: expected \(expected), got \(actual)"
            case .checksumCalculationFailed: return "checksumCalculationFailed"
            }
        }
    }

    @Injected(\.logger) var logger

    // MARK: - Decoder

    private var decoder: JSONDecoder {
        SingleDecoder.shared
    }

    private func verifyChecksum(for report: CoverageMetaReport, isCompressed: Bool) throws {
        // If no checksum is present, skip verification (legacy files)
        guard let storedChecksum = report.checksum else {
            return
        }

        // Create version without checksum for verification
        let reportWithoutChecksum = CoverageMetaReport(
            fileInfo: report.fileInfo,
            coverage: report.coverage,
            checksum: nil
        )

        // Encode without checksum to calculate expected checksum
        // Use the same formatting that was used during encoding
        let encoder = SingleEncoder.shared
        if !isCompressed {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = .sortedKeys
        }
        let dataWithoutChecksum = try encoder.encode(reportWithoutChecksum)

        // Calculate checksum of the data without checksum field
        guard let calculatedChecksum = try? ArchiveIntegrityValidator.calculateChecksum(for: dataWithoutChecksum) else {
            throw CoverageMetaReportCoderError.checksumCalculationFailed
        }

        // Verify checksums match
        if storedChecksum != calculatedChecksum {
            throw CoverageMetaReportCoderError.checksumMismatch(expected: storedChecksum, actual: calculatedChecksum)
        }
    }

    func decode(contentOf url: URL) throws -> CoverageMetaReport {
        logger.log("Looking into file at path:", url.lastPathComponent)
        do {
            let isUncompressed: Bool = url.lastPathComponent.contains("json")
            if isUncompressed {
                let fileContent = try String(contentsOfFile: url.fullPath, encoding: .utf8)

                guard
                    let data = fileContent.data(using: .utf8),
                    let report = decodeUncompressed(data: data)
                else {
                    throw CoverageMetaReportCoderError.decodingFailedWithDetails(url.lastPathComponent)
                }

                logger.log("DECODE: SUCCESS")
                return report
            } else {
                let data = try Data(contentsOf: url)
                guard let report = decodeCompressed(data: data) else {
                    throw CoverageMetaReportCoderError.decodingFailedWithDetails(url.lastPathComponent)
                }

                logger.log("DECODE: SUCCESS")
                return report
            }
        } catch {
            throw CoverageMetaReportCoderError.decodingFailedWithDetails(url.lastPathComponent)
        }
    }

    private func decodeUncompressed(data: Data) -> CoverageMetaReport? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

            let jsonSerializedData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)

            var coverageMetaReport = try? decoder.decode(CoverageMetaReport.self, from: jsonSerializedData)
            if coverageMetaReport == nil {
                coverageMetaReport = try decoder.decode(CoverageMetaReport.self, from: data)
            }

            // Verify checksum if present
            if let report = coverageMetaReport {
                try verifyChecksum(for: report, isCompressed: false)
            }

            return coverageMetaReport
        } catch {
            logger.error(error.localizedDescription)
            return nil
        }
    }

    private func decodeCompressed(data: Data) -> CoverageMetaReport? {
        do {
            let decompressedData = try Compressor.decompress(data)

            guard let jsonString = String(data: decompressedData, encoding: .utf8) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to convert decompressed data to string"))
            }

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to convert string to data"))
            }

            let jsonObject = try JSONSerialization.jsonObject(with: decompressedData, options: [])

            let jsonSerializedData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)

            var coverageMetaReport = try? decoder.decode(CoverageMetaReport.self, from: jsonSerializedData)
            if coverageMetaReport == nil {
                coverageMetaReport = try decoder.decode(CoverageMetaReport.self, from: jsonData)
            }

            // Verify checksum if present
            if let report = coverageMetaReport {
                try verifyChecksum(for: report, isCompressed: true)
            }

            return coverageMetaReport
        } catch {
            logger.error(error.localizedDescription)
            return nil
        }
    }

    // MARK: - ENCODER

    func encode(_ report: CoverageMetaReport, compressed: Bool = true) throws -> Data {
        let encoder = SingleEncoder.shared
        if !compressed {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = .sortedKeys
        }

        // First encode without checksum to calculate it
        let reportWithoutChecksum = CoverageMetaReport(
            fileInfo: report.fileInfo,
            coverage: report.coverage,
            checksum: nil
        )
        let dataWithoutChecksum = try encoder.encode(reportWithoutChecksum)

        // Calculate checksum of the data without checksum field
        guard let checksum = try? ArchiveIntegrityValidator.calculateChecksum(for: dataWithoutChecksum) else {
            throw CoverageMetaReportCoderError.checksumCalculationFailed
        }

        // Create new report with checksum and encode it
        let reportWithChecksum = CoverageMetaReport(
            fileInfo: report.fileInfo,
            coverage: report.coverage,
            checksum: checksum
        )
        let data = try encoder.encode(reportWithChecksum)

        if compressed {
            return try Compressor.compress(data)
        } else {
            return data
        }
    }
}
