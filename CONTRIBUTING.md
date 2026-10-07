# Contributing

Bug reports and pull requests are welcome.

## Project layout

```
gh-dashboard            the extension (one bash script)
tests/
  run.sh                test runner
  lib.sh                setup, helpers and assertions
  test_cli.sh           options, settings, repo and account detection
  test_fetch.sh         search filters, batching, limit, retries
  test_render.sh        columns, statuses, alignment, colors, links
  test_platform.sh      Windows line endings, file hygiene
  fake-bin/gh           fake GitHub CLI used by the tests
  fixtures/states.json  sample PRs covering every status
docs/                   user documentation
.github/workflows/      CI: shellcheck + tests on Linux, macOS, Windows
```

## Running the tests

You need `bash`, `jq`, `git` and `perl`, the same as the extension itself.
The tests don't need network access or a GitHub login.

```bash
tests/run.sh             # everything
tests/run.sh retry       # only tests whose name contains "retry"
```

On Windows, run them from Git Bash.

### How the tests work

`tests/fake-bin/gh` is put first on `PATH`, so when the script runs `gh` it
gets the fake instead. The fake answers the five calls the script makes
(`repo view`, `auth status`, `auth token`, `api user`, `api graphql`) from
environment variables and a fixture file:

| Variable | Meaning |
|---|---|
| `FAKE_ACCOUNTS` | Logged-in accounts: `"login:token[:active] ..."` |
| `FAKE_REPO` | What `gh repo view` returns |
| `FAKE_REPO_TOKEN` | Only this token can see the repo (tests the account fallback) |
| `FAKE_PRS` | JSON file with an array of PR search nodes |
| `FAKE_FAIL_FIRST` | Fail the first N GraphQL calls with `HTTP 504` |
| `FAKE_LOG` | Every call is appended here, so tests can check what was requested |

Each test runs in its own temporary git repository with defaults from
`setup()` in `tests/lib.sh`.

### Writing a test

Add a function named `test_<something>` to one of the `tests/test_*.sh`
files. It's picked up automatically.

```bash
test_draft_pr() {
    dashboard                     # runs the script; sets $OUTPUT and $STATUS
    assert_status 0
    assert_row 104 "[DRAFT]" "◷ DRAFT"
}
```

Useful helpers: `dashboard [args]`, `generate_prs N`, `assert_status`,
`assert_contains`, `assert_not_contains`, `assert_eq`, `assert_row`,
`assert_aligned`, `row_for`, `table_lines`, `graphql_sizes`. See
`tests/lib.sh`.

For a new PR state, add a PR to `tests/fixtures/states.json` with an unused
number and update the `PRs: N` count checked in the tests.

### Lint

CI runs [shellcheck](https://www.shellcheck.net) on every script:

```bash
shellcheck -x gh-dashboard tests/run.sh tests/lib.sh tests/test_*.sh tests/fake-bin/gh
```

## Guidelines

- **Keep bash 3.2 compatible**: macOS ships it. No associative arrays,
  `mapfile` or `${var,,}`. Expand possibly-empty arrays as
  `${arr[@]+"${arr[@]}"}`.
- **Keep it one file** with no dependencies beyond `gh`, `jq`, `git` and
  `perl`, so `gh extension install` is all users need.
- **Match the existing style**: section banners, 4-space indent.
- **Add a test** for every bug fix and feature. Check that the test fails
  without your change.
- **Update the docs** in `docs/` and the `CHANGELOG.md` "Unreleased" section.

## Making a release

1. Update `VERSION` in `gh-dashboard` and move the "Unreleased" changes in
   `CHANGELOG.md` under the new version.
2. Commit, then tag and publish:

   ```bash
   git tag v1.2.3
   git push origin main v1.2.3
   gh release create v1.2.3 --title v1.2.3 --generate-notes
   ```

Users get the new version with `gh extension upgrade dashboard`.
