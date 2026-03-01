# DerivedDataTool

## What does this project do?

This project provides a Swift-based tool that generates detailed code coverage reports from the `xcresults` files located in the `DerivedData` folder. Additionally, it archives old coverage reports, allowing users to compare them and identify trends over time.

## Why is this project useful?

Code coverage is a crucial metric in software development that indicates how much of your codebase is covered by tests. This tool is useful for:

- Generating easy-to-read code coverage reports.
- Tracking code coverage trends over time.
- Identifying areas of your codebase that may need more testing.

By using this tool, developers can ensure their code is well-tested and maintain high quality standards.

## How do I get started?

To get started with this tool, follow these steps:

1. **Clone the Repository:**
    ```sh
    git clone https://github.com/arconsis/derived-data-tool.git
    cd SwiftCodeCoverageTool
    ```

2. **Install Dependencies:**
    Ensure you have Swift and any required dependencies installed.

3. **Run the Tool:**
    - Ensure you have an `xcresults` file in your `DerivedData` folder.
    - Run the tool with the following command:
    ```sh
    swift run CodeCoverageTool
    ```
    - The tool will generate a coverage report and archive it for trend analysis.

4. **View Reports:**
    The generated reports will be located in the `Reports` folder. Open the latest report in your browser to view the coverage details.

## Coverage Thresholds for CI/CD

This tool supports configurable coverage thresholds that enable you to enforce code quality standards in your CI/CD pipeline. When coverage falls below your specified thresholds, the tool exits with a non-zero exit code, allowing you to fail builds and prevent merging of code that doesn't meet your testing standards.

### Threshold Types

#### Absolute Thresholds
Set a minimum coverage percentage that your code must meet:

```yaml
tools:
  threshold:
    min_coverage: 80.0  # Requires at least 80% code coverage
```

If overall coverage is below 80%, the tool will exit with code 1 and display:
```
❌ Coverage threshold not met
   Current coverage: 75.5%
   Required minimum: 80.0%
   Gap: 4.5%

   → Add tests to increase coverage by at least 4.5%
```

#### Relative Thresholds
Prevent coverage from dropping compared to previous reports:

```yaml
tools:
  threshold:
    max_drop: 2.0  # Coverage cannot drop more than 2%
```

If coverage drops by 3% compared to the last report, the tool exits with code 1:
```
❌ Coverage dropped too much
   Previous coverage: 82.0%
   Current coverage: 79.0%
   Drop: 3.0%
   Maximum allowed drop: 2.0%

   → Add tests to recover at least 1.0% coverage
```

#### Per-Target Thresholds
Enforce different thresholds for specific targets:

```yaml
tools:
  threshold:
    min_coverage: 70.0  # Global minimum
    per_target_thresholds: '{"MyApp": {"minCoverage": 85.0}, "MyFramework": {"minCoverage": 90.0, "maxDrop": 1.0}}'
```

The `per_target_thresholds` field accepts a JSON-encoded string mapping target names to threshold configurations.

### Configuration Options

#### In `.xcrtool.yml`

Add a `threshold` section under `tools`:

```yaml
tools:
  threshold:
    min_coverage: 80.0      # Minimum overall coverage (optional)
    max_drop: 2.0           # Maximum allowed coverage drop (optional)
    per_target_thresholds: '{"CoreModule": {"minCoverage": 85.0}}'  # Per-target rules (optional)
```

#### Via CLI Flags

Override configuration values with command-line flags:

```sh
# Set minimum coverage via CLI
swift run derived-data-tool coverage --min-coverage 85.0

# Set maximum allowed drop
swift run derived-data-tool coverage --max-drop 1.5

# Combine both
swift run derived-data-tool coverage --min-coverage 80.0 --max-drop 2.0
```

CLI flags take precedence over configuration file values.

### Exit Codes for CI Integration

The tool uses exit codes to signal threshold validation results:

- **Exit 0**: All thresholds passed ✅
- **Exit 1**: One or more thresholds failed ❌

This makes it easy to integrate into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run Coverage with Threshold Check
  run: swift run derived-data-tool coverage --min-coverage 80.0
  # Build fails if coverage < 80%

# GitLab CI example
coverage_check:
  script:
    - swift run derived-data-tool coverage --min-coverage 80.0
  # Pipeline fails if coverage < 80%
```

### Example Use Cases

**Prevent Coverage Regression:**
```yaml
tools:
  threshold:
    max_drop: 0.0  # Zero-tolerance policy: coverage can never decrease
```

**Gradual Coverage Improvement:**
```yaml
tools:
  threshold:
    min_coverage: 70.0  # Start at 70%
    # Increase this value over time to improve code quality
```

**Strict Rules for Critical Components:**
```yaml
tools:
  threshold:
    min_coverage: 60.0  # Lower global threshold
    per_target_thresholds: '{"PaymentModule": {"minCoverage": 95.0}, "SecurityFramework": {"minCoverage": 95.0}}'
