//
//  FileHandler.swift
//
//
//  Created by Moritz Ellerbrock on 30.04.23.
//

import Compression
import DependencyInjection
import Foundation
import Shared


public typealias FileHandlerResult = Result<URL, CCCLIError>
public typealias FileHandlerResults = Result<[URL], CCCLIError>
public final class FileHandler {
    nonisolated(unsafe) private let fileManager: FileManager = .default

    let bash: Executing

    @Injected(\.logger) private var logger: Loggerable

    public init() {
        self.bash = Bash()
    }

    public func getCurrentDirectoryUrl() -> URL {
        URL(with: fileManager.currentDirectoryPath)
    }

    public func getGitRootDirectory() async -> FileHandlerResult {
        let gitRoot: PredefinedBashCommands = .gitRootDirectory
        let pathResult = await bash.run(gitRoot.command, with: gitRoot.arguments).modify { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        logger.debug(pathResult)
        return pathResult.convertToSingleUrl()
    }

    public func findXCResultfiles(at path: URL) async -> FileHandlerResults {
        let xcresult: PredefinedBashCommands = .findXCResultAt(path)
        let outputResult = await bash.run(xcresult.command, with: xcresult.arguments)
            .modify{ $0.nonOptionalSplitting(at: "\n") }

        logger.debug(outputResult)
        return outputResult.convertToUrl()
    }

    public func findFiles(at url: URL, with fileExtension: String) async -> FileHandlerResults {
        let findFiles: PredefinedBashCommands = .findFiles(url: url, fileExtension: fileExtension)
        let outputResult = await bash.run(findFiles.command, with: findFiles.arguments)
            .modify{ $0.nonOptionalSplitting(at: "\n") }

        logger.debug(outputResult)
        return outputResult.convertToUrl()
    }

    public func findFiles(at url: URL, with fileExtensions: [String]) async -> FileHandlerResults {
        let findFiles: PredefinedBashCommands = .findFilesWithExtensions(url: url, fileExtensions: fileExtensions)
        let outputResult = await bash.run(findFiles.command, with: findFiles.arguments)
            .modify{ $0.nonOptionalSplitting(at: "\n") }
        logger.debug(outputResult)
        return outputResult.convertToUrl()
    }

    public func findFiles(filename: String, at url: URL) async -> FileHandlerResults {
        let findFiles: PredefinedBashCommands = .findFile(filename: filename, url: url)
        let outputResult = await bash.run(findFiles.command, with: findFiles.arguments)
            .modify{ $0.nonOptionalSplitting(at: "\n") }

        logger.debug(outputResult)
        return outputResult.convertToUrl()
    }

    public func homeDirectory() async throws -> URL {
        if #available(macOS 13.0, *) {
            return URL.homeDirectory
        } else {
            guard let homeDirectory = URL(string: "~/") else {
                throw FileHandlerError.noOutputProvided
            }
            return homeDirectory
        }
    }

    /// Write file content to a file
    /// - Parameters:
    ///   - content: content of the file as `String`
    ///   - filename: filename of the resulting file as `String`
    ///   - path: optional path parameter if not provided the CWD is used
    public func writeContent(_ content: String, to filename: String, at path: URL? = nil, overwrite: Bool = false) throws {
        let workingDirectory = path ?? getCurrentDirectoryUrl()
        let outputFile = workingDirectory.appending(pathComponent: filename)

        try writeContent(content, at: outputFile, overwrite: overwrite)
    }

    public func writeContent(_ content: String, at url: URL, overwrite: Bool = false) throws {
        guard let data = content.data(using: .utf8) else {
            let error = FileHandlerError.stringToDataConversionFailed
            logger.error(error.localizedDescription)
            throw ErrorFactory.failing(error: error)
        }

        try writeData(data, at: url, overwrite: overwrite)
    }

    public func writeData(_ data: Data, to filename: String, at path: URL? = nil, overwrite: Bool = false) throws {
        let workingDirectory = path ?? getCurrentDirectoryUrl()
        let outputFile = workingDirectory.appending(pathComponent: filename)

        try writeData(data, at: outputFile, overwrite: overwrite)
    }

    public func writeData(_ data: Data, at url: URL, overwrite: Bool = false) throws {
        try deleteExistingFile(at: url, overwrite: overwrite)

        try createDirectory(at: url)

        try createFile(at: url, with: data)
    }

    public func deleteFile(_ filename: String, at path: URL? = nil) throws {
        let workingDirectory = path ?? getCurrentDirectoryUrl()
        let outputFileUrl = workingDirectory.appending(pathComponent: filename)
        try deleteFile(at: outputFileUrl)
    }

    public func deleteFile(at url: URL) throws {
        logger.debug(url.absoluteString, "does exist and will be deleted")
        try fileManager.trashItem(at: url, resultingItemURL: nil)
        logger.debug(url.absoluteString, "was deleted successfully")
    }

    private func deleteExistingFile(at url: URL, overwrite: Bool = false) throws {
        let outputFilePath = url.fullPath
        if fileManager.fileExists(atPath: outputFilePath) {
            if overwrite {
                try deleteFile(at: url)
            } else {
                logger.debug(outputFilePath, "File exists, but will not be overwritten")
                return
            }
        }
    }

    private func createDirectory(at url: URL) throws {
        logger.debug("Directory will be created:", url.fullPath)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        logger.debug("Directory", url.fullPath, "created successfully")
    }

    private func createFile(at url: URL, with inputData: Data) throws {
        let successfulWriteProcess = fileManager.createFile(atPath: url.fullPath, contents: inputData)
        guard successfulWriteProcess else {
            let error = FileHandlerError.failedWritingFileAt(url.fullPath)
            logger.error(error.localizedDescription)
            throw ErrorFactory.failing(error: error)
        }
    }
}

extension FileHandler {
    enum FileHandlerError: Errorable {
        case failedWritingFileAt(String)
        case locationRenameFailed
        case compressionFailed
        case decompressionFailed
        case stringToDataConversionFailed
        case noOutputProvided

        var printsHelp: Bool { false }
        var errorDescription: String { localizedDescription }
    }
}
