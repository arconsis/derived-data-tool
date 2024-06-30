//
//  Config+Requirements.swift
//
//
//  Created by Moritz Ellerbrock on 11.03.24.
//

import Foundation

public extension Config {
    enum Requirements {
        case currentReportLocation
        case reportTypeLocation
        case archiveLocation
        case githubExporterSettings
        case archiverSettings
        case htmlExporterSettings
        case slackSettings
    }

    enum RequirementsError: Error {
        case missingCurrentReportLocation
        case missingReportTypeLocation
        case missingArchiveLocation
        case missingGithubExporterSettings
        case missingArchiverSettings
        case missingHtmlExporterSettings
        case missingSlackSettings
    }

    func checkRequierements(_ fields: [Requirements]) throws {
        for field in fields {
            switch field {
            case .currentReportLocation:
                guard let _ = locations?.currentReport else {
                    throw RequirementsError.missingCurrentReportLocation
                }
            case .reportTypeLocation:
                guard let _ = locations?.reportType else {
                    throw RequirementsError.missingReportTypeLocation
                }
            case .archiveLocation:
                guard let _ = locations?.archive else {
                    throw RequirementsError.missingArchiveLocation
                }
            case .githubExporterSettings:
                guard let _ = try? settings(.githubExporter) else {
                    throw RequirementsError.missingGithubExporterSettings
                }
            case .archiverSettings:
                guard let _ = try? settings(.archiver) else {
                    throw RequirementsError.missingArchiverSettings
                }
            case .htmlExporterSettings:
                guard let _ = try? settings(.htmlExporter) else {
                    throw RequirementsError.missingHtmlExporterSettings
                }
            case .slackSettings:
                guard let _ = try? settings(.slack) else {
                    throw RequirementsError.missingSlackSettings
                }
            }
        }
    }
}
