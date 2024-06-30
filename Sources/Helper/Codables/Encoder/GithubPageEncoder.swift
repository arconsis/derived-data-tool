//
//  GithubPageEncoder.swift
//
//
//  Created by Moritz Ellerbrock on 10.05.23.
//

import Foundation
import Shared

struct GithubPageEncoder: TestReportEncoder {
    func encode(_: CoverageReport) throws -> String {
        ""
    }

    func encode(_: TargetReports) throws -> String {
        ""
    }

    func encode(_: File) throws -> String {
        ""
    }

    func encode(_: Target) throws -> String {
        ""
    }
}
