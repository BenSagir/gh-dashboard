# How it works

`gh-dashboard` is a single bash script. This page explains what it does, in
order, for anyone debugging it or contributing.

- [1. Repository and account detection](#repository-and-account-detection)
- [2. Fetching PRs](#fetching-prs)
- [3. Rendering](#rendering)
- [Portability](#portability)
- [Known limitations](#known-limitations)

## Repository and account detection

1. `git rev-parse` checks that you're inside a git working tree.
2. `gh repo view` resolves the GitHub repository (`owner/name`) from the
   git remotes, using your active `gh` account.
3. If that fails, for example because the repo is private on a different
   account, the script lists your other logged-in accounts
   (`gh auth status --json hosts`). For each one it gets the token
   (`gh auth token --user <login>`) and retries `gh repo view` with
   `GH_TOKEN` set to that token. The first account that succeeds is used for
   the rest of the run by exporting `GH_TOKEN`.
4. `gh api user` returns the login of the account in use. `--mine` and
   `--review` search with it.

Exporting `GH_TOKEN` affects only the dashboard's own process. It never runs
`gh auth switch`, so your active account is unchanged afterwards.

## Fetching PRs

PRs come from one GraphQL **search** query:

```
repo:<owner/name> is:pr is:open sort:created-desc [author:<you> | review-requested:<you>]
```

For each PR it requests the title, author, draft flag, review decision,
mergeability, up to 20 review requests, up to 20 latest reviews (one per
reviewer) and the **status check rollup state** of the latest commit.

### Why batches

`gh pr list` fetches up to 100 PRs per request and can't be told to use
smaller pages. Computing mergeability and check status for that many PRs can
take longer than GitHub's roughly 10-second limit for GraphQL requests, and
the request fails with `HTTP 504`. So the script pages through the search
itself:

- It asks for `GH_DASHBOARD_BATCH` PRs per request (default 20) and follows
  the `endCursor` until there are no more pages or `GH_DASHBOARD_LIMIT` is
  reached. The last request asks only for what's still needed.
- If a request fails, it halves the batch size and retries the same page,
  down to 1, for up to 4 attempts. After a page succeeds, the batch size
  doubles back toward the configured size.

### Why the rollup state

The CI column uses GitHub's single rollup state for the commit (`SUCCESS`,
`FAILURE`, `ERROR`, `PENDING`, `EXPECTED`) instead of downloading every check
run. That's much cheaper, and more accurate: GitHub only counts the latest
run of each check, so a cancelled run that was later re-run successfully
doesn't show as a failure.

## Rendering

Each search result is reshaped into the same JSON the `gh pr list --json`
command produces, then rendered row by row:

- **Reviewers** are the unique logins from review requests plus latest
  reviews. Each gets the state of their latest review, or "pending" if they
  have none.
- **Approvals** count latest reviews in the `APPROVED` state, out of that
  same reviewer set.
- **Merge** is a single verdict picked by priority, see
  [usage](usage.md#merge).

### Column alignment

bash's `printf '%-30s'` pads by **bytes**, not by what you see on screen.
Color codes are invisible but take bytes, symbols like `✓` take 3 bytes,
and emoji take 2 columns. A small Perl helper (`row`) pads and truncates each
cell by its visible width instead:

- ANSI color codes and OSC 8 hyperlink codes count as zero width.
- Emoji and East Asian wide characters count as two columns.
- Combining marks count as zero.
- Text that doesn't fit is cut and ends in `…`, keeping the color and link
  codes intact.

Column widths are set in one place, `COL_WIDTHS`, which the header,
separator and every row use.

### Colors and links

Colors and [OSC 8 hyperlinks](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda)
are emitted only when stdout is a terminal (`-t 1`), unless `NO_COLOR` or
`CLICOLOR_FORCE` says otherwise. The orange used for comments is color 208
of the 256-color palette.

## Portability

The script targets **bash 3.2**, which is still macOS's `/bin/bash`, and
avoids features that changed since:

- Empty arrays are expanded as `${arr[@]+"${arr[@]}"}`. Under `set -u`,
  bash 3.2 treats a plain `"${arr[@]}"` of an empty array as an unbound
  variable.
- No associative arrays, `mapfile`, `${var,,}` or other bash 4+ features.

On **Windows** (Git Bash), `jq.exe` ends lines with `\r\n`. A stray `\r`
breaks string comparisons, titles and the paging cursor. When `uname`
reports `MINGW*`, `MSYS*` or `CYGWIN*`, the script wraps `jq` to strip
carriage returns. `.gitattributes` keeps the script itself on LF endings,
since Git for Windows' default `core.autocrlf=true` would otherwise convert
it on checkout and bash would fail on the `\r`s.

CI runs the test suite on Ubuntu (bash 5), macOS (bash 3.2) and Windows
(Git Bash with the real `jq.exe`).

## Known limitations

- **Search delay:** brand-new PRs can take up to a minute to appear,
  because the data comes from GitHub search.
- **Search cap:** GitHub search returns at most 1,000 results, so at most
  1,000 PRs can be shown.
- **Re-requested reviewers:** a reviewer who approved and was then asked to
  review again still shows their last state (`✓`), not pending.
- **Large review lists:** only the first 20 review requests and 20 latest
  reviews per PR are fetched.
- **Account fallback is github.com only:** with GitHub Enterprise Server,
  the active account is used and other accounts aren't tried.
- **Speed:** rendering runs `jq` several times per PR. 50 PRs take a few
  seconds on top of the API time.
