# JSON Summary Export Integration Test

This directory contains an integration test setup for the JSON summary export feature.

## Purpose

Verify that the `--format=json-summary` flag correctly:
1. Creates a JSON file with valid JSON structure
2. Includes overall coverage metrics (coverage %, lines covered, lines total)
3. Includes per-target breakdown with rankings
4. Includes comparison delta when previous report exists

## Files

- `.xcrtool.yml` - Configuration file specifying JSON summary as the output format
- `test-json-summary-export.sh` - Test script to verify JSON export functionality
- `Reports/` - Output directory for generated JSON reports

## Usage

### Prerequisites

To run a complete integration test with real coverage data:
1. Run tests in Xcode with code coverage enabled
2. Locate the `.xcresult` file in DerivedData
3. Update `.xcrtool.yml` if needed to point to correct paths

### Running the Test

```bash
cd IntegrationTests/json-summary-export-test
./test-json-summary-export.sh
```

## Expected Output

The script will:
1. Verify the `--format` option is available in the CLI
2. Check for available `.xcresult` files
3. Provide instructions for running with real data
4. Confirm that JSON summary encoder unit tests pass

## Validation

After generating a JSON report, you can validate it with:

```bash
# Check JSON is valid
jq . Reports/coverage_report.json

# Extract overall metrics
jq '.overall' Reports/coverage_report.json

# View per-target breakdown
jq '.targets' Reports/coverage_report.json

# View comparison delta (if exists)
jq '.comparison' Reports/coverage_report.json
```
