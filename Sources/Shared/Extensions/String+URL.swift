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
}
