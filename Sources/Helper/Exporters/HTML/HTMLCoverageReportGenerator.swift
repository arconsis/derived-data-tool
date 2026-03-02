//
//  HTMLCoverageReportGenerator.swift
//
//
//  Created by auto-claude on 02.03.26.
//

import Foundation
import Shared
import SwiftHtml

public class HTMLCoverageReportGenerator {
    private let report: CoverageMetaReport

    public init(report: CoverageMetaReport) {
        self.report = report
    }

    /// Generate a self-contained HTML coverage report
    public static func generateHTML(from report: CoverageMetaReport) -> String {
        let generator = HTMLCoverageReportGenerator(report: report)
        return generator.generate()
    }

    private func generate() -> String {
        let doc = Document(.html) {
            buildHTML()
        }
        return DocumentRenderer(minify: false, indent: 4)
            .render(doc)
    }

    @TagBuilder
    private func buildHTML() -> Tag {
        Html {
            buildHead()
            buildBody()
        }
    }

    @TagBuilder
    private func buildHead() -> Tag {
        Head {
            Meta().charset("utf-8")
            Meta()
                .name(.viewport)
                .content("width=device-width, initial-scale=1")
            Title("Coverage Report - \(report.fileInfo.date.formatted())")
            Style {
                HTMLCoverageStyles.allStyles()
            }
        }
    }

    @TagBuilder
    private func buildBody() -> Tag {
        Body {
            Div {
                buildHeader()
                buildSummarySection()
                buildTargetsSection()
            }
            .class(["container"])
            buildJavaScript()
        }
    }

    // MARK: - Header

    @TagBuilder
    private func buildHeader() -> Tag {
        H1 {
            Text("Code Coverage Report")
        }
    }

    // MARK: - Summary Section

    @TagBuilder
    private func buildSummarySection() -> Tag {
        let coverage = report.coverage
        let coveragePercent = String(format: "%.2f", coverage.coverage * 100.0)
        let colorClass = getCoverageColorClass(coverage.coverage)

        SummaryCardGenerator().buildTag(
            SummaryCardData(
                title: "Overall Coverage",
                items: [
                    SummaryCard.SummaryItem(
                        label: "Coverage",
                        value: "\(coveragePercent)%",
                        cssClasses: [colorClass]
                    ),
                    SummaryCard.SummaryItem(
                        label: "Covered Lines",
                        value: "\(coverage.coveredLines)"
                    ),
                    SummaryCard.SummaryItem(
                        label: "Executable Lines",
                        value: "\(coverage.executableLines)"
                    ),
                    SummaryCard.SummaryItem(
                        label: "Targets",
                        value: "\(coverage.targets.count)"
                    )
                ]
            )
        )
    }

    // MARK: - Targets Section

    @TagBuilder
    private func buildTargetsSection() -> Tag {
        Section {
            H2 {
                Text("Targets")
            }
            buildTargetsTable()
        }
    }

    @TagBuilder
    private func buildTargetsTable() -> Tag {
        Table {
            buildTargetsTableHeader()
            buildTargetsTableBody()
        }
        .class(["coverage-table"])
        .id("targets-table")
    }

    @TagBuilder
    private func buildTargetsTableHeader() -> Tag {
        SortableTableHeaderGenerator().buildTag(
            SortableHeaderData(
                headers: [
                    SortableTableHeader.HeaderCell(
                        title: "Target",
                        sortable: true,
                        columnKey: "name"
                    ),
                    SortableTableHeader.HeaderCell(
                        title: "Coverage",
                        sortable: true,
                        columnKey: "coverage",
                        cssClasses: ["text-center"]
                    ),
                    SortableTableHeader.HeaderCell(
                        title: "Covered",
                        sortable: true,
                        columnKey: "covered",
                        cssClasses: ["text-center"]
                    ),
                    SortableTableHeader.HeaderCell(
                        title: "Executable",
                        sortable: true,
                        columnKey: "executable",
                        cssClasses: ["text-center"]
                    ),
                    SortableTableHeader.HeaderCell(
                        title: "Visual",
                        sortable: false,
                        columnKey: nil
                    )
                ]
            )
        )
    }

    @TagBuilder
    private func buildTargetsTableBody() -> Tag {
        Tbody {
            for target in report.coverage.targets {
                buildTargetRow(target)
                buildTargetFilesExpandableContent(target)
            }
        }
    }

