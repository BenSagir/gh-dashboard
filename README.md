# gh dashboard

[![tests](https://github.com/BenSagir/gh-dashboard/actions/workflows/tests.yml/badge.svg)](https://github.com/BenSagir/gh-dashboard/actions/workflows/tests.yml)

English | [עברית](README.he.md)

A [GitHub CLI](https://cli.github.com) extension that shows a repository's
open pull requests in one table, with more at a glance than GitHub's web PR
list: **every reviewer's status, CI, approval count and whether it can be
merged**.

```
 GitHub PR Dashboard — acme/widgets
 Updated: 09:41:00   PRs: 7

#      PR                                 AUTHOR         REVIEWERS                      CI         APPROVALS   MERGE
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#101   Add login page                     alice          —                              ✓ PASS     0/0         ✓ READY
#102   Fix flaky test                     bob            ◷ carol ✓ dave                 ✓ PASS     1/2         ◷ REVIEW
#103   Refactor API client                carol          ✗ alice 💬 bob                 ✓ PASS     0/2         ✗ CHANGES
#104   Update dependencies [DRAFT]        dependabot     —                              ◷ RUN      0/0         ◷ DRAFT
#105   Rename config keys                 dave           —                              ✗ FAIL     0/0         ✗ CONFLICT
#107   Waiting on CI                      bob            ✓ carol                        ◷ RUN      1/1         ◷ CI RUN
#108   No CI configured                   carol          —                              — NONE     0/0         ✗ BLOCKED

 Legend: ✓ Approved  ◷ Pending  ✗ Changes/Problem  💬 Comment
```

In a terminal, statuses are colored and every PR title is a clickable link.

## Quick start

**1. Install** (macOS shown, for Windows and Linux see [Install](#install)):

```bash
brew install gh jq
gh auth login
gh extension install BenSagir/gh-dashboard
```

**2. Run** inside a clone of your repository:

```bash
gh dashboard            # all open PRs
gh dashboard --mine     # PRs you opened
gh dashboard --review   # PRs waiting for your review
```

**3. Update** when a new version is out:

```bash
gh extension upgrade dashboard
```

## Features

- **Per-reviewer status**: who approved, who requested changes, who only
  commented and who hasn't reviewed yet, including teams.
- **One merge verdict per PR**: draft, conflict, failing CI, changes
  requested, waiting for review, CI running, blocked or ready.
- **Filters**: all open PRs, only yours, or only the ones waiting on your
  review.
- **Handles big repos**: fetches in small batches and retries with smaller
  ones if GitHub times out, so hundreds of open PRs load without `HTTP 504`.
- **Work and personal accounts**: if your active `gh` account can't see the
  repo, it uses another logged-in account that can, without switching your
  active account.
- **macOS, Linux and Windows** (Git Bash), tested on all three in CI.

## Install

You need the [GitHub CLI](https://cli.github.com) (logged in) and
[jq](https://jqlang.org).

**macOS**

```bash
brew install gh jq
gh auth login
gh extension install BenSagir/gh-dashboard
```

**Windows** (PowerShell, then use Windows Terminal)

```powershell
winget install Git.Git GitHub.cli jqlang.jq
gh auth login
gh extension install BenSagir/gh-dashboard
```

**Linux**: install `gh` and `jq` with your package manager, then
`gh auth login` and `gh extension install BenSagir/gh-dashboard`.

Full instructions, including WSL, installing without the extension system,
upgrading and uninstalling: **[docs/installation.md](docs/installation.md)**.

## Usage

Run it inside a clone of any GitHub repository:

```bash
gh dashboard            # all open PRs
gh dashboard --mine     # PRs you opened
gh dashboard --review   # PRs waiting for your review
```

| Option | |
|---|---|
| `--all` | All open PRs (default) |
| `--mine` | PRs you authored |
| `--review` | PRs that request your review |
| `--version`, `-v` | Print the version |
| `--help`, `-h` | Print help |

| Environment variable | Default | |
|---|---|---|
| `GH_DASHBOARD_LIMIT` | `200` | Maximum number of PRs to show |
| `GH_DASHBOARD_BATCH` | `20` | PRs fetched per API request |
| `NO_COLOR` | | Set to disable colors and links |
| `CLICOLOR_FORCE` | | Set to `1` to keep colors when piping |

What every column and symbol means: **[docs/usage.md](docs/usage.md)**.

## Documentation

- [מדריך בעברית (Hebrew guide)](README.he.md): what it is, install, usage, columns, common problems
- [Installation](docs/installation.md): macOS, Windows, Linux, WSL, upgrading, uninstalling
- [Usage](docs/usage.md): options, columns, statuses, settings, examples
- [Troubleshooting](docs/troubleshooting.md): common errors and fixes
- [How it works](docs/how-it-works.md): API calls, batching, retries, account fallback, known limitations
- [Contributing](CONTRIBUTING.md): running the tests, project layout, making a release
- [Changelog](CHANGELOG.md)

## License

[MIT](LICENSE)
