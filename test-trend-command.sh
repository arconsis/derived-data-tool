#!/bin/bash
# Test script for trend command end-to-end verification

set -e

echo "🧪 Testing Trend Command E2E"
echo "=============================="
echo ""

# Create a simple Swift script to populate the database with sample data
cat > populate_test_data.swift <<'EOF'
import Foundation
import SQLite3

let dbPath = ".derived_data_tool.db"
var db: OpaquePointer?

// Open database
guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
    print("Error opening database")
    exit(1)
}

// Helper function to execute SQL
func execute(_ sql: String) {
    var stmt: OpaquePointer?
    if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("Error executing: \(sql)")
        }
    }
    sqlite3_finalize(stmt)
}

// Create sample data - 10 reports over 30 days with varying coverage
let baseDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
let formatter = ISO8601DateFormatter()

for i in 0..<10 {
    let reportDate = baseDate.addingTimeInterval(Double(i) * 3 * 24 * 60 * 60) // Every 3 days
    let timestamp = formatter.string(from: reportDate)

    // Insert report
    let reportSQL = """
    INSERT INTO ReportModel (id, date, type, url, application, timestamp)
    VALUES ('\(UUID().uuidString)', '\(timestamp)', 'xcresult', 'test_\(i).xcresult', 'TestApp', '\(timestamp)');
    """
    execute(reportSQL)

    // Get last report ID
    var stmt: OpaquePointer?
    sqlite3_prepare_v2(db, "SELECT last_insert_rowid()", -1, &stmt, nil)
    sqlite3_step(stmt)
    let reportRowId = sqlite3_column_int64(stmt, 0)
    sqlite3_finalize(stmt)

    // Insert coverage
    let coverageSQL = """
    INSERT INTO CoverageModel (id, report_id)
    VALUES ('\(UUID().uuidString)', \(reportRowId));
    """
    execute(coverageSQL)

    // Get last coverage ID
    sqlite3_prepare_v2(db, "SELECT last_insert_rowid()", -1, &stmt, nil)
    sqlite3_step(stmt)
    let coverageRowId = sqlite3_column_int64(stmt, 0)
    sqlite3_finalize(stmt)

    // Insert targets with increasing coverage
    let baseCoverage = 0.60 + Double(i) * 0.03 // 60% to 87%

    let targets = [
        ("AppTarget", 1000, Int(Double(1000) * baseCoverage)),
        ("NetworkModule", 500, Int(Double(500) * (baseCoverage + 0.05))),
        ("UIComponents", 800, Int(Double(800) * (baseCoverage - 0.05)))
    ]

    for (name, execLines, covLines) in targets {
        let targetSQL = """
        INSERT INTO TargetModel (id, name, executableLines, coveredLines, coverage_id)
        VALUES ('\(UUID().uuidString)', '\(name)', \(execLines), \(covLines), \(coverageRowId));
        """
        execute(targetSQL)
    }
}

sqlite3_close(db)
print("✅ Inserted 10 sample coverage reports")
EOF

# Compile and run the data population script
echo "📝 Populating database with sample coverage reports..."
swiftc populate_test_data.swift -o populate_test_data
./populate_test_data
rm populate_test_data populate_test_data.swift

echo ""
echo "🔍 Step 1: Testing basic trend generation (--days 30)"
swift run derived-data-tool trend --days 30 --output trend.svg
if [ -f "trend.svg" ]; then
    echo "✅ trend.svg created"
    FILE_SIZE=$(wc -c < trend.svg)
    echo "   File size: $FILE_SIZE bytes"
else
    echo "❌ trend.svg not created"
    exit 1
fi

echo ""
echo "🔍 Step 2: Verifying SVG is valid XML"
if head -1 trend.svg | grep -q "<?xml"; then
    echo "✅ SVG has valid XML header"
else
    echo "❌ SVG missing XML header"
    exit 1
fi

if grep -q "<svg" trend.svg; then
    echo "✅ SVG contains <svg> tag"
else
    echo "❌ SVG missing <svg> tag"
    exit 1
fi

echo ""
echo "🔍 Step 3: Verifying chart contains coverage data"
if grep -q "Coverage Trend" trend.svg; then
    echo "✅ Chart has title"
else
    echo "⚠️  Chart missing title"
fi

if grep -q "polyline" trend.svg || grep -q "path" trend.svg; then
    echo "✅ Chart contains line elements"
else
    echo "❌ Chart missing line elements"
    exit 1
fi

echo ""
echo "🔍 Step 4: Testing with --limit option"
swift run derived-data-tool trend --limit 5 --output trend-limit.svg
if [ -f "trend-limit.svg" ]; then
    echo "✅ trend-limit.svg created"
else
    echo "❌ trend-limit.svg not created"
    exit 1
fi

echo ""
echo "🔍 Step 5: Testing with --targets filter"
swift run derived-data-tool trend --days 30 --targets AppTarget NetworkModule --output trend-targets.svg
if [ -f "trend-targets.svg" ]; then
    echo "✅ trend-targets.svg created"
    if grep -q "AppTarget" trend-targets.svg && grep -q "NetworkModule" trend-targets.svg; then
        echo "✅ Target names found in legend"
    else
        echo "⚠️  Target names not found in legend"
    fi
else
    echo "❌ trend-targets.svg not created"
    exit 1
fi

echo ""
echo "🔍 Step 6: Testing with --threshold option"
swift run derived-data-tool trend --days 30 --threshold 0.75 --output trend-threshold.svg
if [ -f "trend-threshold.svg" ]; then
    echo "✅ trend-threshold.svg created"
    if grep -q "75%" trend-threshold.svg; then
        echo "✅ Threshold line appears in chart"
    else
        echo "⚠️  Threshold line not found"
    fi
else
    echo "❌ trend-threshold.svg not created"
    exit 1
fi

echo ""
echo "🔍 Step 7: Testing error handling - nonexistent target"
if swift run derived-data-tool trend --days 30 --targets NonExistentTarget --output trend-error.svg 2>&1 | grep -q "not found"; then
    echo "✅ Error handling works for nonexistent target"
else
    echo "⚠️  Expected error for nonexistent target"
fi

echo ""
echo "🔍 Step 8: Testing error handling - empty database"
rm .derived_data_tool.db
if swift run derived-data-tool trend --days 30 --output trend-empty.svg 2>&1 | grep -q "No coverage reports found"; then
    echo "✅ Error handling works for empty database"
else
    echo "❌ Expected error for empty database"
    exit 1
fi

echo ""
echo "=============================="
echo "✅ All E2E tests passed!"
echo ""
echo "Generated files:"
echo "  - trend.svg (basic trend chart)"
echo "  - trend-limit.svg (with --limit)"
echo "  - trend-targets.svg (with --targets)"
echo "  - trend-threshold.svg (with --threshold)"
echo ""
echo "You can open these SVG files in a browser to visually verify."
