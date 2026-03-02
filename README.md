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

## HTML Coverage Reports

DerivedDataTool can generate rich, interactive HTML coverage reports that provide a visual and user-friendly way to explore your code coverage data. Unlike terminal output, HTML reports offer sortable tables, file-level details, and a persistent artifact you can share with your team or archive for historical analysis.

### Why Use HTML Format?

HTML reports are ideal for:

- **Visual Analysis**: Easy-to-read tables with color-coded coverage percentages
- **Interactive Exploration**: Click column headers to sort by coverage, lines, or target name
- **Team Collaboration**: Share a single HTML file via email, Slack, or CI artifacts
- **Historical Records**: Archive HTML reports to track coverage trends over time
- **Documentation**: Include coverage reports in project documentation or wikis
- **Offline Access**: View coverage details without needing to re-run the tool

### Basic Usage

Generate an HTML coverage report by adding the `--format=html` flag:

```sh
swift run derived-data-tool coverage --format=html
```

By default, this creates a file named `coverage-report.html` in your current directory. Open it in any web browser:

```sh
open coverage-report.html
```

### Custom Output Location

Specify a custom filename or path using the `--output` flag:

```sh
# Save to a specific directory
swift run derived-data-tool coverage --format=html --output ./reports/coverage-2024-03-15.html

# Save to CI artifacts directory
swift run derived-data-tool coverage --format=html --output ./build/coverage/index.html
```

### HTML Report Features

The generated HTML report includes:

- **Overall Coverage Summary**: Total coverage percentage and line counts displayed prominently
- **Sortable Target Table**: Click any column header to sort targets by:
  - Target name (alphabetical)
  - Coverage percentage (high to low or low to high)
  - Covered lines count
  - Executable lines count
- **Color-Coded Coverage**: Visual indicators for coverage levels:
  - 🟢 Green: ≥ 80% coverage (excellent)
  - 🟡 Yellow: 60-79% coverage (good)
  - 🟠 Orange: 40-59% coverage (needs improvement)
  - 🔴 Red: < 40% coverage (critical)
- **File-Level Breakdown**: Expandable file listings for each target showing individual file coverage
- **Responsive Design**: Works on desktop, tablet, and mobile browsers
- **Self-Contained**: Single HTML file with embedded CSS (no external dependencies)

### Combining HTML Format with Thresholds

HTML reports work seamlessly with coverage thresholds. The report will visually highlight targets that fail threshold checks:

```sh
swift run derived-data-tool coverage \
  --format=html \
  --output coverage-report.html \
  --min-coverage 80.0
```

If thresholds fail:
- The tool exits with code 1 (as expected for CI integration)
- The HTML report is still generated with threshold failures highlighted
- Failed targets are marked with a ⚠️ warning indicator

### Integration with CI/CD Pipelines

HTML reports are perfect for CI artifact collection:

```yaml
# GitHub Actions example
- name: Generate HTML Coverage Report
  run: |
    swift run derived-data-tool coverage \
      --format=html \
      --output coverage-report.html \
      --min-coverage 80.0

- name: Upload HTML Coverage Report
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: coverage-report.html
```

Team members can download the HTML report directly from the GitHub Actions run page, making it easy to review coverage without running tests locally.

### GitLab CI Integration

```yaml
coverage_html:
  script:
    - swift run derived-data-tool coverage --format=html --output coverage.html
  artifacts:
    paths:
      - coverage.html
    expire_in: 30 days
  only:
    - merge_requests
```

The HTML report will be available as a downloadable artifact in the GitLab pipeline.

### Combining HTML and CI Modes

You cannot use `--format=html` and `--ci` together, as they serve different purposes:

- **`--format=html`**: For human-readable reports and archival
- **`--ci`**: For machine-parseable output and GitHub Actions annotations

Instead, run the tool twice in your CI pipeline if you need both:

```yaml
# Generate HTML report for human review
- name: Generate HTML Report
  run: swift run derived-data-tool coverage --format=html --output coverage.html

# Run CI mode for threshold validation
- name: Validate Coverage Thresholds
  run: swift run derived-data-tool coverage --ci --min-coverage 80.0
```

### Example Use Cases

**Weekly Coverage Report for Team Review:**
```sh
swift run derived-data-tool coverage \
  --format=html \
  --output "weekly-coverage-$(date +%Y-%m-%d).html"
```

**Archive Coverage Reports by Git Tag:**
```sh
TAG=$(git describe --tags)
swift run derived-data-tool coverage \
  --format=html \
  --output "coverage-${TAG}.html"
```

**Generate Report and Auto-Open in Browser:**
```sh
swift run derived-data-tool coverage --format=html && open coverage-report.html
```

### HTML vs. Terminal Output

| Feature | Terminal Output | HTML Format |
|---------|----------------|-------------|
| **Best for** | Quick checks, CI validation | Detailed analysis, sharing |
| **Sortable** | ❌ No | ✅ Yes (click headers) |
| **Persistent** | ❌ No (scrolls away) | ✅ Yes (save & archive) |
| **Shareable** | ⚠️ Copy/paste only | ✅ Single file |
| **File Details** | ✅ Yes | ✅ Yes (expandable) |
| **CI Annotations** | ✅ With `--ci` flag | ❌ No |
| **Visual Colors** | ✅ In terminal | ✅ In browser |
| **Offline Access** | ❌ Must re-run | ✅ Open anytime |

## Where can I get more help, if I need it?

If you need more help, you can:

- Check the [Issues](https://github.com/arconsis/derived-data-tool/issues) section on GitHub to see if your question has already been answered or to ask a new question.
- Review the [Documentation](https://github.com/arconsis/derived-data-tool/wiki) for detailed guides and examples.
- Reach out to the community or maintainers via the [Discussions](https://github.com/arconsis/derived-data-tool/discussions) page.

We appreciate your feedback and contributions to improve this tool!

---

Thank you for using the DerivedDataTool. We hope it helps you maintain high-quality code and improve your testing practices.
