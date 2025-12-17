//
//  Tools.swift
//
//
//  Created by Moritz Ellerbrock on 23.05.23.
//

import DependencyInjection
import Foundation
import Shared


public typealias ToolsResult = Result<String, CCCLIError>
public final class Tools {
    let bash: Executing

    @Injected(\.logger) private var logger: Loggerable

    public init() {
        self.bash = Bash()
    }

    public func xccov(filePath: URL) async -> ToolsResult {
        let xccov: PredefinedBashCommands = .xccov(file: filePath)
        let output = await bash.run(xccov.command, with: xccov.arguments)
        logger.debug(output)
        return output
    }

    public func xccovTargetsOnly(filePath: URL) async -> ToolsResult {
        let xccov: PredefinedBashCommands = .xccovTargetsOnly(file: filePath)
        let output = await bash.run(xccov.command, with: xccov.arguments)
        logger.debug(output)
        return output
    }

    public func xcResultTool(filePath: URL) async -> ToolsResult {
        let xcresulttool: PredefinedBashCommands = .xcresulttool(file: filePath)
        let output = await bash.run(xcresulttool.command, with: xcresulttool.arguments)
        logger.debug(output)
        return output
    }
}
