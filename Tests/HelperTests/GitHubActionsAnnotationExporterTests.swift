//
//  GitHubActionsAnnotationExporterTests.swift
//
//
//  Created by Auto-Claude on 02.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class GitHubActionsAnnotationExporterTests: XCTestCase {
    var exporter: GitHubActionsAnnotationExporter!

    override func setUp() {
        super.setUp()
        exporter = GitHubActionsAnnotationExporter()
    }

    override func tearDown() {
        exporter = nil
        super.tearDown()
    }

    // MARK: - Basic Formatting Tests

    func testFormatAnnotations_SingleFailedResult() throws {
        let result = Self.makeValidationResult(
            targetName: "MyApp",
            actualCoverage: 0.65,
            requiredThreshold: 0.75,
            passed: false,
            filePath: "Sources/MyApp/App.swift"
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("::error"))
        XCTAssertTrue(output.contains("file=Sources/MyApp/App.swift"))
        XCTAssertTrue(output.contains("line=1"))
        XCTAssertTrue(output.contains("Coverage 65.00%"))
        XCTAssertTrue(output.contains("threshold 0.75%"))
        XCTAssertTrue(output.contains("MyApp"))
    }

    func testFormatAnnotations_MultipleFailedResults() throws {
        let results = [
            Self.makeValidationResult(
                targetName: "AppTarget",
                actualCoverage: 0.60,
                requiredThreshold: 0.75,
                passed: false,
                filePath: "Sources/AppTarget/Main.swift"
            ),
            Self.makeValidationResult(
                targetName: "NetworkTarget",
                actualCoverage: 0.50,
                requiredThreshold: 0.80,
                passed: false,
                filePath: "Sources/NetworkTarget/Client.swift"
            )
        ]

        let output = exporter.formatAnnotations(from: results)
        let lines = output.split(separator: "\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(output.contains("AppTarget"))
        XCTAssertTrue(output.contains("NetworkTarget"))
        XCTAssertTrue(output.contains("60.00%"))
        XCTAssertTrue(output.contains("50.00%"))
    }

    func testFormatAnnotations_AllPassedResults() throws {
        let results = [
            Self.makeValidationResult(
                targetName: "AppTarget",
                actualCoverage: 0.85,
                requiredThreshold: 0.75,
                passed: true
            ),
            Self.makeValidationResult(
                targetName: "NetworkTarget",
                actualCoverage: 0.90,
                requiredThreshold: 0.80,
                passed: true
            )
        ]

        let output = exporter.formatAnnotations(from: results)

        XCTAssertTrue(output.isEmpty)
    }

    func testFormatAnnotations_MixedResults() throws {
        let results = [
            Self.makeValidationResult(
                targetName: "PassTarget",
                actualCoverage: 0.85,
                requiredThreshold: 0.75,
                passed: true
            ),
            Self.makeValidationResult(
                targetName: "FailTarget",
                actualCoverage: 0.60,
                requiredThreshold: 0.75,
                passed: false
            )
        ]

        let output = exporter.formatAnnotations(from: results)
        let lines = output.split(separator: "\n")

        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(output.contains("FailTarget"))
        XCTAssertFalse(output.contains("PassTarget"))
    }

    // MARK: - File Path Handling Tests

    func testFormatAnnotations_WithFilePath() throws {
        let result = Self.makeValidationResult(
            targetName: "MyTarget",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false,
            filePath: "Sources/MyTarget/File.swift"
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("file=Sources/MyTarget/File.swift"))
    }

    func testFormatAnnotations_WithoutFilePath() throws {
        let result = Self.makeValidationResult(
            targetName: "MyTarget",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false,
            filePath: nil
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("file=MyTarget"))
        XCTAssertFalse(output.contains("Sources/"))
    }

    // MARK: - Annotation Limit Tests

    func testFormatAnnotations_ExactlyAtLimit() throws {
        let results = (0..<10).map { index in
            Self.makeValidationResult(
                targetName: "Target\(index)",
                actualCoverage: 0.50,
                requiredThreshold: 0.75,
                passed: false
            )
        }

        let output = exporter.formatAnnotations(from: results)
        let lines = output.split(separator: "\n")

        XCTAssertEqual(lines.count, 10)
        XCTAssertFalse(output.contains("additional threshold failure"))
    }

    func testFormatAnnotations_ExceedsLimit() throws {
        let results = (0..<15).map { index in
            Self.makeValidationResult(
                targetName: "Target\(index)",
                actualCoverage: 0.50,
                requiredThreshold: 0.75,
                passed: false
            )
        }

        let output = exporter.formatAnnotations(from: results)
        let lines = output.split(separator: "\n")

        // Should be 10 error annotations + 1 warning about truncation
        XCTAssertEqual(lines.count, 11)
        XCTAssertTrue(output.contains("::warning::"))
        XCTAssertTrue(output.contains("5 additional threshold failure"))
        XCTAssertTrue(output.contains("GitHub Actions limit: 10"))
    }

    func testFormatAnnotations_ExceedsLimitBy1() throws {
        let results = (0..<11).map { index in
            Self.makeValidationResult(
                targetName: "Target\(index)",
                actualCoverage: 0.50,
                requiredThreshold: 0.75,
                passed: false
            )
        }

        let output = exporter.formatAnnotations(from: results)

        XCTAssertTrue(output.contains("1 additional threshold failure"))
    }

    func testFormatAnnotations_SignificantlyExceedsLimit() throws {
        let results = (0..<50).map { index in
            Self.makeValidationResult(
                targetName: "Target\(index)",
                actualCoverage: 0.50,
                requiredThreshold: 0.75,
                passed: false
            )
        }

        let output = exporter.formatAnnotations(from: results)
        let lines = output.split(separator: "\n")

        XCTAssertEqual(lines.count, 11)
        XCTAssertTrue(output.contains("40 additional threshold failure"))
    }

    // MARK: - Message Formatting Tests

    func testFormatAnnotations_FormatsPercentagesCorrectly() throws {
        let result = Self.makeValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.6789,
            requiredThreshold: 0.8523,
            passed: false
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("67.89%"))
        XCTAssertTrue(output.contains("0.85%"))
    }

    func testFormatAnnotations_HandlesZeroCoverage() throws {
        let result = Self.makeValidationResult(
            targetName: "UncoveredTarget",
            actualCoverage: 0.0,
            requiredThreshold: 0.50,
            passed: false
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("Coverage 0.00%"))
        XCTAssertTrue(output.contains("threshold 0.50%"))
    }

    func testFormatAnnotations_HandlesVeryHighThreshold() throws {
        let result = Self.makeValidationResult(
            targetName: "StrictTarget",
            actualCoverage: 0.95,
            requiredThreshold: 0.99,
            passed: false
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("Coverage 95.00%"))
        XCTAssertTrue(output.contains("threshold 0.99%"))
    }

    // MARK: - Annotation Format Tests

    func testFormatAnnotations_UsesErrorAnnotationType() throws {
        let result = Self.makeValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.hasPrefix("::error"))
        XCTAssertFalse(output.contains("::warning file="))
    }

    func testFormatAnnotations_UsesLineNumber1() throws {
        let result = Self.makeValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false,
            filePath: "TestFile.swift"
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("line=1"))
    }

    func testFormatAnnotations_ContainsAllRequiredComponents() throws {
        let result = Self.makeValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false,
            filePath: "TestFile.swift"
        )

        let output = exporter.formatAnnotations(from: [result])

        // Should match format: ::error file={name},line={line}::{message}
        XCTAssertTrue(output.contains("::error"))
        XCTAssertTrue(output.contains("file="))
        XCTAssertTrue(output.contains("line="))
        XCTAssertTrue(output.contains("::"))
        XCTAssertTrue(output.contains("Coverage"))
    }

    // MARK: - Empty Input Tests

    func testFormatAnnotations_EmptyResults() throws {
        let output = exporter.formatAnnotations(from: [])

        XCTAssertTrue(output.isEmpty)
    }

    // MARK: - Edge Cases

    func testFormatAnnotations_TargetNameWithSpecialCharacters() throws {
        let result = Self.makeValidationResult(
            targetName: "My-App_Target.Core",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("My-App_Target.Core"))
    }

    func testFormatAnnotations_FilePathWithSpaces() throws {
        let result = Self.makeValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.50,
            requiredThreshold: 0.75,
            passed: false,
            filePath: "Sources/My Module/File.swift"
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("file=Sources/My Module/File.swift"))
    }

    func testFormatAnnotations_VerySmallCoverageGap() throws {
        let result = Self.makeValidationResult(
            targetName: "AlmostThere",
            actualCoverage: 0.7499,
            requiredThreshold: 0.75,
            passed: false
        )

        let output = exporter.formatAnnotations(from: [result])

        XCTAssertTrue(output.contains("74.99%"))
        XCTAssertTrue(output.contains("0.75%"))
    }

    // MARK: - Integration Tests

    func testFormatAnnotations_RealisticScenario() throws {
        let results = [
            Self.makeValidationResult(
                targetName: "Core",
                actualCoverage: 0.92,
                requiredThreshold: 0.90,
                passed: true
            ),
            Self.makeValidationResult(
                targetName: "Networking",
                actualCoverage: 0.78,
                requiredThreshold: 0.85,
                passed: false,
                filePath: "Sources/Networking/Client.swift"
            ),
            Self.makeValidationResult(
                targetName: "UI",
                actualCoverage: 0.65,
                requiredThreshold: 0.70,
                passed: false,
                filePath: "Sources/UI/Views.swift"
            ),
            Self.makeValidationResult(
                targetName: "Utils",
                actualCoverage: 0.88,
                requiredThreshold: 0.80,
                passed: true
            )
        ]

        let output = exporter.formatAnnotations(from: results)
        let lines = output.split(separator: "\n")

        // Should only have 2 annotations for the failed targets
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(output.contains("Networking"))
        XCTAssertTrue(output.contains("UI"))
        XCTAssertFalse(output.contains("Core"))
        XCTAssertFalse(output.contains("Utils"))
    }
}

// MARK: - Test Helpers

extension GitHubActionsAnnotationExporterTests {
    static func makeValidationResult(
        targetName: String,
        actualCoverage: Double,
        requiredThreshold: Double,
        passed: Bool,
        filePath: String? = nil
    ) -> ThresholdValidationResult {
        ThresholdValidationResult(
            targetName: targetName,
            actualCoverage: actualCoverage,
            requiredThreshold: requiredThreshold,
            passed: passed,
            filePath: filePath
        )
    }
}
