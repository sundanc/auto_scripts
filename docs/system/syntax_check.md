# Script Syntax Checker

## Summary
Scans all IT Arsenal scripts for syntax errors and potential code issues to ensure reliable execution.

## Location
`/system/syntax_check.sh`

## Purpose
The Script Syntax Checker is designed to proactively detect potential issues in bash scripts before they cause problems during execution. It performs both basic syntax validation and more advanced static code analysis to identify common coding mistakes.

By using this tool regularly, you can ensure that all scripts in the IT Arsenal repository maintain a high standard of quality and reliability.

The tool checks for:
- Basic syntax errors (bash parser errors)
- Unquoted variables in conditionals
- Incorrect comparison operators (= vs ==)
- Missing or mismatched control flow statements (if/fi, for/done, etc.)
- Duplicate function definitions
- Best practices violations

## Usage

```bash
./system/syntax_check.sh
```

Running the script with no arguments will check all scripts in the IT Arsenal directory.

## Output

The script produces both terminal output and a detailed report file:

- Terminal output shows a summary of issues found
- A detailed report is saved to `/logs/syntax_report.txt`
- Each issue found includes line number and description for easy fixing

Example output:

