# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2024-09-07

### Added

- `sql/01_setup.sql` — Database, role, and grant creation
- `sql/02_rss_scope.sql` — RSS scope with 5 allowed privileges (no blocked_roles)
- `sql/03_session_policy.sql` — Session policy creation and account-level attachment
- `sql/04_test_governance.sql` — 4 validation tests with verified expected results
- `sql/05_cleanup.sql` — Full teardown script
- `docs/ARCHITECTURE.md` — Component deep dive and dependency graph
- `docs/medium_article.md` — Full Medium article draft
- `tests/TEST_RESULTS.md` — Detailed test evidence
- `README.md` — Enterprise-style documentation with quickstart
- `CONTRIBUTING.md` — Contribution guidelines
- `SECURITY.md` — Security policy and vulnerability reporting
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
- `.github/ISSUE_TEMPLATE/bug_report.md` — Bug report template
- `.github/ISSUE_TEMPLATE/feature_request.md` — Feature request template

### Verified

- Test 1: Read Orders — 5,000 orders / $758.2M revenue (PASS)
- Test 2: Read Customers — Furniture > Machinery > Automobile (PASS)
- Test 3: Blocked Write — INSERT denied by RSS (PASS)
- Test 4: Orders by Status — F=2,511 / O=2,370 / P=119 (PASS)
