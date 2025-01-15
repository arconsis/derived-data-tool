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
    enum CoverageMetaReportCoderError: Error {
        case decodingFailed
        case decodingFailedWithDetails(String)

        var localizedDescription: String {
            switch self {
            case .decodingFailed: return "decodingFailed"
            case let .decodingFailedWithDetails(filename): return "decodingFailed: \(filename)"
            }
        }
    }

    @Injected(\.logger) var logger

    func decode(contentOf url: URL) throws -> CoverageMetaReport {
        logger.log("DECODE:", url.lastPathComponent)
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

            var coverageMetaReport = try? SingleDecoder.shared.decode(CoverageMetaReport.self, from: jsonSerializedData)
            if coverageMetaReport == nil {
                coverageMetaReport = try SingleDecoder.shared.decode(CoverageMetaReport.self, from: data)
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

            var coverageMetaReport = try? SingleDecoder.shared.decode(CoverageMetaReport.self, from: jsonSerializedData)
            if coverageMetaReport == nil {
                coverageMetaReport = try SingleDecoder.shared.decode(CoverageMetaReport.self, from: jsonData)
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
            encoder.outputFormatting = .prettyPrinted
        }
        let data = try encoder.encode(report)
        if compressed {
            return try Compressor.compress(data)
        } else {
            return data
        }
    }
}
