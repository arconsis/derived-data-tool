# Manual Verification Guide: PR Comment Feature

This guide explains how to manually verify the `pr-comment` command with a real GitHub Pull Request.

## Prerequisites

1. **GitHub Token**: You need a GitHub Personal Access Token with `repo` scope
   - Create one at: https://github.com/settings/tokens
   - Required permissions: `repo` (Full control of private repositories)

2. **Test Repository**: Access to a GitHub repository where you can create a PR
   - Can be a personal test repo or any repo where you have write access

3. **Coverage Data**: The repository should have coverage data generated
   - Run your tests with coverage enabled
   - Generate coverage report using `derived-data-tool`

## Verification Steps

### Step 1: Set up GITHUB_TOKEN

```bash
export GITHUB_TOKEN="your_personal_access_token_here"
```

Verify it's set:
```bash
echo $GITHUB_TOKEN
```

### Step 2: Create a Test Pull Request

1. Create a new branch in your test repository
2. Make some changes (add/modify files)
3. Commit and push the branch
4. Create a Pull Request on GitHub
5. Note the PR number (e.g., #123)

### Step 3: Generate Coverage Data

Ensure you have coverage data:
```bash
# Run your tests with coverage
# Example for Swift projects:
swift test --enable-code-coverage

# Generate the coverage report
swift run derived-data-tool coverage
```

### Step 4: Run the PR Comment Command

```bash
swift run derived-data-tool pr-comment \
  --pr-number <PR_NUMBER> \
  --repo <REPO_NAME> \
  --owner <OWNER_NAME>
```

Example:
```bash
swift run derived-data-tool pr-comment \
  --pr-number 123 \
  --repo derived-data-tool \
  --owner my-username
```

### Step 5: Verify the Comment

1. Go to your Pull Request on GitHub
2. Check that a new comment was posted with:
   - ✅ Overall coverage percentage
   - ✅ Coverage change indicator (emoji and diff)
   - ✅ Detailed metrics table (Lines, Functions, Branches)
   - ✅ Top changed files section (if applicable)
   - ✅ New untested files section (if applicable)
   - ✅ Marker comment `<!-- derived-data-tool-pr-comment -->`

### Step 6: Test Comment Updates

1. Make changes to your code and update coverage:
   ```bash
   # Make code changes
   # Run tests again
   swift test --enable-code-coverage

   # Regenerate coverage
   swift run derived-data-tool coverage
   ```

2. Run the pr-comment command again (same PR):
   ```bash
   swift run derived-data-tool pr-comment \
     --pr-number 123 \
     --repo derived-data-tool \
     --owner my-username
   ```

3. Verify on GitHub that:
   - ✅ The existing comment was **updated** (not duplicated)
   - ✅ Coverage metrics reflect the new data
   - ✅ No duplicate comments were created

### Step 7: Test Configuration Options

Update `.xcrtool.yml`:
```yaml
tools:
  github_exporter:
    pr_comment_top_files: 10  # Show top 10 files instead of 5
    pr_comment_include_untested: false  # Hide untested files section
```

Run the command again and verify the output respects these settings.

## Expected Comment Format

The posted comment should look like this:

```markdown
<!-- derived-data-tool-pr-comment -->
# 📊 Coverage Report

## Overall Coverage
**68.5%** 📉 (-1.2%)

### Details
| Metric | Coverage | Change |
|--------|----------|--------|
| Lines | 68.5% | -1.2% |
| Functions | 72.3% | +0.5% |
| Branches | 65.1% | -2.1% |

## 📈 Top Changed Files
| File | Coverage | Change |
|------|----------|--------|
| src/Helper.swift | 45.2% | -15.3% ⚠️ |
| src/Parser.swift | 78.9% | +8.7% ✅ |
| src/Formatter.swift | 91.2% | +3.4% ✅ |

## ⚠️ New Untested Files
| File | Executable Lines |
|------|------------------|
| src/NewFeature.swift | 45 |
| src/NewHelper.swift | 23 |
```

## Troubleshooting

### Error: "GITHUB_TOKEN not found"
- Ensure `export GITHUB_TOKEN="..."` was run in the same terminal session
- Verify with `echo $GITHUB_TOKEN`

### Error: "HTTP 401 Unauthorized"
- Check your token has `repo` scope
- Verify the token hasn't expired

### Error: "HTTP 404 Not Found"
- Verify the owner, repo, and PR number are correct
- Ensure the PR exists and you have access

### Error: "No coverage data found"
- Run `swift test --enable-code-coverage` first
- Run `swift run derived-data-tool coverage` to generate the report

### Comment Not Updating
- Check that the marker comment `<!-- derived-data-tool-pr-comment -->` exists
- The command searches for this marker to find existing comments

## Success Criteria

✅ Command posts a formatted coverage comment to GitHub PR
✅ Comment includes all required sections (overall, details, top files)
✅ Uses GITHUB_TOKEN for authentication
✅ Updates existing comment instead of creating duplicates
✅ Configuration options in `.xcrtool.yml` are respected
✅ Error messages are clear and helpful

---

**Note**: This is a manual verification step that requires a real GitHub repository and token.
Automated tests cover the formatting logic and API client, but end-to-end integration must be
tested manually.
