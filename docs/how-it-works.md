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

### First pass: totals and authors

Before fetching the details, the dashboard can run a light version of the
search that asks only for the number of matches (`issueCount`) and, if
needed, each PR's number and author. GitHub answers it quickly because it
doesn't compute mergeability or CI for it.

| When | What it fetches |
|---|---|
| Output is a terminal | One PR per search, just to read the total for the progress bar (and time a request) |
| `--verbose` or `--author-list` | Every match, 100 per request: number and author |
| Output piped, no `--verbose` | Nothing; this pass is skipped |

`--author-list` stops after this pass. Everything else continues with the
detail fetch below.

### Progress bar animation

A detail request returns its whole batch at once, after a few seconds, so a
bar that only moved when data arrived would jump 0, 20, 40. Instead, while
a request is in flight, the request runs in the background and the bar is
redrawn about 10 times a second:

- It moves from the current count toward **one PR short** of the batch's
  end, at the expected speed, and **holds** there until the response
  arrives.
- When the response arrives it **jumps** to the real count, even if the
  animation hadn't got there yet.
- It **never moves backwards**, including when a failed request is retried
  with a smaller batch.
- It moves in eighths of a cell (`▏▎▍▌▋▊▉`), so it looks smooth.

The expected time of a request is `fixed + per-PR × PRs`, measured on your
machine and network rather than built in:

1. The count request gives a first guess of the fixed cost.
2. The first detail request asks for **1 PR**: roughly the fixed cost of a
   detail request, which is higher than the count request's because GitHub
   computes mergeability and CI.
3. The second asks for **5 PRs**. The difference gives the per-PR cost.
4. From then on both come from a least-squares line through every request
   so far, so network noise averages out.

One request can't do this alone: a 1-PR request taking 1.2s doesn't mean 20
PRs take 24s, since most of that 1.2s is the fixed part (in practice 20 PRs
take about 5s). The small requests fetch real PRs, so nothing is fetched
twice; the cost is one or two extra round trips. This all happens only
when the bar is shown.

### Detail fetch

PRs come from a GraphQL **search** query:

```
repo:<owner/name> is:pr is:open sort:created-desc
```

plus, depending on the option:

| Option | Added to the query |
|---|---|
| `--all` | nothing |
| `--mine` | `author:<you>` |
| `--review` | two searches: `review-requested:<you> -author:<you>` **and** `reviewed-by:<you> -author:<you>` |
| `--author alice,bob` | `author:alice author:app/alice author:bob author:app/bob` |

`--review` needs two searches because GitHub search has no OR between these
qualifiers, and `review-requested:` stops matching as soon as you submit a
review. `reviewed-by:` covers approvals, change requests, comments and
dismissed reviews. The results are merged, duplicates removed, sorted newest
first and cut to `GH_DASHBOARD_LIMIT`. `-author:` leaves out your own PRs,
where replying to review comments also counts as a review by you.

For `--author`, GitHub ORs repeated `author:` qualifiers, so one search
covers several people. Each name is also searched as `app/<name>`: bots are
shown with logins like `dependabot`, but only match `author:app/dependabot`.
Names must be valid GitHub logins (letters, numbers, `-`, `_`), so they
can't add other qualifiers to the search.

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
