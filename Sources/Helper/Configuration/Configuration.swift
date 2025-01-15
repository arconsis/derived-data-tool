//
//  Configuration.swift
//
//
//  Created by Moritz Ellerbrock on 03.05.23.
//

import DependencyInjection
import Foundation
import Shared

public enum ConfigFactory {
    static func retrieve(at customDirectory: URL? = nil) async throws -> Config {
        @Injected(\.logger) var logger
        do {
            let fileHandler = FileHandler()
            let currentDirectory: URL = {
                if let customDirectory {
                    return customDirectory
                } else {
                    return fileHandler.getCurrentDirectoryUrl()
                }
            }()

            let configFile = await fileHandler.findFiles(filename: ".xcrtool.yml", at: currentDirectory).value?.first

            guard let configFile else {
                throw ErrorFactory.failing(error: ConfigFactoryError.noConfigFileFoundAt(currentDirectory.absoluteString))
            }
            let configData = try Data(contentsOf: configFile)
            let config = try ConfigGenerator.decode(Config.self, from: configData)
            return config
        } catch {
            logger.error(error)
            if let recognisedError = error as? any Errorable {
                throw recognisedError
            } else {
                throw ErrorFactory.intern(error: error)
            }
        }
    }

    public static func getConfig(at customDirectory: URL? = nil) async throws -> Config {
        if let customDirectory, let configAtCustomPath = try? await ConfigFactory.retrieve(at: customDirectory) {
            return configAtCustomPath
        } else if let configAtCurrentLocation = try? await ConfigFactory.retrieve() {
            return configAtCurrentLocation
        } else {
            let gitRootDirectoryResult = await FileHandler().getGitRootDirectory()
            switch gitRootDirectoryResult {
                case .success(let rootDirectory):
                    return try await ConfigFactory.retrieve(at: rootDirectory)
                case .failure(let error):
                    throw error
            }
        }
    }

    public static func save(_ config: Config, at directory: URL, overwriteExsisting _: Bool = false) async throws {
        @Injected(\.logger) var logger
        do {
            let fileHandler = FileHandler()

            let data = try ConfigGenerator.encode(config)

            try fileHandler.writeData(data, at: directory.appending(pathComponent: ".xcrtool.yml"))
        } catch {
            logger.error(error)
            if let recognisedError = error as? any Errorable {
                throw recognisedError
            } else {
                throw ErrorFactory.intern(error: error)
            }
        }
    }
}

extension ConfigFactory {
    enum ConfigFactoryError: Errorable {
        case noConfigFileFoundAt(String)

        var printsHelp: Bool { false }
        var errorDescription: String? { "Config file not found. It is needed for any furhter operation." }
    }
}
