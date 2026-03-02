#!/usr/bin/env swift

import Foundation

// This script generates a sample HTML file for manual browser testing
// Run with: swift generate_test_html.swift

let htmlContent = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Coverage Report - Test</title>
    <style>
        /* Base Styles */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif; background-color: #f5f5f5; padding: 20px; line-height: 1.6; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; margin-bottom: 30px; font-size: 28px; border-bottom: 3px solid #007bff; padding-bottom: 10px; }
        h2 { color: #444; margin: 30px 0 15px; font-size: 22px; }

        /* Coverage Color Classes */
        .coverage-high { color: #28a745; font-weight: 600; }
        .coverage-normal { color: #ffc107; font-weight: 600; }
        .coverage-lower { color: #fd7e14; font-weight: 600; }
        .coverage-low { color: #dc3545; font-weight: 600; }

        /* Summary Card */
        .summary-card { background: #f8f9fa; border-radius: 6px; padding: 20px; margin-bottom: 30px; border-left: 4px solid #007bff; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        .summary-item { text-align: center; }
        .summary-label { font-size: 14px; color: #666; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; }
        .summary-value { font-size: 32px; font-weight: 700; }

        /* Coverage Bar */
        .coverage-bar-container { width: 100%; height: 24px; background: #e9ecef; border-radius: 12px; overflow: hidden; position: relative; margin: 8px 0; }
        .coverage-bar { height: 100%; transition: width 0.3s ease; display: flex; align-items: center; justify-content: flex-end; padding-right: 8px; font-size: 12px; color: white; font-weight: 600; }
        .coverage-bar.coverage-high { background: linear-gradient(90deg, #28a745, #20c997); }
        .coverage-bar.coverage-normal { background: linear-gradient(90deg, #ffc107, #ffca2c); }
        .coverage-bar.coverage-lower { background: linear-gradient(90deg, #fd7e14, #ff922b); }
        .coverage-bar.coverage-low { background: linear-gradient(90deg, #dc3545, #e4606d); }

        /* Table Styles */
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; }
        thead { background: #007bff; color: white; }
        th { padding: 12px 16px; text-align: left; font-weight: 600; cursor: pointer; user-select: none; position: relative; }
        th:hover { background: #0056b3; }
        th::after { content: ' ⇅'; opacity: 0.5; font-size: 12px; }
        th.sort-asc::after { content: ' ↑'; opacity: 1; }
        th.sort-desc::after { content: ' ↓'; opacity: 1; }
        td { padding: 12px 16px; border-bottom: 1px solid #dee2e6; }
        tbody tr:hover { background: #f8f9fa; }

        /* Expandable Rows */
        .expandable { cursor: pointer; }
        .expand-icon { display: inline-block; width: 20px; transition: transform 0.2s; }
        .expand-icon::before { content: '▶'; }
        .expandable.expanded .expand-icon::before { content: '▼'; }
        .expandable-content { display: none; }
        .expandable.expanded + .expandable-content { display: table-row; }
        .file-details { background: #f8f9fa; padding: 20px; }

        /* Line Coverage */
        .line-row { display: flex; align-items: center; padding: 4px 8px; font-family: 'Monaco', 'Menlo', monospace; font-size: 13px; }
        .line-number { width: 60px; color: #6c757d; text-align: right; padding-right: 16px; user-select: none; }
        .line-hits { width: 60px; text-align: right; padding-right: 16px; font-weight: 600; }
        .line-covered { background: #d4edda; border-left: 3px solid #28a745; }
        .line-uncovered { background: #f8d7da; border-left: 3px solid #dc3545; }

        /* Responsive */
        @media (max-width: 768px) {
            .container { padding: 15px; }
            .summary-grid { grid-template-columns: 1fr; }
            table { font-size: 14px; }
            th, td { padding: 8px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Code Coverage Report</h1>

        <!-- Summary Section -->
        <div class="summary-card">
            <div class="summary-grid">
                <div class="summary-item">
                    <div class="summary-label">Coverage</div>
                    <div class="summary-value coverage-high">85.50%</div>
                </div>
                <div class="summary-item">
                    <div class="summary-label">Covered Lines</div>
                    <div class="summary-value">855</div>
                </div>
                <div class="summary-item">
                    <div class="summary-label">Executable Lines</div>
                    <div class="summary-value">1000</div>
                </div>
                <div class="summary-item">
                    <div class="summary-label">Targets</div>
                    <div class="summary-value">2</div>
                </div>
            </div>
        </div>

        <!-- Targets Table -->
        <h2>Targets</h2>
        <table id="targetsTable">
            <thead>
                <tr>
                    <th data-column="0" data-type="string">Target</th>
                    <th data-column="1" data-type="number">Coverage</th>
                    <th data-column="2" data-type="number">Lines</th>
                    <th data-column="3" data-type="number">Files</th>
                </tr>
            </thead>
            <tbody>
                <tr class="expandable" data-target="target-1">
                    <td><span class="expand-icon"></span> MyApp</td>
                    <td data-value="92.5">
                        <div class="coverage-bar-container">
                            <div class="coverage-bar coverage-high" style="width: 92.5%;">92.50%</div>
                        </div>
                    </td>
                    <td data-value="925">925 / 1000</td>
                    <td data-value="15">15</td>
                </tr>
                <tr class="expandable-content">
                    <td colspan="4">
                        <div class="file-details">
                            <h3>Files in MyApp</h3>
                            <table>
                                <thead>
                                    <tr>
                                        <th>File</th>
                                        <th>Coverage</th>
                                        <th>Functions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr class="expandable" data-file="file-1">
                                        <td><span class="expand-icon"></span> ViewController.swift</td>
                                        <td data-value="95.0">
                                            <div class="coverage-bar-container">
                                                <div class="coverage-bar coverage-high" style="width: 95%;">95.00%</div>
                                            </div>
                                        </td>
                                        <td data-value="8">8</td>
                                    </tr>
                                    <tr class="expandable-content">
                                        <td colspan="3">
                                            <div class="file-details">
                                                <h4>Line Coverage</h4>
                                                <div class="line-row line-covered">
                                                    <span class="line-number">1</span>
                                                    <span class="line-hits">42</span>
                                                    <span>import UIKit</span>
                                                </div>
                                                <div class="line-row line-covered">
                                                    <span class="line-number">2</span>
                                                    <span class="line-hits">42</span>
                                                    <span>class ViewController: UIViewController {</span>
                                                </div>
                                                <div class="line-row line-covered">
                                                    <span class="line-number">3</span>
                                                    <span class="line-hits">42</span>
                                                    <span>    override func viewDidLoad() {</span>
                                                </div>
                                                <div class="line-row line-uncovered">
                                                    <span class="line-number">4</span>
                                                    <span class="line-hits">0</span>
                                                    <span>        handleError()</span>
                                                </div>
                                                <div class="line-row line-covered">
                                                    <span class="line-number">5</span>
                                                    <span class="line-hits">42</span>
                                                    <span>    }</span>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr class="expandable" data-file="file-2">
                                        <td><span class="expand-icon"></span> Model.swift</td>
                                        <td data-value="88.5">
                                            <div class="coverage-bar-container">
                                                <div class="coverage-bar coverage-high" style="width: 88.5%;">88.50%</div>
                                            </div>
                                        </td>
                                        <td data-value="5">5</td>
                                    </tr>
                                    <tr class="expandable-content">
                                        <td colspan="3">
                                            <div class="file-details">
                                                <p>Function-level coverage details would appear here</p>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </td>
                </tr>
                <tr class="expandable" data-target="target-2">
                    <td><span class="expand-icon"></span> MyAppTests</td>
                    <td data-value="75.0">
                        <div class="coverage-bar-container">
                            <div class="coverage-bar coverage-normal" style="width: 75%;">75.00%</div>
                        </div>
                    </td>
                    <td data-value="750">750 / 1000</td>
                    <td data-value="8">8</td>
                </tr>
                <tr class="expandable-content">
                    <td colspan="4">
                        <div class="file-details">
                            <p>Test files would be listed here</p>
                        </div>
                    </td>
                </tr>
                <tr class="expandable" data-target="target-3">
                    <td><span class="expand-icon"></span> LowCoverageTarget</td>
                    <td data-value="45.0">
                        <div class="coverage-bar-container">
                            <div class="coverage-bar coverage-low" style="width: 45%;">45.00%</div>
                        </div>
                    </td>
                    <td data-value="450">450 / 1000</td>
                    <td data-value="3">3</td>
                </tr>
                <tr class="expandable-content">
                    <td colspan="4">
                        <div class="file-details">
                            <p>Files with low coverage would be listed here</p>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <script>
        // Table Sorting
        function sortTable(table, column, ascending) {
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr:not(.expandable-content)'));

            rows.sort((a, b) => {
                const aCell = a.cells[column];
                const bCell = b.cells[column];

                const aValue = aCell.dataset.value || aCell.textContent.trim();
                const bValue = bCell.dataset.value || bCell.textContent.trim();

                const aNum = parseFloat(aValue);
                const bNum = parseFloat(bValue);

                let comparison;
                if (!isNaN(aNum) && !isNaN(bNum)) {
                    comparison = aNum - bNum;
                } else {
                    comparison = aValue.localeCompare(bValue);
                }

                return ascending ? comparison : -comparison;
            });

            // Re-append rows with their expandable content
            rows.forEach(row => {
                tbody.appendChild(row);
                const nextSibling = row.nextElementSibling;
                if (nextSibling && nextSibling.classList.contains('expandable-content')) {
                    tbody.appendChild(nextSibling);
                }
            });
        }

        // Toggle Expandable Sections
        function toggleExpandable(row) {
            row.classList.toggle('expanded');
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', () => {
            // Setup sortable headers
            document.querySelectorAll('th[data-column]').forEach(header => {
                let ascending = true;
                header.addEventListener('click', () => {
                    const table = header.closest('table');
                    const column = parseInt(header.dataset.column);

                    // Update header classes
                    table.querySelectorAll('th').forEach(h => {
                        h.classList.remove('sort-asc', 'sort-desc');
                    });

                    header.classList.add(ascending ? 'sort-asc' : 'sort-desc');

                    sortTable(table, column, ascending);
                    ascending = !ascending;
                });
            });

            // Setup expandable rows
            document.querySelectorAll('.expandable').forEach(row => {
                row.addEventListener('click', (e) => {
                    // Don't toggle if clicking on a nested expandable
                    if (e.target.closest('.file-details')) return;
                    toggleExpandable(row);
                });
            });
        });

        // Log to console for testing
        console.log('HTML Coverage Report loaded successfully');
        console.log('Features available:');
        console.log('- Table sorting: Click column headers');
        console.log('- Expandable sections: Click rows with arrow icon');
        console.log('- Coverage bars: Visual representation of coverage %');
        console.log('- Line-by-line coverage: Expand files to see details');
    </script>
</body>
</html>
"""

let fileURL = URL(fileURLWithPath: "test-coverage-report.html")
try htmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
print("✅ Generated test-coverage-report.html")
print("   Open this file in Chrome, Firefox, and Safari to verify:")
print("   - Tables sort when clicking headers")
print("   - Files expand/collapse when clicking rows")
print("   - Coverage bars display correctly")
print("   - Colors match thresholds (green > 80%, yellow 60-80%, red < 60%)")
print("   - No console errors")
print("   - No external dependencies")
print("")
print("   open -a 'Google Chrome' test-coverage-report.html")
print("   open -a 'Firefox' test-coverage-report.html")
print("   open -a 'Safari' test-coverage-report.html")
