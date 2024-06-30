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

## Where can I get more help, if I need it?

If you need more help, you can:

- Check the [Issues](https://github.com/arconsis/derived-data-tool/issues) section on GitHub to see if your question has already been answered or to ask a new question.
- Review the [Documentation](https://github.com/arconsis/derived-data-tool/wiki) for detailed guides and examples.
- Reach out to the community or maintainers via the [Discussions](https://github.com/arconsis/derived-data-tool/discussions) page.

We appreciate your feedback and contributions to improve this tool!

---

Thank you for using the DerivedDataTool. We hope it helps you maintain high-quality code and improve your testing practices.
