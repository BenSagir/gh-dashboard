# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.0.0] - 2026-10-07

First public release.

### Added

- Table of a repository's open PRs: per-reviewer status, CI, approvals and a
  merge verdict, with clickable titles.
- `--all`, `--mine` and `--review` filters, `--version`, `--help`.
- Batched fetching with automatic retry at smaller batch sizes, so large
  repositories don't hit `HTTP 504` timeouts. Configurable with
  `GH_DASHBOARD_BATCH`.
- `GH_DASHBOARD_LIMIT` (default 200) for the maximum number of PRs.
- Automatic fallback to another logged-in `gh` account when the active one
  can't see the repository, without changing the active account.
- Windows support through Git Bash, including `jq.exe` CRLF output.
- `NO_COLOR` and `CLICOLOR_FORCE` support. Colors and links are off when
  output is piped.
- Offline test suite and CI on Linux, macOS (bash 3.2) and Windows.

[Unreleased]: https://github.com/BenSagir/gh-dashboard/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/BenSagir/gh-dashboard/releases/tag/v1.0.0
