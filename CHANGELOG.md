# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.4.1] - 2026-10-29

### Fixed

- The progress bar crashed with `bar…: unbound variable` in terminals using a
  UTF-8 locale (most macOS and Linux setups). Under such a locale, macOS's
  bash 3.2 read the start of the `█` character as part of a variable name.
  The tests now also run the dashboard under a UTF-8 locale and check for
  this pattern.

## [1.4.0] - 2026-10-29

### Changed

- The progress bar moves smoothly while each batch downloads instead of
  jumping 0 → 20 → 40. It advances at the speed measured on your machine
  and network, holds one PR short of the batch's end until the batch
  arrives, then jumps to the real count. To measure the speed, the first
  two detail requests fetch 1 and 5 PRs (about a second extra, only when
  the bar is shown).

### Added

- `GH_DASHBOARD_PROGRESS`: `0` hides the progress bar, `1` shows it even
  when stderr isn't a terminal.

## [1.3.0] - 2026-10-29

### Added

- Progress bar with the real total while fetching (`Fetching PRs ███░░ 40/57`),
  in place of the plain counter.
- `--verbose`: prints the search, how many open PRs there are and by whom,
  then one line per fetched batch with its time, retries, and the total
  time. Written to stderr, so the table output is unchanged.
- `--author-list`: lists everyone with open PRs and their counts, without
  fetching the PR details, so it finishes in a second or two. Works with
  `--mine`, `--review` and `--author`.

## [1.2.0] - 2026-10-22

### Added

- `--author NAME` (or `--author=NAME`) shows open PRs opened by NAME.
  Several names can be comma-separated (`--author alice,bob`), `@me` means
  you, and bots work by the name shown in the table (`dependabot`).

### Changed

- Passing two of `--all`, `--mine`, `--review` and `--author` now says which
  two were given, instead of "Too many arguments".

## [1.1.0] - 2026-10-22

### Fixed

- `--review` was empty for PRs you had already reviewed. GitHub stops
  listing you as a requested reviewer once you submit a review, so the old
  `review-requested:` search missed them. `--review` now shows every open
  PR you're a reviewer on: requested, approved, changes requested,
  commented or dismissed. Your own PRs are left out. A dismissed review
  shows as `◷` (pending), since it no longer counts.

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

[Unreleased]: https://github.com/BenSagir/gh-dashboard/compare/v1.4.1...HEAD
[1.4.1]: https://github.com/BenSagir/gh-dashboard/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/BenSagir/gh-dashboard/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/BenSagir/gh-dashboard/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/BenSagir/gh-dashboard/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/BenSagir/gh-dashboard/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/BenSagir/gh-dashboard/releases/tag/v1.0.0
