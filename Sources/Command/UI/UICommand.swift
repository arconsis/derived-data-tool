//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 22.06.24.
//

import ArgumentParser
import Foundation
import UIComponents
import SwiftTUI
import Combine


public final class UICommand: ParsableCommand {
    public static let configuration = CommandConfiguration(commandName: "ui", abstract: "Use the TUI version")


    public init() {}

    public func run() throws {
        var isDone: Bool = false
        let view = MyTerminalView(text: "Hello Moe") { _ in
            isDone = true
        }
        let app = Application(rootView: view)
        app.start()

        sleep(100)
        while isDone {
            print("running")
        }

        while !isDone {
            print("running")
        }
    }
}
