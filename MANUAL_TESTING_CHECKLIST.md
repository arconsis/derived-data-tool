# Manual Browser Testing Checklist - HTML Coverage Report

## Test File
- **File:** `test-coverage-report.html`
- **Date:** 2026-03-02
- **Purpose:** Verify HTML coverage report functionality across multiple browsers

## Browser Testing Instructions

### How to Open the File
```bash
# From the project directory
open test-coverage-report.html
```

Or manually:
1. Navigate to project directory in Finder
2. Right-click `test-coverage-report.html`
3. Select "Open With" → Choose browser

---

## Testing Checklist

### ✅ Chrome Testing

#### 1. Table Sorting
- [ ] Click "Target" header → Table sorts alphabetically
- [ ] Click "Coverage" header → Table sorts by percentage (high to low)
- [ ] Click "Lines" header → Table sorts numerically
- [ ] Click "Files" header → Table sorts numerically
- [ ] Click same header twice → Reverses sort order
- [ ] Sort indicators (↑/↓) appear correctly on sorted column
- [ ] Expandable content stays with parent row after sorting

#### 2. Expand/Collapse Functionality
- [ ] Click "MyApp" row → Target expands to show files table
- [ ] Click again → Target collapses
- [ ] Expand "MyApp" → Click "ViewController.swift" → Shows line-by-line coverage
- [ ] Click arrow icon changes from ▶ to ▼ when expanded
- [ ] Multiple items can be expanded simultaneously
- [ ] Nested expansion works (target → file → lines)

#### 3. Coverage Bars
- [ ] Coverage bars display for all items
- [ ] Bar width matches percentage (92.5% bar is ~92.5% wide)
- [ ] Colors are correct:
  - Green (high): ≥ 80% coverage (MyApp: 92.5%, ViewController: 95%, Model: 88.5%)
  - Yellow (normal): 60-79% coverage (MyAppTests: 75%)
  - Red (low): < 60% coverage (LowCoverageTarget: 45%)
- [ ] Percentage text appears inside bars
- [ ] Bars have gradient effect

#### 4. Coverage Colors
- [ ] Summary card shows 85.50% in green (coverage-high class)
- [ ] High coverage items (>80%) display in green
- [ ] Normal coverage items (60-80%) display in yellow/orange
- [ ] Low coverage items (<60%) display in red

#### 5. Line-by-Line Coverage
- [ ] Expand ViewController.swift to see line coverage
- [ ] Line numbers appear on left (1, 2, 3, 4, 5)
- [ ] Hit counts appear (42, 42, 42, 0, 42)
- [ ] Covered lines have green background (lines 1, 2, 3, 5)
- [ ] Uncovered lines have red background (line 4 with 0 hits)
- [ ] Code is displayed in monospace font
- [ ] Green/red border appears on left of covered/uncovered lines

#### 6. Visual Design
- [ ] Page loads without visual glitches
- [ ] Text is readable (proper contrast)
- [ ] Spacing and padding look correct
- [ ] Tables are properly aligned
- [ ] Summary cards display in grid layout
- [ ] No overlapping elements

#### 7. Console Errors
- [ ] Open DevTools (F12 or Cmd+Option+I)
- [ ] Check Console tab
- [ ] Verify "HTML Coverage Report loaded successfully" message appears
- [ ] Verify no error messages (red text)
- [ ] Verify no warning messages about missing resources

#### 8. Network Dependencies
- [ ] Open DevTools → Network tab
- [ ] Refresh page
- [ ] Verify ONLY the HTML file loads
- [ ] Verify no external CSS/JS requests
- [ ] Verify no failed network requests
- [ ] Verify no CDN requests (no jquery, bootstrap, etc.)

#### 9. Responsive Design (Optional)
- [ ] Open DevTools → Toggle device toolbar (Cmd+Shift+M)
- [ ] View on iPhone size (375px width)
- [ ] Verify layout adjusts for mobile
- [ ] Verify table remains usable (may require horizontal scroll)
- [ ] Verify summary cards stack vertically

---

### ✅ Firefox Testing

Repeat all checks from Chrome section:
- [ ] Table Sorting works correctly
- [ ] Expand/Collapse works correctly
- [ ] Coverage Bars display correctly
- [ ] Coverage Colors match thresholds
- [ ] Line-by-Line Coverage displays correctly
- [ ] Visual Design looks correct
- [ ] No Console Errors (F12 → Console)
- [ ] No External Dependencies (F12 → Network)

---

### ✅ Safari Testing

Repeat all checks from Chrome section:
- [ ] Table Sorting works correctly
- [ ] Expand/Collapse works correctly
- [ ] Coverage Bars display correctly
- [ ] Coverage Colors match thresholds
- [ ] Line-by-Line Coverage displays correctly
- [ ] Visual Design looks correct
- [ ] No Console Errors (Cmd+Option+C → Console)
- [ ] No External Dependencies (Network tab)

---

## Expected Results Summary

### Table Sorting
- **Expected:** Clicking headers sorts table. Arrow indicators show sort direction. Content stays connected after sort.
- **Technology:** Vanilla JavaScript `sortTable()` function

### Expandable Sections
- **Expected:** Clicking rows toggles expansion. Arrow icon rotates. Nested expansion works.
- **Technology:** Vanilla JavaScript `toggleExpandable()` function

### Coverage Bars
- **Expected:** Visual bars match percentages. Gradient colors indicate coverage level.
- **Colors:**
  - ≥80%: Green gradient (#28a745 to #20c997)
  - 60-79%: Yellow gradient (#ffc107 to #ffca2c)
  - 40-59%: Orange gradient (#fd7e14 to #ff922b)
  - <40%: Red gradient (#dc3545 to #e4606d)

### Line Coverage
- **Expected:** Monospace font. Line numbers left-aligned. Hit counts right-aligned. Color-coded backgrounds.
- **Colors:**
  - Covered: Green background (#d4edda) with green border
  - Uncovered: Red background (#f8d7da) with red border

### Self-Contained
- **Expected:** Zero external dependencies. All CSS inline in `<style>` tag. All JS inline in `<script>` tag.
- **Verification:** Network tab shows only the HTML file loads.

---

## Testing Status

| Browser | Tested | Pass/Fail | Notes |
|---------|--------|-----------|-------|
| Chrome  | ⬜     |           |       |
| Firefox | ⬜     |           |       |
| Safari  | ⬜     |           |       |

---

## Issues Found

*Document any issues discovered during testing:*

### Issue 1
- **Browser:**
- **Description:**
- **Steps to Reproduce:**
- **Expected:**
- **Actual:**
- **Severity:** Critical / High / Medium / Low

---

## Sign-Off

- [ ] All features verified in Chrome
- [ ] All features verified in Firefox
- [ ] All features verified in Safari
- [ ] No console errors in any browser
- [ ] No external dependencies loaded
- [ ] Report is fully self-contained
- [ ] Visual design is consistent across browsers

**Tester:** _________________
**Date:** _________________
**Status:** ⬜ PASS / ⬜ FAIL

---

## Additional Notes

*Any additional observations or recommendations:*