    @TagBuilder
    private func buildTargetRow(_ target: Shared.Target) -> Tag {
        let coveragePercent = String(format: "%.2f", target.coverage * 100.0)
        let colorClass = getCoverageColorClass(target.coverage)
        let targetID = sanitizeID(target.name)

        Tr {
            Td {
                Span {
                    Text("▶")
                }
                .class(["expand-icon"])
                Span {
                    Text(target.name)
                }
            }
            Td {
                Text("\(coveragePercent)%")
            }
            .class([colorClass, "text-center"])
            .attribute("data-value", String(target.coverage))
            Td {
                Text("\(target.coveredLines)")
            }
            .class(["text-center"])
            .attribute("data-value", String(target.coveredLines))
            Td {
                Text("\(target.executableLines)")
            }
            .class(["text-center"])
            .attribute("data-value", String(target.executableLines))
            Td {
                CoverageBarGenerator().buildTag(
                    CoverageBarData(percentage: target.coverage)
                )
            }
        }
        .class(["expandable"])
        .attribute("data-target-id", targetID)
    }

    @TagBuilder
    private func buildTargetFilesExpandableContent(_ target: Shared.Target) -> Tag {
        let targetID = sanitizeID(target.name)

        Tr {
            Td {
                Div {
                    H3 {
                        Text("Files in \(target.name)")
                    }
                    .class(["mt-2", "mb-2"])

                    if target.files.isEmpty {
                        P {
                            Text("No files found in this target.")
                        }
                        .class(["text-muted"])
                    } else {
                        buildFilesTable(for: target)
                    }
                }
                .class(["expandable-inner"])
            }
            .attribute("colspan", "5")
        }
        .class(["expandable-content"])
        .id("content-\(targetID)")
    }

    @TagBuilder
    private func buildFilesTable(for target: Shared.Target) -> Tag {
        Table {
            buildFilesTableHeader()
            Tbody {
                for file in target.files.sorted(by: { $0.coverage > $1.coverage }) {
                    ExpandableFileSectionGenerator().buildTag(
                        ExpandableFileSectionData(
                            fileName: file.name,
                            fileID: sanitizeID("\(target.name)-\(file.name)"),
                            coverage: file.coverage,
                            coveredLines: file.coveredLines,
                            executableLines: file.executableLines
                        )
                    )
                    buildFileDetailsExpandableContent(file, targetName: target.name)
                }
            }
        }
        .class(["coverage-table", "line-coverage"])
    }

    @TagBuilder
    private func buildFilesTableHeader() -> Tag {
        Thead {
            Tr {
                Th {
                    Text("File")
                }
                Th {
                    Text("Coverage")
                }
                .class(["text-center"])
                Th {
                    Text("Covered")
                }
                .class(["text-center"])
                Th {
                    Text("Executable")
                }
                .class(["text-center"])
                Th {
                    Text("Visual")
                }
            }
        }
    }

    @TagBuilder
    private func buildFileDetailsExpandableContent(_ file: Shared.File, targetName: String) -> Tag {
        let fileID = sanitizeID("\(targetName)-\(file.name)")

        Tr {
            Td {
                Div {
                    H4 {
                        Text("Functions in \(file.name)")
                    }
                    .class(["mt-2", "mb-2", "font-mono"])

                    if file.functions.isEmpty {
                        P {
                            Text("No function coverage data available.")
                        }
                        .class(["text-muted"])
                    } else {
                        buildFunctionsTable(file.functions)
                    }
                }
                .class(["expandable-inner"])
            }
            .attribute("colspan", "5")
        }
        .class(["expandable-content"])
        .id("content-\(fileID)")
    }

    @TagBuilder
    private func buildFunctionsTable(_ functions: [Shared.Function]) -> Tag {
        Table {
            Thead {
                Tr {
                    Th {
                        Text("Function")
                    }
                    Th {
                        Text("Line")
                    }
                    .class(["text-center"])
                    Th {
                        Text("Coverage")
                    }
                    .class(["text-center"])
                    Th {
                        Text("Execution Count")
                    }
                    .class(["text-center"])
                }
            }
            Tbody {
                for function in functions.sorted(by: { $0.lineNumber < $1.lineNumber }) {
                    buildFunctionRow(function)
                }
            }
        }
        .class(["coverage-table", "line-coverage"])
    }

