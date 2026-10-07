# Troubleshooting

- [`Not inside a git repository.`](#not-inside-a-git-repository)
- [`Could not open this repository on GitHub.`](#could-not-open-this-repository-on-github)
- [`HTTP 504: 504 Gateway Timeout`](#http-504-504-gateway-timeout)
- [`Fetching PRs failed after 4 attempts.`](#fetching-prs-failed-after-4-attempts)
- [`jq: command not found` / `perl: command not found`](#jq-command-not-found--perl-command-not-found)
- [Garbled symbols, no colors, or columns out of line](#garbled-symbols-no-colors-or-columns-out-of-line)
- [A PR I just opened is missing](#a-pr-i-just-opened-is-missing)
- [MERGE shows `? UNKNOWN`](#merge-shows--unknown)
- [Windows: `$'\r': command not found`](#windows-r-command-not-found)
- [`Invalid GH_DASHBOARD_LIMIT` / `Invalid GH_DASHBOARD_BATCH`](#invalid-gh_dashboard_limit--invalid-gh_dashboard_batch)
- [Reporting a bug](#reporting-a-bug)

## `Not inside a git repository.`

Run the command from inside a cloned repository:

```bash
cd path/to/your/clone
gh dashboard
```

## `Could not open this repository on GitHub.`

The repository was found locally, but none of your logged-in `gh` accounts
can see it on GitHub. The message includes GitHub's own error.

- **Private repo on another account.** If you have separate work and personal
  accounts, log in to the one with access too (`gh auth login`). The
  dashboard picks the right account automatically; see
  [several accounts](installation.md#several-github-accounts).
- **Check what you're logged in as:** `gh auth status`.
- **Check the remote:** `git remote -v` should point at `github.com`.
- **Organization SSO:** if your org uses SAML single sign-on, authorize your
  token for the org: `gh auth refresh -h github.com`, then follow the SSO
  prompt.
- **GitHub Enterprise Server:** basic use works when `gh` is logged in to
  your Enterprise host, but trying other accounts only looks at `github.com`.

## `HTTP 504: 504 Gateway Timeout`

GitHub cut off a request that took too long. The dashboard already retries
with smaller batches, so you'll normally only see this as the last line of
the error below.

## `Fetching PRs failed after 4 attempts.`

Four requests in a row failed, even with the batch size halved each time.

- If the last line is a `504`, GitHub is slow right now. Try a smaller batch:
  `GH_DASHBOARD_BATCH=5 gh dashboard`.
- If it's `HTTP 401` or `Bad credentials`, your login expired:
  `gh auth login`.
- If it mentions `rate limit`, wait for the time shown and try again, or
  lower `GH_DASHBOARD_LIMIT` to make fewer requests.
- Check [githubstatus.com](https://www.githubstatus.com).

## `jq: command not found` / `perl: command not found`

Install the missing tool, see [installation](installation.md). On Windows,
`perl` comes with Git for Windows; if it's missing, reinstall Git for
Windows. After installing, open a new terminal.

## Garbled symbols, no colors, or columns out of line

- **Windows:** use Windows Terminal, not the legacy console window.
- **Output piped or redirected:** colors are off on purpose. Use
  `CLICOLOR_FORCE=1` to keep them.
- **`NO_COLOR` is set** in your environment: `echo $NO_COLOR`.
- **Font:** use a font that has ✓ ◷ ✗ and emoji, such as the default font
  of your terminal, or a [Nerd Font](https://www.nerdfonts.com).
- **Terminal narrower than ~125 columns:** rows wrap. Widen the window or
  make the font smaller.

## A PR I just opened is missing

`--mine` and `--review` (and the default view) use GitHub's search, which can
take up to a minute to include a brand-new PR. Run it again shortly.

If your repo has more open PRs than `GH_DASHBOARD_LIMIT` (200 by default),
only the newest ones are shown. Raise the limit:
`GH_DASHBOARD_LIMIT=500 gh dashboard`.

## MERGE shows `? UNKNOWN`

GitHub computes whether a PR can be merged in the background, and hasn't
finished yet for that PR. Run the dashboard again in a few seconds.

## Windows: `$'\r': command not found`

The script was saved with Windows line endings. This happens if you copied
the file by hand rather than installing it with `gh extension install`.
Reinstall it:

```powershell
gh extension remove dashboard
gh extension install BenSagir/gh-dashboard
```

## `Invalid GH_DASHBOARD_LIMIT` / `Invalid GH_DASHBOARD_BATCH`

These settings must be positive whole numbers, e.g.
`GH_DASHBOARD_LIMIT=50`. Check your shell profile for a typo.

## Reporting a bug

[Open an issue](https://github.com/BenSagir/gh-dashboard/issues) with:

- `gh dashboard --version`, `gh --version`, `jq --version`, `bash --version`
- your OS and terminal
- the command you ran and the full error, with private repo names and
  usernames removed
