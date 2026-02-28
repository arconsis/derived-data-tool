# Markdown Default Format Integration Test

## Purpose
Verify that markdown format still works as the default when no `--format` flag is specified, ensuring backward compatibility after adding CSV and JSON export formats.

## Test Script
`test-markdown-default.sh` - Verifies:
1. Build succeeds
2. Format option exists in CLI help
3. MarkDownEncoder implementation exists
4. Markdown is the default format in code
5. No regressions in unit tests
6. Markdown content generation works

## How to Run
```bash
./test-markdown-default.sh
```

Note: The script performs code-level verification. Full end-to-end testing requires actual .xcresult files from Xcode test runs.

## Expected Behavior
When running `swift run derived-data-tool coverage` without the `--format` flag:
- The tool should default to markdown format
- Output file should be in markdown format
- Behavior should be identical to pre-feature implementation

## Verification Results
See `../INTEGRATION_TEST_RESULTS.md` for detailed test results.

## Related Subtask
- ID: subtask-2-3
- Phase: End-to-End Integration Testing
- Status: Completed
