//
//  Compareify.swift
//
//
//  Created by Moritz Ellerbrock on 07.05.23.
//

import Foundation
import Shared

protocol Compareify {
    var verbose: Bool { get }
    var configFilePath: String? { get }
    var reportDirectory: String? { get }
    func reportsUrl() async -> URL?
    func outputUrl() async -> URL?
    var config: Config? { get }
    func filterReports() async -> [String]
    func retrieveConfig() async -> Config?
    func createWebsite(with current: JSONReport?, previous: JSONReport?) -> String
}

private func createWebsite(with _: JSONReport?, previous _: JSONReport?) -> String {
    //        HTMLGenerator.
    fatalError("GENERATE html-file content")
}
