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

## Configuring Coverage Thresholds

The tool supports configurable coverage thresholds to enforce quality standards across your codebase. You can set different thresholds for different modules, allowing critical business logic to have higher coverage requirements than UI components.

### Configuration File

Create a `.xcrtool.yml` file in your project root to configure coverage thresholds:

```yaml
thresholds:
  global: 80.0  # Default threshold for all targets (in %)
  targets:
    # Critical modules require higher coverage
    PAFPaymentServiceCN: 90.0
    PAFUser: 85.0
    PAFNetwork: 85.0

    # UI components can have lower thresholds
    PAFUIComponents: 70.0

    # Common utilities
    PAFCommon: 75.0
```

### How Thresholds Work

- **Global Threshold**: The default coverage threshold applied to all targets unless overridden
- **Per-Target Thresholds**: Override the global threshold for specific modules
- **Fallback**: Any target without a specific threshold uses the global threshold
- **Validation**: Invalid thresholds (outside 0-100 range) or redundant configurations will trigger warnings

### Example Use Cases

**Critical Business Logic:**
```yaml
thresholds:
  global: 70.0
  targets:
    PaymentProcessing: 95.0  # Payments need thorough testing
    AuthenticationService: 90.0  # Security-critical code
```

**Legacy Code Management:**
```yaml
thresholds:
  global: 80.0
  targets:
    LegacyModule: 50.0  # Gradual improvement for legacy code
    NewFeature: 90.0  # High standards for new development
```

### CI/CD Integration

The tool exits with a non-zero status code if any target fails to meet its threshold, making it perfect for CI/CD pipelines:

```bash
# In your CI pipeline
swift run derived-data-tool coverage --config .xcrtool.yml

# Exit code 0: All thresholds met ✓
# Exit code 1: One or more thresholds failed ✗
```

The coverage reports will clearly show which targets passed or failed their thresholds with ✓ and ✗ indicators.

### Generating a Config File

Generate a default configuration file with:

```sh
swift run derived-data-tool config
```

This creates a `.xcrtool.yml` file with example threshold configurations that you can customize for your project.

## Where can I get more help, if I need it?

If you need more help, you can:

- Check the [Issues](https://github.com/arconsis/derived-data-tool/issues) section on GitHub to see if your question has already been answered or to ask a new question.
- Review the [Documentation](https://github.com/arconsis/derived-data-tool/wiki) for detailed guides and examples.
- Reach out to the community or maintainers via the [Discussions](https://github.com/arconsis/derived-data-tool/discussions) page.

We appreciate your feedback and contributions to improve this tool!

---

Thank you for using the DerivedDataTool. We hope it helps you maintain high-quality code and improve your testing practices.
