#!/bin/bash
#
# Command-line options, settings validation and repo detection.

test_help_lists_every_option() {
    dashboard --help
    assert_status 0
    assert_contains "gh dashboard --mine"
    assert_contains "gh dashboard --review"
    assert_contains "gh dashboard --author NAME"
    assert_contains "gh dashboard --all"
    assert_contains "gh dashboard --version"
    assert_contains "GH_DASHBOARD_LIMIT"
    assert_contains "GH_DASHBOARD_BATCH"
    assert_contains "NO_COLOR"
}

test_help_short_flag() {
    dashboard -h
    assert_status 0
    assert_contains "Usage:"
}

test_version_flag() {
    dashboard --version
    assert_status 0
    [[ "$OUTPUT" =~ ^gh-dashboard\ [0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "unexpected version output: $OUTPUT"
}

test_unknown_option_fails() {
    dashboard --bogus
    assert_status 1
    assert_contains "Unknown option: --bogus"
    assert_contains "--help"
}

test_two_filters_fail() {
    dashboard --mine --review
    assert_status 1
    assert_contains "Use only one of --all, --mine, --review, --author (got --mine and --review)"
}

test_author_cannot_be_combined_with_mine() {
    dashboard --author bob --mine
    assert_status 1
    assert_contains "Use only one of"
}

test_author_without_name_fails() {
    local args
    for args in "--author" "--author --mine" "--author=" "--author ,"; do
        # shellcheck disable=SC2086  # split args on purpose
        dashboard $args
        assert_status 1
        assert_contains "--author needs a name"
    done
    [[ ! -s "$FAKE_LOG" ]] || fail "should fail before calling gh"
}

test_author_rejects_names_that_could_inject_search_terms() {
    dashboard --author "bob is:closed"
    assert_status 1
    assert_contains "Invalid author name: 'bob is:closed'"
    dashboard --author "alice,bob:x"
    assert_status 1
    assert_contains "Invalid author name: 'bob:x'"
}

test_invalid_limit_fails() {
    GH_DASHBOARD_LIMIT=abc dashboard
    assert_status 1
    assert_contains "Invalid GH_DASHBOARD_LIMIT: 'abc'"
}

test_zero_batch_fails() {
    GH_DASHBOARD_BATCH=0 dashboard
    assert_status 1
    assert_contains "Invalid GH_DASHBOARD_BATCH: '0'"
}

test_not_a_git_repository() {
    mkdir -p "$TEST_TMP/plain"
    GIT_CEILING_DIRECTORIES="$TEST_TMP" RUN_IN="$TEST_TMP/plain" dashboard
    assert_status 1
    assert_contains "Not inside a git repository."
}

test_repo_not_accessible_shows_gh_error() {
    export FAKE_REPO_TOKEN="tok-somebody-else"
    dashboard
    assert_status 1
    assert_contains "Could not open this repository on GitHub."
    assert_contains "gh said: GraphQL: Could not resolve to a Repository"
    assert_contains "None of your logged-in gh accounts can see it."
}

test_falls_back_to_account_with_access() {
    # Work account is active, but only the personal account can see the repo.
    export FAKE_ACCOUNTS="work-user:tok-work:active personal-user:tok-personal"
    export FAKE_REPO_TOKEN="tok-personal"
    dashboard --mine
    assert_status 0
    assert_contains "GitHub PR Dashboard — acme/widgets"
    # Searches run as the account that has access...
    grep -q 'author:personal-user' "$FAKE_LOG" || fail "--mine should search as personal-user"
    # ...without touching the user's active gh account.
    if grep -q 'auth switch' "$FAKE_LOG"; then fail "must not run gh auth switch"; fi
}

test_active_account_used_when_it_has_access() {
    export FAKE_ACCOUNTS="work-user:tok-work:active personal-user:tok-personal"
    export FAKE_REPO_TOKEN="tok-work"
    dashboard --mine
    assert_status 0
    grep -q 'author:work-user' "$FAKE_LOG" || fail "--mine should search as work-user"
    if grep -q 'auth token' "$FAKE_LOG"; then fail "should not look up other accounts' tokens"; fi
}
