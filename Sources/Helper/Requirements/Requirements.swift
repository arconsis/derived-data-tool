//
//  Requirements.swift
//
//
//  Created by Moritz Ellerbrock on 03.05.23.
//

import Foundation
import Shared

enum RequirementsError: Errorable {
    case requirementsNotMet

    var printsHelp: Bool { true }
}

public enum Requirements {
    public static func check(verbose _: Bool = false) async throws {
        let bash = Bash()
        let xcrun = await bash.run("xcrun", with: ["--version"])
        try xcrun.throwError()

        let git = await bash.run("git", with: ["rev-parse", "--show-toplevel"])
        try git.throwError()
    }
}
