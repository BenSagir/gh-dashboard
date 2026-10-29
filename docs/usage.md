# Usage

- [Running it](#running-it)
- [Options](#options)
- [Reading the table](#reading-the-table)
  - [REVIEWERS](#reviewers)
  - [CI](#ci)
  - [APPROVALS](#approvals)
  - [MERGE](#merge)
- [Settings](#settings)
- [Colors and links](#colors-and-links)
- [Examples](#examples)

## Running it

Run `gh dashboard` from inside a clone of a GitHub repository, in any
folder of the working tree:

```bash
cd ~/code/my-project
gh dashboard
```

It shows that repository's open pull requests, newest first. While it loads,
a progress bar shows how many PRs have been fetched out of the total:

```
 Fetching PRs ██████████████████████░░░░░░░░ 40/57
```

## Options

| Option | Shows |
|---|---|
| *(none)* or `--all` | All open PRs |
| `--mine` | Open PRs you authored |
| `--review` | Open PRs you're a reviewer on, see below |
| `--author NAME` | Open PRs opened by NAME, see below |
| `--author-list` | Who has open PRs, with counts, see below |
| `--verbose` | Totals and each fetch step, see below |
| `--version`, `-v` | The installed version |
| `--help`, `-h` | Help |

Pass at most one of `--all`, `--mine`, `--review` and `--author`.
`--author-list` and `--verbose` can be added to any of them. "You" means the GitHub account the dashboard uses
for the repository, normally your active `gh` account (see
[several accounts](installation.md#several-github-accounts)).

### Which PRs `--review` shows

Every open PR, except your own, where you are a reviewer:

- your review is requested and you haven't reviewed yet, directly or
  through a team you're on
- you approved it
- you requested changes
- you left review comments
- your review was dismissed

GitHub stops listing you as "requested" once you submit a review, so the
dashboard combines two searches (`review-requested:` and `reviewed-by:`)
to keep PRs you've already reviewed in the list.

### `--author`

Shows open PRs opened by one or more people:

```bash
gh dashboard --author alice          # one person
gh dashboard --author alice,bob      # several, comma-separated
gh dashboard --author=alice          # same as --author alice
gh dashboard --author dependabot     # bots work too
```

- Use the GitHub login, as shown in the AUTHOR column. Case doesn't matter,
  and a leading `@` is fine (`@alice`).
- `@me` means you, the same as `--mine`.
- Bots can be written as shown in the table (`dependabot`) or with
  `[bot]` (`dependabot[bot]`).
- A name that doesn't exist shows an empty table, not an error.
- Only one of `--all`, `--mine`, `--review` and `--author` can be used at a
  time.

### `--author-list`

Lists everyone with open PRs and how many each has, most first:

```
 Open PR authors — acme/widgets
 14 PRs by 7 authors

   PRS  AUTHOR
     3  alice
     3  bob
     2  dave
     1  dependabot (bot)
     1  (deleted user)
```

It only asks GitHub for each PR's number and author, so it takes a second
or two even on big repositories, and it counts every open PR, regardless of
`GH_DASHBOARD_LIMIT`. Combine it with a filter to narrow it down:

```bash
gh dashboard --author-list              # everyone with open PRs
gh dashboard --review --author-list     # whose PRs you're reviewing
```

Then look at one person's PRs with `gh dashboard --author <name>`.

### `--verbose`

Prints what the dashboard is doing, before the table:

```
 Search: repo:acme/widgets is:pr is:open sort:created-desc
 Found 57 open PRs by 12 authors: alice 10, bob 8, carol 7, dave 5, erin 4, … (+7 more)
 Fetching details, 20 PRs per request
   batch 1: 20 PRs in 5.5s (20/57)
   request failed (HTTP 504: 504 Gateway Timeout ...), retrying with 10
   batch 2: 10 PRs in 2.6s (30/57)
   ...
 Fetched 57 PRs in 19.4s
```

Useful to see why a run is slow, which batches GitHub timed out on, or what
search was sent. The log goes to stderr, so `gh dashboard --verbose > prs.txt`
saves only the table.

## Reading the table

```
#      PR                                 AUTHOR         REVIEWERS                      CI         APPROVALS   MERGE
#102   Fix flaky test                     bob            ◷ carol ✓ dave                 ✓ PASS     1/2         ◷ REVIEW
```

| Column | Content |
|---|---|
| `#` | PR number |
| `PR` | Title, clickable in terminals that support links. Drafts end in `[DRAFT]`. |
| `AUTHOR` | GitHub login of the author (`—` for deleted accounts) |
| `REVIEWERS` | Each reviewer and where they stand, see below |
| `CI` | Overall result of the checks on the latest commit |
| `APPROVALS` | Approvals out of total reviewers |
| `MERGE` | What stands between the PR and merging |

Values longer than their column are cut off with `…`.

### REVIEWERS

Everyone who was asked to review **or** has reviewed, alphabetically, each
with their latest state:

| Symbol | Color | Meaning |
|---|---|---|
| `✓ name` | green | Approved |
| `✗ name` | red | Requested changes |
| `💬 name` | orange | Commented without approving or requesting changes |
| `◷ name` | yellow | Review requested and not submitted yet, or their review was dismissed (it no longer counts, so it's needed again) |
| `—` | dim | No reviewers |

Team review requests show the team name, for example `◷ frontend-team`.

### CI

GitHub's combined status for the PR's latest commit, the same result as the
checks summary on the PR page:

| Display | Meaning |
|---|---|
| `✓ PASS` | All required checks passed |
| `✗ FAIL` | A check failed or errored |
| `◷ RUN` | Checks are running or expected |
| `— NONE` | The commit has no checks |

If a run was cancelled and re-run, only the latest run counts.

### APPROVALS

`approved / total reviewers`. Total reviewers is the same set of people as in
the REVIEWERS column, including reviewers who already submitted a review
(GitHub removes them from the "requested" list once they do).

The color follows GitHub's review decision: green when the PR has the
approvals it needs, red when changes are requested, yellow otherwise.

### MERGE

One verdict per PR. When several apply, the first one in this list wins:

| Display | Meaning |
|---|---|
| `◷ DRAFT` | The PR is a draft |
| `✗ CONFLICT` | Merge conflicts with the base branch |
| `✗ CI FAIL` | Checks are failing |
| `✗ CHANGES` | A reviewer requested changes |
| `◷ REVIEW` | Branch protection requires a review that's missing |
| `◷ CI RUN` | Checks are still running |
| `✗ BLOCKED` | Blocked by another rule (e.g. required reviewers, rulesets) |
| `✓ READY` | Can be merged |
| `? <state>` | GitHub hasn't computed mergeability yet (shows its raw state, often `UNKNOWN`). Run again in a few seconds. |

## Settings

Set these as environment variables, for one run or in your shell profile:

| Variable | Default | Meaning |
|---|---|---|
| `GH_DASHBOARD_LIMIT` | `200` | Maximum PRs to show. Fewer loads faster. |
| `GH_DASHBOARD_BATCH` | `20` | PRs per API request. Lower it if you see `HTTP 504` errors; raising it above ~25 tends to cause them. |
| `NO_COLOR` | unset | Any value disables colors and links ([no-color.org](https://no-color.org)) |
| `CLICOLOR_FORCE` | unset | `1` keeps colors and links when output isn't a terminal |

Both numbers must be positive whole numbers.

## Colors and links

Colors and clickable titles are on when the output goes to a terminal and off
when it's piped or redirected, so files stay clean text.

- `NO_COLOR=1` turns them off everywhere. It wins over `CLICOLOR_FORCE`.
- `CLICOLOR_FORCE=1` keeps them on when piping, for pagers that understand
  them.

Clickable links need a terminal that supports OSC 8 hyperlinks, such as
iTerm2, Windows Terminal, GNOME Terminal, Kitty or WezTerm. Elsewhere titles
show as plain text.

## Examples

Only the 30 newest PRs, faster on big repos:

```bash
GH_DASHBOARD_LIMIT=30 gh dashboard
```

Scroll through a long list with colors:

```bash
CLICOLOR_FORCE=1 gh dashboard | less -R
```

Save a plain-text snapshot:

```bash
gh dashboard > prs.txt
```

Short aliases (`gh alias` works on every platform):

```bash
gh alias set mine 'dashboard --mine'
gh alias set rv 'dashboard --review'
gh mine
```

Keep a smaller default in your shell profile (`~/.zshrc`, `~/.bashrc`):

```bash
export GH_DASHBOARD_LIMIT=50
```
