//
//  String+URL.swift
//
//
//  Created by Moritz Ellerbrock on 04.05.23.
//

import Foundation

public extension String {
    var filePathUrl: URL? {
        let url = URL(fileURLWithPath: self)
        return url.hasDirectoryPath ? nil : url
    }

    var directoryPathUrl: URL? {
        let url = URL(fileURLWithPath: self)
        return url
    }

    func ensureFilePath(defaultFileName: String) -> URL {
        if var url = URL(string: self) {
            let last = url.lastPathComponent
            let isDotDir = (last == "." || last == "..")
            // Purely syntactic check (no disk I/O): trailing slash means "directory-like"
            if url.hasDirectoryPath || isDotDir {
                url.appendPathComponent(defaultFileName)
                return url
            } else {
                return url
            }
        } else {
            return normalizedFilePath(defaultFileName: defaultFileName)
        }
    }

    func normalizedFilePath(defaultFileName: String) -> URL {
        // Expand ~
        let expanded = (self as NSString).expandingTildeInPath
        var url = URL(fileURLWithPath: expanded)

        // Treat "." and ".." as directory-like even without a trailing slash
        let last = url.lastPathComponent
        let isDotDir = (last == "." || last == "..")

        // Purely syntactic check (no disk I/O): trailing slash means "directory-like"
        if url.hasDirectoryPath || isDotDir {
            url.appendPathComponent(defaultFileName)
            return url
        } else {
            return url
        }
    }
}
