# CSV Export Integration Test

## Purpose
This integration test verifies that the coverage command can export data in CSV format.

## Prerequisites
To run this integration test, you need:
1. XCResult files from running tests with code coverage enabled
2. The derived-data-tool built and ready to run

## Setup
1. Place your .xcresult files in the appropriate location (typically ~/Library/Developer/Xcode/DerivedData)
2. Ensure the .xcrtool.yml configuration is properly set up
3. The database path and report paths exist

## Running the Test

### CSV Format Export
```bash
cd IntegrationTests/csv-export-test
swift run derived-data-tool coverage --format=csv
```

### Expected Output
1. A CSV file should be created at `Reports/coverage_report.csv`
2. The file should have proper CSV headers
3. The file should contain target and file coverage data
4. The CSV should be importable into Excel or Google Sheets

### Verification Steps
1. Check that the CSV file was created
2. Inspect the CSV headers (should include: Rank, Target, Coverage, etc.)
3. Verify data is properly formatted with commas
4. Import into Excel/Google Sheets to ensure compatibility

## Note
This test requires actual XCResult data to run successfully. Without real test coverage data,
the command will fail to find xcresult files to process.

For unit-level testing of the CSV encoder, see Tests/HelperTests/CSVEncoderTests.swift
