//
//  GitHubActionsAnnotationsTests.swift
//
//
//  Created by Moritz Ellerbrock on 01.03.26.
//

import Foundation
@testable import Helper
@testable import Shared
import XCTest

final class GitHubActionsAnnotationsTests: XCTestCase {
    var formatter: GitHubActionsAnnotations!

    override func setUp() {
        super.setUp()
        formatter = GitHubActionsAnnotations()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    // MARK: - format Tests

    func testFormat_ReturnsEmptyStringWhenNoResults() throws {
        let results: [ThresholdValidationResult] = []
        let output = formatter.format(results: results)

        XCTAssertEqual(output, "")
    }

    func testFormat_ReturnsEmptyStringWhenAllResultsPass() throws {
        let results = [
            ThresholdValidationResult(
                targetName: "TargetA",
                actualCoverage: 0.85,
                requiredThreshold: 80.0,
                passed: true
            ),
            ThresholdValidationResult(
                targetName: "TargetB",
                actualCoverage: 0.90,
                requiredThreshold: 85.0,
                passed: true
            )
        ]

        let output = formatter.format(results: results)

        XCTAssertEqual(output, "")
    }

    func testFormat_ReturnsSingleAnnotationForOneFailedResult() throws {
        let result = ThresholdValidationResult(
            targetName: "MyTarget",
            actualCoverage: 0.65,
            requiredThreshold: 75.0,
            passed: false
        )

        let output = formatter.format(results: [result])

        XCTAssertEqual(
            output,
            "::error file=MyTarget,line=1::Coverage below threshold (65.00% < 75.00%)"
        )
    }

    func testFormat_ReturnsMultipleAnnotationsForMultipleFailedResults() throws {
        let results = [
            ThresholdValidationResult(
                targetName: "TargetA",
                actualCoverage: 0.60,
                requiredThreshold: 70.0,
                passed: false
            ),
            ThresholdValidationResult(
                targetName: "TargetB",
                actualCoverage: 0.50,
                requiredThreshold: 80.0,
                passed: false
            )
        ]

        let output = formatter.format(results: results)
        let lines = output.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(
            lines[0],
            "::error file=TargetA,line=1::Coverage below threshold (60.00% < 70.00%)"
        )
        XCTAssertEqual(
            lines[1],
            "::error file=TargetB,line=1::Coverage below threshold (50.00% < 80.00%)"
        )
    }

    func testFormat_OnlyIncludesFailedResults() throws {
        let results = [
            ThresholdValidationResult(
                targetName: "PassingTarget",
                actualCoverage: 0.85,
                requiredThreshold: 80.0,
                passed: true
            ),
            ThresholdValidationResult(
                targetName: "FailingTarget",
                actualCoverage: 0.65,
                requiredThreshold: 75.0,
                passed: false
            ),
            ThresholdValidationResult(
                targetName: "AnotherPassingTarget",
                actualCoverage: 0.95,
                requiredThreshold: 90.0,
                passed: true
            )
        ]

        let output = formatter.format(results: results)
        let lines = output.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("FailingTarget"))
        XCTAssertFalse(output.contains("PassingTarget"))
        XCTAssertFalse(output.contains("AnotherPassingTarget"))
    }

    // MARK: - Annotation Format Tests

    func testFormat_CorrectlyFormatsPercentages() throws {
        let result = ThresholdValidationResult(
            targetName: "Target",
            actualCoverage: 0.6543,  // Should format to 65.43%
            requiredThreshold: 75.5678,  // Should format to 75.57%
            passed: false
        )

        let output = formatter.format(results: [result])

        XCTAssertTrue(output.contains("65.43%"))
        XCTAssertTrue(output.contains("75.57%"))
    }

    func testFormat_HandlesZeroCoverage() throws {
        let result = ThresholdValidationResult(
            targetName: "NoCodeCovered",
            actualCoverage: 0.0,
            requiredThreshold: 50.0,
            passed: false
        )

        let output = formatter.format(results: [result])

        XCTAssertEqual(
            output,
            "::error file=NoCodeCovered,line=1::Coverage below threshold (0.00% < 50.00%)"
        )
    }

    func testFormat_HandlesNearFullCoverage() throws {
        let result = ThresholdValidationResult(
            targetName: "AlmostThere",
            actualCoverage: 0.9999,
            requiredThreshold: 100.0,
            passed: false
        )

        let output = formatter.format(results: [result])

        XCTAssertTrue(output.contains("99.99%"))
        XCTAssertTrue(output.contains("100.00%"))
    }

    func testFormat_HandlesTargetNamesWithSpecialCharacters() throws {
        let result = ThresholdValidationResult(
            targetName: "My-Target_v2.0",
            actualCoverage: 0.60,
            requiredThreshold: 75.0,
            passed: false
        )

        let output = formatter.format(results: [result])

        XCTAssertTrue(output.contains("file=My-Target_v2.0"))
    }

    func testFormat_IncludesCorrectGitHubActionsFormat() throws {
        let result = ThresholdValidationResult(
            targetName: "TestTarget",
            actualCoverage: 0.50,
            requiredThreshold: 75.0,
            passed: false
        )

        let output = formatter.format(results: [result])

        // Verify the GitHub Actions annotation format
        XCTAssertTrue(output.hasPrefix("::error"))
        XCTAssertTrue(output.contains("file=TestTarget"))
        XCTAssertTrue(output.contains("line=1"))
        XCTAssertTrue(output.contains("Coverage below threshold"))
    }

    func testFormat_MaintainsOrderOfResults() throws {
        let results = [
            ThresholdValidationResult(
                targetName: "First",
                actualCoverage: 0.60,
                requiredThreshold: 70.0,
                passed: false
            ),
            ThresholdValidationResult(
                targetName: "Second",
                actualCoverage: 0.50,
                requiredThreshold: 80.0,
                passed: false
            ),
            ThresholdValidationResult(
                targetName: "Third",
                actualCoverage: 0.40,
                requiredThreshold: 90.0,
                passed: false
            )
        ]

        let output = formatter.format(results: results)
        let lines = output.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].contains("First"))
        XCTAssertTrue(lines[1].contains("Second"))
        XCTAssertTrue(lines[2].contains("Third"))
    }

    func testFormat_HandlesLargeNumberOfFailures() throws {
        let results = (0..<10).map { index in
            ThresholdValidationResult(
                targetName: "Target\(index)",
                actualCoverage: 0.50,
                requiredThreshold: 75.0,
                passed: false
            )
        }

        let output = formatter.format(results: results)
        let lines = output.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 10)
        for (index, line) in lines.enumerated() {
            XCTAssertTrue(line.contains("Target\(index)"))
        }
    }

    func testFormat_HandlesVerySmallPercentageDifferences() throws {
        let result = ThresholdValidationResult(
            targetName: "CloseCall",
            actualCoverage: 0.7499,  // 74.99%
            requiredThreshold: 75.0,  // 75.00%
            passed: false
        )

        let output = formatter.format(results: [result])

        XCTAssertTrue(output.contains("74.99%"))
        XCTAssertTrue(output.contains("75.00%"))
    }
}
