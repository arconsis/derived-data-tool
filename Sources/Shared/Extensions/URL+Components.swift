//
//  URL+Components.swift
//
//
//  Created by Moritz Ellerbrock on 04.05.23.
//

import Foundation

public extension URL {
    enum URLExtensionError: Error {
        case doesNotContainSuffix(String)
    }

    init(with filePath: String) {
        if #available(macOS 13.0, *) {
            self.init(filePath: filePath)
        } else {
            self.init(fileURLWithPath: filePath)
        }
    }

    init?(with filePath: String?) {
        guard let nonOptionalFilePath = filePath else {
            return nil
        }
        self.init(with: nonOptionalFilePath)
    }

    func appending(pathComponent: String, isDirectory: Bool = false) -> Self {
        if #available(macOS 13.0, *) {
            return self.appending(path: pathComponent, directoryHint: isDirectory ? .isDirectory : .notDirectory)
        } else {
            return appendingPathComponent(pathComponent, isDirectory: isDirectory)
        }
    }

    var fullPath: String {
        return fullPathWithPercentEncoding.removingPercentEncoding ?? ""
    }

    var fullPathWithPercentEncoding: String {
        let path = self.absoluteString
        let cleanPath = path.replacingOccurrences(of: "file://", with: "")
        return cleanPath
    }

    mutating func replaceFileExtension(with newFileExtension: String) {
        if let fileExtension = lastPathComponent.split(separator: ".").last {
            let fullpath = fullPath.replacingOccurrences(of: fileExtension, with: newFileExtension)
            self = URL(with: fullpath)
        }
    }
}
