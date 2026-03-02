//
//  ArchiveIntegrityValidator.swift
//
//
//  Created by Moritz Ellerbrock on 02.03.26.
//

import CryptoKit
import Foundation
import Shared

enum ArchiveIntegrityValidator {
    static func calculateChecksum(for data: Data) throws -> String {
        guard !data.isEmpty else {
            throw ErrorFactory.failing(error: IntegrityValidatorError.emptyData)
        }

        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func calculateChecksum(at url: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ErrorFactory.failing(error: IntegrityValidatorError.fileNotFound)
        }

        do {
            let data = try Data(contentsOf: url)
            return try calculateChecksum(for: data)
        } catch {
            throw ErrorFactory.failing(error: IntegrityValidatorError.checksumCalculationFailed)
        }
    }

    static func verifyChecksum(for data: Data, expectedChecksum: String) throws -> Bool {
        let calculatedChecksum = try calculateChecksum(for: data)
        return calculatedChecksum.lowercased() == expectedChecksum.lowercased()
    }

    static func verifyChecksum(at url: URL, expectedChecksum: String) throws -> Bool {
        let calculatedChecksum = try calculateChecksum(at: url)
        return calculatedChecksum.lowercased() == expectedChecksum.lowercased()
    }
}

extension ArchiveIntegrityValidator {
    enum IntegrityValidatorError: Errorable {
        case emptyData
        case fileNotFound
        case checksumCalculationFailed
        case checksumMismatch

        var printsHelp: Bool { false }
        var errorDescription: String? { localizedDescription }
    }
}
