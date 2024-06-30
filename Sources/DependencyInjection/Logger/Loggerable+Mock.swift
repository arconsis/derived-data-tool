//
//  Loggerable+Mock.swift
//
//
//  Created by Moritz Ellerbrock on 07.06.23.
//

import Foundation

struct MockedLogger: Loggerable {
    var verbose: Bool = false

    static func log(_: LogLevel, message _: String, fileId _: String) {}
}