```

## CI-Optimized Output Mode

For seamless integration into CI/CD pipelines, DerivedDataTool provides a dedicated `--ci` flag that produces machine-parseable output, GitHub Actions annotations, and structured JSON summaries.

### Why Use CI Mode?

Traditional cloud coverage services (Codecov, Coveralls) can cause CI failures during outages. DerivedDataTool's local execution is inherently reliable, and CI mode provides:

- **Clean, parseable output** for CI logs without visual noise (no emoji or colors)
- **GitHub Actions annotations** that highlight coverage issues directly in PR checks
- **Structured JSON export** for downstream CI processing and custom workflows
- **Machine-parseable summary** for easy integration with monitoring tools

### Basic Usage

Enable CI mode by adding the `--ci` flag:

```sh
swift run derived-data-tool coverage --ci --min-coverage 80.0
```

This produces output optimized for CI environments:

```
COVERAGE: 78.5% | TARGETS: 2/3 PASSED | THRESHOLD: FAIL
::error file=MyApp,title=Coverage Threshold Not Met::Target 'MyApp' coverage 78.5% is below required 80.0%
```

### GitHub Actions Integration

Add DerivedDataTool to your GitHub Actions workflow:

```yaml
name: Coverage Check

on: [pull_request]

jobs:
  coverage:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Tests
        run: xcodebuild test -scheme MyApp -resultBundlePath TestResults.xcresult

      - name: Check Coverage
        run: |
          swift run derived-data-tool coverage \
            --ci \
            --min-coverage 80.0 \
            --ci-json-output coverage-summary.json

      - name: Upload Coverage Summary
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: coverage-summary
          path: coverage-summary.json
```

Coverage failures will appear as annotations in the PR checks tab, making it easy for developers to see exactly which files need attention.

### JSON Export for Downstream Processing

Use the `--ci-json-output` flag to export structured coverage data:

```sh
swift run derived-data-tool coverage \
  --ci \
  --ci-json-output coverage-summary.json \
  --min-coverage 80.0
```

The JSON output includes comprehensive coverage metrics:

```json
{
  "overallCoverage": 78.5,
  "thresholdStatus": "FAIL",
  "targets": [
    {
      "name": "MyApp",
      "coverage": 78.5,
      "coveredLines": 1570,
      "executableLines": 2000,
      "passed": false
    },
    {
      "name": "MyFramework",
      "coverage": 92.3,
      "coveredLines": 923,
      "executableLines": 1000,
      "passed": true
    }
  ],
  "failures": [
    {
      "targetName": "MyApp",
      "actualCoverage": 78.5,
      "requiredThreshold": 80.0
    }
  ]
}
```

### Machine-Parseable Summary

CI mode outputs a single-line summary that's easy to parse programmatically:

```
COVERAGE: {overall}% | TARGETS: {passed}/{total} PASSED | THRESHOLD: {PASS|FAIL}
```

Example:
```
COVERAGE: 85.2% | TARGETS: 5/5 PASSED | THRESHOLD: PASS
```

### GitHub Actions Annotations Format

When thresholds fail, CI mode generates annotations following the [GitHub Actions workflow commands format](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions):

```
::error file={targetName},title=Coverage Threshold Not Met::{message}
::error file={targetName},title=Coverage Dropped::{message}
```

These annotations appear inline in the PR "Files changed" tab and in the workflow run summary.

### Combining CI Mode with Thresholds

CI mode works seamlessly with all threshold configurations:

```sh
# Absolute threshold
swift run derived-data-tool coverage --ci --min-coverage 80.0

# Relative threshold
swift run derived-data-tool coverage --ci --max-drop 2.0

# Per-target thresholds (configured in .xcrtool.yml)
swift run derived-data-tool coverage --ci

# Multiple thresholds with JSON export
swift run derived-data-tool coverage \
  --ci \
  --min-coverage 75.0 \
  --max-drop 1.5 \
  --ci-json-output coverage-summary.json
```

### CI Mode Output Characteristics

When `--ci` is enabled:

- ✅ GitHub Actions annotations for failed thresholds
- ✅ Single-line machine-parseable summary
- ✅ Clean output without emoji or colors
- ✅ Optional structured JSON export via `--ci-json-output`
- ✅ Exit code 0 for pass, 1 for fail (same as normal mode)

## Where can I get more help, if I need it?

If you need more help, you can:

- Check the [Issues](https://github.com/arconsis/derived-data-tool/issues) section on GitHub to see if your question has already been answered or to ask a new question.
- Review the [Documentation](https://github.com/arconsis/derived-data-tool/wiki) for detailed guides and examples.
- Reach out to the community or maintainers via the [Discussions](https://github.com/arconsis/derived-data-tool/discussions) page.

We appreciate your feedback and contributions to improve this tool!

---

Thank you for using the DerivedDataTool. We hope it helps you maintain high-quality code and improve your testing practices.
