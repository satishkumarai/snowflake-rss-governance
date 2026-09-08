# Contributing

Thank you for your interest in contributing to this project.

## How to Contribute

1. Fork the repository
2. Create a branch for your change (`git checkout -b feature/my-change`)
3. Make your changes and test them against a Snowflake account
4. Commit with a clear message describing the change
5. Open a Pull Request against `main`

## Guidelines

- All SQL must be tested against `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1`
- Do not add `blocked_roles` to any RSS scope — see [README.md](README.md#accountadmin-lockout-warning)
- Include expected results for any new test cases
- Follow the existing file naming convention (`NN_description.sql`)
- Run `sql/05_cleanup.sql` from a SQL worksheet (not CoCo) after testing

## Reporting Issues

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) for bugs and the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) for enhancements.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
