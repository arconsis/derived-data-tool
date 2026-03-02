//
//  HTMLCoverageStyles.swift
//
//
//  Created by auto-claude on 02.03.26.
//

import Foundation
import SwiftHtml

enum HTMLCoverageStyles {
    // MARK: - Color Scheme

    @TagBuilder
    static func colorScheme() -> Tag {
        Text("""
        :root {
            --color-high: #00cd33;
            --color-normal: #6c757d;
            --color-lower: #ffae00;
            --color-low: #e01a4f;
            --color-background: #ffffff;
            --color-text: #212529;
            --color-border: #dee2e6;
            --color-hover: #f8f9fa;
            --color-covered: #d4edda;
            --color-uncovered: #f8d7da;
            --color-header: #343a40;
        }
        """)
    }

    // MARK: - Base Styles

    @TagBuilder
    static func baseStyles() -> Tag {
        Text("""
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: var(--color-text);
            background-color: var(--color-background);
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        h1, h2, h3 {
            margin-bottom: 1rem;
            font-weight: 600;
        }

        h1 {
            font-size: 2rem;
            text-align: center;
            padding-bottom: 1.5rem;
            border-bottom: 2px solid var(--color-border);
            margin-bottom: 2rem;
        }

        h2 {
            font-size: 1.5rem;
            margin-top: 2rem;
        }
        """)
    }

    // MARK: - Coverage Colors

    @TagBuilder
    static func coverageColors() -> Tag {
        Text("""
        .high_coverage {
            color: var(--color-high);
            font-weight: 600;
        }

        .normal_coverage {
            color: var(--color-normal);
            font-weight: 600;
        }

        .lower_coverage {
            color: var(--color-lower);
            font-weight: 600;
        }

        .low_coverage {
            color: var(--color-low);
            font-weight: 600;
        }
        """)
    }

    // MARK: - Table Styles

    @TagBuilder
    static func tableStyles() -> Tag {
        Text("""
        .coverage-table {
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
            background-color: var(--color-background);
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .coverage-table thead {
            background-color: var(--color-header);
            color: white;
        }

        .coverage-table th {
            padding: 12px 16px;
            text-align: left;
            font-weight: 600;
            cursor: pointer;
            user-select: none;
            position: relative;
        }

        .coverage-table th:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .coverage-table th.sortable::after {
            content: ' ↕';
            opacity: 0.5;
            font-size: 0.8em;
        }

        .coverage-table th.sorted-asc::after {
            content: ' ↑';
            opacity: 1;
        }

        .coverage-table th.sorted-desc::after {
            content: ' ↓';
            opacity: 1;
        }

        .coverage-table td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--color-border);
        }

        .coverage-table tbody tr:hover {
            background-color: var(--color-hover);
        }

        .coverage-table tbody tr.expandable {
            cursor: pointer;
        }

        .text-center {
            text-align: center;
        }

        .text-right {
            text-align: right;
        }
        """)
    }

    // MARK: - Coverage Bar Styles

    @TagBuilder
    static func coverageBarStyles() -> Tag {
        Text("""
        .coverage-bar-container {
            width: 100%;
            height: 20px;
            background-color: #e9ecef;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }

        .coverage-bar {
            height: 100%;
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.75rem;
            font-weight: 600;
            color: white;
            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
        }

        .coverage-bar.high {
            background-color: var(--color-high);
        }

        .coverage-bar.normal {
            background-color: var(--color-normal);
        }

        .coverage-bar.lower {
            background-color: var(--color-lower);
        }

        .coverage-bar.low {
            background-color: var(--color-low);
        }
        """)
    }

    // MARK: - Expandable Section Styles

    @TagBuilder
    static func expandableSectionStyles() -> Tag {
        Text("""
        .expandable-content {
            display: none;
            background-color: #f8f9fa;
            border-top: 1px solid var(--color-border);
        }

        .expandable-content.expanded {
            display: table-row;
        }

        .expandable-inner {
            padding: 1rem;
        }

        .expand-icon {
            display: inline-block;
            margin-right: 0.5rem;
            transition: transform 0.2s ease;
        }

        .expandable.expanded .expand-icon {
            transform: rotate(90deg);
        }

        .file-name {
            font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
            font-size: 0.9rem;
        }
        """)
    }

    // MARK: - Line Coverage Styles

    @TagBuilder
    static func lineCoverageStyles() -> Tag {
        Text("""
        .line-coverage {
            font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
            font-size: 0.85rem;
            margin: 0;
            width: 100%;
        }

        .line-coverage tbody tr {
            background-color: white;
        }

        .line-coverage tbody tr:hover {
            background-color: #f1f3f5;
        }

        .line-number {
            width: 60px;
            text-align: right;
            color: #6c757d;
            border-right: 1px solid var(--color-border);
            padding-right: 8px;
            user-select: none;
        }

        .line-hits {
            width: 60px;
            text-align: center;
            border-right: 1px solid var(--color-border);
            user-select: none;
        }

        .line-code {
            padding-left: 12px;
            white-space: pre-wrap;
            word-break: break-all;
        }

        .line-covered {
            background-color: var(--color-covered);
        }

        .line-uncovered {
            background-color: var(--color-uncovered);
        }

        .line-neutral {
            background-color: white;
        }
        """)
    }

    // MARK: - Summary Styles

    @TagBuilder
    static func summaryStyles() -> Tag {
        Text("""
        .summary-card {
            background-color: white;
            border: 1px solid var(--color-border);
            border-radius: 8px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-top: 1rem;
        }

        .summary-item {
            text-align: center;
            padding: 1rem;
            background-color: #f8f9fa;
            border-radius: 4px;
        }

        .summary-label {
            font-size: 0.875rem;
            color: #6c757d;
            margin-bottom: 0.5rem;
        }

        .summary-value {
            font-size: 2rem;
            font-weight: 700;
        }
        """)
    }

    // MARK: - Utility Styles

    @TagBuilder
    static func utilityStyles() -> Tag {
        Text("""
        .mt-1 { margin-top: 0.5rem; }
        .mt-2 { margin-top: 1rem; }
        .mt-3 { margin-top: 1.5rem; }
        .mb-1 { margin-bottom: 0.5rem; }
        .mb-2 { margin-bottom: 1rem; }
        .mb-3 { margin-bottom: 1.5rem; }

        .font-mono {
            font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
        }

        .font-bold {
            font-weight: 600;
        }

        .text-muted {
            color: #6c757d;
        }

        .text-small {
            font-size: 0.875rem;
        }
        """)
    }

    // MARK: - Responsive Styles

    @TagBuilder
    static func responsiveStyles() -> Tag {
        Text("""
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }

            h1 {
                font-size: 1.5rem;
            }

            .coverage-table th,
            .coverage-table td {
                padding: 8px 10px;
                font-size: 0.875rem;
            }

            .summary-grid {
                grid-template-columns: 1fr;
            }

            .line-coverage {
                font-size: 0.75rem;
            }
        }
        """)
    }

    // MARK: - All Styles Combined

    @TagBuilder
    static func allStyles() -> Tag {
        colorScheme()
        baseStyles()
        coverageColors()
        tableStyles()
        coverageBarStyles()
        expandableSectionStyles()
        lineCoverageStyles()
        summaryStyles()
        utilityStyles()
        responsiveStyles()
    }
}
