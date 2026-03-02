#!/usr/bin/env swift

import Foundation

// This script creates a sample JUnit XML output for manual verification
// It simulates what the JUnitXMLExporter would generate

let timestamp = ISO8601DateFormatter().string(from: Date())

let xml = """
<?xml version="1.0" encoding="UTF-8"?>
<testsuites id="coverage-\(timestamp)" name="Coverage Report" tests="6" failures="2" time="0.0" timestamp="\(timestamp)">
    <testsuite id="MyApp" name="MyApp" tests="2" skipped="0" failures="1" errors="0" timestamp="\(timestamp)" time="0.0">
        <properties>
            <property name="coverage" value="65.00"/>
            <property name="coveredLines" value="650"/>
            <property name="executableLines" value="1000"/>
        </properties>
        <testcase name="threshold-validation" classname="MyApp" time="0.0">
            <failure message="Coverage threshold not met: 65.00% &lt; 80.00%" type="CoverageThresholdFailure">
Target: MyApp
Actual Coverage: 65.00%
Required Threshold: 80.00%
            </failure>
        </testcase>
        <testcase name="ViewController.swift" classname="MyApp" time="0.0">
            <properties>
                <property name="coverage" value="75.00"/>
                <property name="coveredLines" value="75"/>
                <property name="executableLines" value="100"/>
            </properties>
        </testcase>
        <testcase name="AppDelegate.swift" classname="MyApp" time="0.0">
            <properties>
                <property name="coverage" value="55.00"/>
                <property name="coveredLines" value="55"/>
                <property name="executableLines" value="100"/>
            </properties>
        </testcase>
    </testsuite>
    <testsuite id="MyFramework" name="MyFramework" tests="3" skipped="0" failures="1" errors="0" timestamp="\(timestamp)" time="0.0">
        <properties>
            <property name="coverage" value="70.00"/>
            <property name="coveredLines" value="700"/>
            <property name="executableLines" value="1000"/>
        </properties>
        <testcase name="threshold-validation" classname="MyFramework" time="0.0">
            <failure message="Coverage threshold not met: 70.00% &lt; 75.00%" type="CoverageThresholdFailure">
Target: MyFramework
Actual Coverage: 70.00%
Required Threshold: 75.00%
            </failure>
        </testcase>
        <testcase name="Helper.swift" classname="MyFramework" time="0.0">
            <properties>
                <property name="coverage" value="80.00"/>
                <property name="coveredLines" value="80"/>
                <property name="executableLines" value="100"/>
            </properties>
        </testcase>
        <testcase name="Utilities.swift" classname="MyFramework" time="0.0">
            <properties>
                <property name="coverage" value="60.00"/>
                <property name="coveredLines" value="60"/>
                <property name="executableLines" value="100"/>
            </properties>
        </testcase>
    </testsuite>
    <testsuite id="MyTests" name="MyTests" tests="1" skipped="0" failures="0" errors="0" timestamp="\(timestamp)" time="0.0">
        <properties>
            <property name="coverage" value="100.00"/>
            <property name="coveredLines" value="100"/>
            <property name="executableLines" value="100"/>
        </properties>
        <testcase name="TestHelper.swift" classname="MyTests" time="0.0">
            <properties>
                <property name="coverage" value="100.00"/>
                <property name="coveredLines" value="100"/>
                <property name="executableLines" value="100"/>
            </properties>
        </testcase>
    </testsuite>
</testsuites>
"""

print("=== Sample JUnit XML Coverage Report ===\n")
print(xml)

// Validate basic structure
let validations = [
    ("XML declaration", xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")),
    ("Root testsuites element", xml.contains("<testsuites") && xml.contains("</testsuites>")),
    ("Test suite elements", xml.contains("<testsuite") && xml.contains("</testsuite>")),
    ("Test case elements", xml.contains("<testcase")),
    ("Coverage properties", xml.contains("<property name=\"coverage\"")),
    ("Threshold failures", xml.contains("<failure") && xml.contains("CoverageThresholdFailure")),
    ("Proper XML escaping", xml.contains("&lt;") && !xml.contains("< 80")),
    ("Timestamps", xml.contains("timestamp=\""))
]

print("\n=== Validation Results ===\n")
var allPassed = true
for (name, passed) in validations {
    let status = passed ? "✅ PASS" : "❌ FAIL"
    print("\(status): \(name)")
    if !passed { allPassed = false }
}

print("\n=== Summary ===")
print("All validations: \(allPassed ? "✅ PASSED" : "❌ FAILED")")
print("\nThis XML demonstrates:")
print("  • Coverage targets mapped to test suites (MyApp, MyFramework, MyTests)")
print("  • Individual files mapped to test cases")
print("  • Threshold failures shown as test failures")
print("  • Coverage statistics in properties")
print("  • Proper XML structure compatible with CI systems")