    @TagBuilder
    private func buildFunctionRow(_ function: Shared.Function) -> Tag {
        let coveragePercent = String(format: "%.2f", function.coverage * 100.0)
        let colorClass = getCoverageColorClass(function.coverage)

        Tr {
            Td {
                Text(function.name)
            }
            .class(["font-mono"])
            Td {
                Text("\(function.lineNumber)")
            }
            .class(["text-center"])
            Td {
                Text("\(coveragePercent)%")
            }
            .class([colorClass, "text-center"])
            Td {
                Text("\(function.executionCount)")
            }
            .class(["text-center"])
        }
    }

    // MARK: - JavaScript

    @TagBuilder
    private func buildJavaScript() -> Tag {
        Script {
            Text("""
            // Table sorting functionality
            function sortTable(table, columnIndex, ascending) {
                const tbody = table.querySelector('tbody');
                const rows = Array.from(tbody.querySelectorAll('tr:not(.expandable-content)'));

                rows.sort((a, b) => {
                    const aCell = a.cells[columnIndex];
                    const bCell = b.cells[columnIndex];

                    // Get data-value attribute if it exists, otherwise use text content
                    const aValue = aCell.getAttribute('data-value') || aCell.textContent.trim();
                    const bValue = bCell.getAttribute('data-value') || bCell.textContent.trim();

                    // Try to parse as numbers
                    const aNum = parseFloat(aValue);
                    const bNum = parseFloat(bValue);

                    if (!isNaN(aNum) && !isNaN(bNum)) {
                        return ascending ? aNum - bNum : bNum - aNum;
                    }

                    // Fall back to string comparison
                    return ascending
                        ? aValue.localeCompare(bValue)
                        : bValue.localeCompare(aValue);
                });

                // Rebuild table with sorted rows and their expandable content
                rows.forEach(row => {
                    tbody.appendChild(row);
                    const targetId = row.getAttribute('data-target-id');
                    if (targetId) {
                        const expandableContent = tbody.querySelector(`#content-${targetId}`);
                        if (expandableContent) {
                            tbody.appendChild(expandableContent);
                        }
                    }
                });
            }

            // Toggle expandable sections
            function toggleExpandable(element) {
                const targetId = element.getAttribute('data-target-id') || element.getAttribute('data-file-id');
                if (!targetId) return;

                const content = document.getElementById(`content-${targetId}`);
                if (content) {
                    content.classList.toggle('expanded');
                    element.classList.toggle('expanded');
                }
            }

            // Setup event listeners
            document.addEventListener('DOMContentLoaded', function() {
                // Add click handlers to sortable headers
                document.querySelectorAll('.coverage-table th.sortable').forEach(header => {
                    header.addEventListener('click', function() {
                        const table = this.closest('table');
                        const columnIndex = Array.from(this.parentElement.children).indexOf(this);
                        const isAscending = !this.classList.contains('sorted-asc');

                        // Remove sort classes from all headers in this table
                        table.querySelectorAll('th').forEach(h => {
                            h.classList.remove('sorted-asc', 'sorted-desc');
                        });

                        // Add appropriate sort class
                        this.classList.add(isAscending ? 'sorted-asc' : 'sorted-desc');

                        sortTable(table, columnIndex, isAscending);
                    });
                });

                // Add click handlers to expandable rows
                document.querySelectorAll('.expandable').forEach(row => {
                    row.addEventListener('click', function(e) {
                        // Don't toggle if clicking on a link or button
                        if (e.target.tagName === 'A' || e.target.tagName === 'BUTTON') {
                            return;
                        }
                        toggleExpandable(this);
                    });
                });
            });
            """)
        }
    }

    // MARK: - Helper Methods

    private func getCoverageColorClass(_ coverage: Double) -> String {
        if coverage >= 0.8 {
            return "high_coverage"
        } else if coverage >= 0.3 {
            return "normal_coverage"
        } else if coverage >= 0.15 {
            return "lower_coverage"
        } else {
            return "low_coverage"
        }
    }

    private func sanitizeID(_ string: String) -> String {
        // Replace non-alphanumeric characters with hyphens for valid HTML IDs
        return string
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .lowercased()
    }
}
