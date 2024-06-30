//
//  RawXCResult.swift
//
//
//  Created by Moritz Ellerbrock on 23.05.23.
//

import Foundation

// MARK: - TargetReport

public struct RawXCResult: Codable {
    let type: SupertypeClass
    let actions: Actions
    let issues: TargetReportIssues
    let metadataRef: MetadataRefClass
    let metrics: ActionResultMetrics

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case actions, issues, metadataRef, metrics
    }
}

// MARK: - Actions

struct Actions: Codable {
    let type: SupertypeClass
    let values: [ActionsValue]

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case values = "_values"
    }
}

// MARK: - SupertypeClass

struct SupertypeClass: Codable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name = "_name"
    }
}

// MARK: - ActionsValue

struct ActionsValue: Codable {
    let type: SupertypeClass
    let actionResult: ActionResult
    let buildResult: BuildResult
    let endedTime: ID
    let runDestination: RunDestination
    let schemeCommandName, schemeTaskName, startedTime: ID
    let title, testPlanName: ID?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case actionResult, buildResult, endedTime, runDestination, schemeCommandName, schemeTaskName, startedTime, title, testPlanName
    }
}

// MARK: - ActionResult

struct ActionResult: Codable {
    let type: SupertypeClass
    let coverage: ActionResultCoverage
    let issues: ActionResultIssues
    let metrics: ActionResultMetrics
    let resultName, status: ID
    let diagnosticsRef: DiagnosticsRefClass?
    let logRef, testsRef: MetadataRefClass?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case coverage, issues, metrics, resultName, status, diagnosticsRef, logRef, testsRef
    }
}

// MARK: - ActionResultCoverage

struct ActionResultCoverage: Codable {
    let type: SupertypeClass
    let archiveRef: DiagnosticsRefClass?
    let hasCoverageData: ID?
    let reportRef: DiagnosticsRefClass?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case archiveRef, hasCoverageData, reportRef
    }
}

// MARK: - DiagnosticsRefClass

struct DiagnosticsRefClass: Codable {
    let type: SupertypeClass
    let id: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case id
    }
}

// MARK: - ID

struct ID: Codable {
    let type: SupertypeClass
    let value: String

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case value = "_value"
    }
}

// MARK: - ActionResultIssues

struct ActionResultIssues: Codable {
    let type: SupertypeClass
    let testFailureSummaries: TestFailureSummaries?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case testFailureSummaries
    }
}

// MARK: - TestFailureSummaries

struct TestFailureSummaries: Codable {
    let type: SupertypeClass
    let values: [TestFailureSummariesValue]

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case values = "_values"
    }
}

// MARK: - TestFailureSummariesValue

struct TestFailureSummariesValue: Codable {
    let type: PurpleType
    let documentLocationInCreatingWorkspace: DocumentLocationInCreatingWorkspace
    let issueType, message, testCaseName: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case documentLocationInCreatingWorkspace, issueType, message, testCaseName
    }
}

// MARK: - DocumentLocationInCreatingWorkspace

struct DocumentLocationInCreatingWorkspace: Codable {
    let type: SupertypeClass
    let concreteTypeName, url: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case concreteTypeName, url
    }
}

// MARK: - PurpleType

struct PurpleType: Codable {
    let name: String
    let supertype: SupertypeClass

    enum CodingKeys: String, CodingKey {
        case name = "_name"
        case supertype = "_supertype"
    }
}

// MARK: - MetadataRefClass

struct MetadataRefClass: Codable {
    let type: SupertypeClass
    let id: ID
    let targetType: TargetType

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case id, targetType
    }
}

// MARK: - TargetType

struct TargetType: Codable {
    let type: SupertypeClass
    let name: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case name
    }
}

// MARK: - ActionResultMetrics

struct ActionResultMetrics: Codable {
    let type: SupertypeClass
    let testsCount, testsFailedCount, testsSkippedCount, warningCount: ID?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case testsCount, testsFailedCount, testsSkippedCount, warningCount
    }
}

// MARK: - BuildResult

struct BuildResult: Codable {
    let type: SupertypeClass
    let coverage: BuildResultCoverage
    let issues: BuildResultIssues
    let logRef: MetadataRefClass
    let metrics: BuildResultMetrics
    let resultName, status: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case coverage, issues, logRef, metrics, resultName, status
    }
}

// MARK: - BuildResultCoverage

struct BuildResultCoverage: Codable {
    let type: SupertypeClass

    enum CodingKeys: String, CodingKey {
        case type = "_type"
    }
}

// MARK: - BuildResultIssues

struct BuildResultIssues: Codable {
    let type: SupertypeClass
    let warningSummaries: WarningSummaries?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case warningSummaries
    }
}

// MARK: - WarningSummaries

struct WarningSummaries: Codable {
    let type: SupertypeClass
    let values: [WarningSummariesValue]

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case values = "_values"
    }
}

// MARK: - WarningSummariesValue

struct WarningSummariesValue: Codable {
    let type: SupertypeClass
    let documentLocationInCreatingWorkspace: DocumentLocationInCreatingWorkspace?
    let issueType, message: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case documentLocationInCreatingWorkspace, issueType, message
    }
}

// MARK: - BuildResultMetrics

struct BuildResultMetrics: Codable {
    let type: SupertypeClass
    let warningCount: ID?

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case warningCount
    }
}

// MARK: - RunDestination

struct RunDestination: Codable {
    let type: SupertypeClass
    let displayName: ID
    let localComputerRecord: Record
    let targetArchitecture: ID
    let targetDeviceRecord: Record
    let targetSDKRecord: TargetSDKRecord

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case displayName, localComputerRecord, targetArchitecture, targetDeviceRecord, targetSDKRecord
    }
}

// MARK: - Record

struct Record: Codable {
    let type: SupertypeClass
    let busSpeedInMHz, cpuCount: ID
    let cpuKind: ID?
    let cpuSpeedInMHz, identifier, isConcreteDevice, logicalCPUCoresPerPackage: ID
    let modelCode, modelName, modelUTI, name: ID
    let nativeArchitecture, operatingSystemVersion, operatingSystemVersionWithBuildNumber, physicalCPUCoresPerPackage: ID
    let platformRecord: PlatformRecord
    let ramSizeInMegabytes: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case busSpeedInMHz, cpuCount, cpuKind, cpuSpeedInMHz, identifier, isConcreteDevice, logicalCPUCoresPerPackage, modelCode, modelName, modelUTI, name, nativeArchitecture, operatingSystemVersion, operatingSystemVersionWithBuildNumber, physicalCPUCoresPerPackage, platformRecord, ramSizeInMegabytes
    }
}

// MARK: - PlatformRecord

struct PlatformRecord: Codable {
    let type: SupertypeClass
    let identifier, userDescription: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case identifier, userDescription
    }
}

// MARK: - TargetSDKRecord

struct TargetSDKRecord: Codable {
    let type: SupertypeClass
    let identifier, name, operatingSystemVersion: ID

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case identifier, name, operatingSystemVersion
    }
}

// MARK: - TargetReportIssues

struct TargetReportIssues: Codable {
    let type: SupertypeClass
    let testFailureSummaries: TestFailureSummaries
    let warningSummaries: WarningSummaries

    enum CodingKeys: String, CodingKey {
        case type = "_type"
        case testFailureSummaries, warningSummaries
    }
}
