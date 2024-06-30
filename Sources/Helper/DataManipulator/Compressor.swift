//
//  Compressor.swift
//
//
//  Created by Moritz Ellerbrock on 21.06.23.
//

import Compression
import Foundation
import Shared

enum Compressor {
    static func compress(content: String) throws -> Data {
        guard let data = content.data(using: .utf8) else {
            throw ErrorFactory.failing(error: CompressorError.contentDataConversionFailed)
        }
        return try compress(data)
    }

    static func compress(_ inputData: Data) throws -> Data {
        let inputDataSize = inputData.count
        let byteSize = MemoryLayout<UInt8>.stride
        let bufferSize = inputDataSize / byteSize
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var sourceBuffer = [UInt8](repeating: 0, count: bufferSize)
        inputData.copyBytes(to: &sourceBuffer, count: inputDataSize)
        let compressedSize = compression_encode_buffer(destinationBuffer,
                                                       inputDataSize,
                                                       &sourceBuffer,
                                                       inputDataSize,
                                                       nil,
                                                       COMPRESSION_ZLIB)
        guard compressedSize != 0 else {
            throw ErrorFactory.failing(error: CompressorError.compressionFailed)
        }
        return NSData(bytesNoCopy: destinationBuffer, length: compressedSize) as Data
    }

    static func decompress(_ inputData: Data) throws -> Data {
        let compressedSize = inputData.count
        var destinationBufferCapacity = compressedSize * 100 // Initial capacity estimation for the destination buffer
        var destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferCapacity)
        var sourceBuffer = [UInt8](repeating: 0, count: compressedSize)
        inputData.copyBytes(to: &sourceBuffer, count: compressedSize)

        var decompressedSize = 0

        var isFirstError = false

        repeat {
            decompressedSize = compression_decode_buffer(destinationBuffer,
                                                         destinationBufferCapacity,
                                                         &sourceBuffer,
                                                         compressedSize,
                                                         nil,
                                                         COMPRESSION_ZLIB)

            if decompressedSize == 0 {
                if errno == EAGAIN {
                    // The destination buffer was not large enough, resize and try again
                    destinationBufferCapacity = destinationBufferCapacity * 2
                    destinationBuffer.deallocate()
                    destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferCapacity)
                } else {
                    if !isFirstError {
                        isFirstError = true
                        // The destination buffer was not large enough, resize and try again
                        destinationBufferCapacity = destinationBufferCapacity * 3
                        destinationBuffer.deallocate()
                        destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferCapacity)
                    } else {
                        // Error occurred during decompression
                        destinationBuffer.deallocate()
                        throw ErrorFactory.failing(error: CompressorError.decompressionFailed)
                    }
                }
            }
        } while decompressedSize == 0

        let decompressedData = Data(bytesNoCopy: destinationBuffer, count: decompressedSize, deallocator: .free)

        return decompressedData
    }
}

extension Compressor {
    enum CompressorError: Errorable {
        case compressionFailed
        case decompressionFailed
        case contentDataConversionFailed

        var printsHelp: Bool { false }
        var errorDescription: String? { localizedDescription }
    }
}
