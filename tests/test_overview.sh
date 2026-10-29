#!/bin/bash
#
# --author-list, --verbose, and the light first pass behind them.
# Fixture: tests/fixtures/states.json (14 PRs by 7 authors).

# The author rows of --author-list output: "COUNT  NAME" per line.
author_rows() {
    printf '%s\n' "$OUTPUT" | strip_escapes |
        sed -n '/PRS  AUTHOR/,/^$/p' | sed '1d;/^$/d;s/^ *//'
}

test_author_list_counts_each_author() {
    dashboard --author-list
    assert_status 0
    assert_contains "Open PR authors — acme/widgets"
    assert_contains "14 PRs by 7 authors"
    # Most PRs first, then by name; bots marked; deleted accounts last.
    assert_eq "$(author_rows | tr '\n' '|')" \
        "3  alice|3  bob|3  carol|2  dave|1  a-very-long-username-indeed|1  dependabot (bot)|1  (deleted user)|" \
        "author rows"
}

test_author_list_skips_the_detail_fetch() {
    dashboard --author-list
    assert_status 0
    # One light request (100 per page), no detail batches.
    assert_eq "$(graphql_sizes)" "100" "requests"
    assert_not_contains "PRs: 14"
}

test_author_list_pages_past_100_and_ignores_limit() {
    generate_prs 250
    GH_DASHBOARD_LIMIT=50 dashboard --author-list
    assert_status 0
    assert_contains "250 PRs by 1 author"
    assert_eq "$(graphql_sizes)" "100 100 100" "requests"
}

test_author_list_with_review_filter() {
    FAKE_PRS_REQUESTED="$(pick_prs 101 102)"
    FAKE_PRS_REVIEWED="$(pick_prs 102 103)"
    export FAKE_PRS_REQUESTED FAKE_PRS_REVIEWED
    dashboard --review --author-list
    assert_status 0
    # 102 is in both searches and counted once.
    assert_contains "3 PRs by 3 authors   Filter: --review"
    assert_eq "$(author_rows | tr '\n' '|')" "1  alice|1  bob|1  carol|" "author rows"
}

test_author_list_with_author_filter() {
    dashboard --author alice,bob --author-list
    assert_status 0
    assert_contains "Filter: --author alice,bob"
}

test_verbose_prints_summary_and_each_batch() {
    GH_DASHBOARD_BATCH=5 dashboard --verbose
    assert_status 0
    assert_contains "Search: repo:acme/widgets is:pr is:open sort:created-desc"
    assert_contains "Found 14 open PRs by 7 authors: alice 3, bob 3, carol 3, dave 2, a-very-long-username-indeed 1, … (+2 more)"
    assert_contains "Fetching details, 5 PRs per request"
    assert_contains "batch 1: 5 PRs in "
    assert_contains "(5/14)"
    assert_contains "batch 3: 4 PRs in "
    assert_contains "(14/14)"
    assert_contains "Fetched 14 PRs in "
    # The table itself is still there.
    assert_contains "PRs: 14"
    assert_aligned
}

test_verbose_log_goes_to_stderr() {
    local stdout
    stdout="$(cd "$WORK" && "$SCRIPT" --verbose 2>/dev/null)"
    [[ "$stdout" != *"Found 14"* ]] || fail "verbose log leaked into stdout"
    [[ "$stdout" == *"PRs: 14"* ]] || fail "table missing from stdout"
}

test_verbose_shows_retries() {
    export FAKE_FAIL_FIRST=1
    dashboard --verbose
    assert_status 0
    assert_contains "request failed (HTTP 504: 504 Gateway Timeout (https://api.github.com/graphql)), retrying with 50"
    assert_contains "PRs: 14"
}

test_verbose_notes_when_limit_cuts_results() {
    generate_prs 30
    GH_DASHBOARD_LIMIT=10 dashboard --verbose
    assert_status 0
    assert_contains "Found 30 open PRs by 1 author: alice 30"
    assert_contains "Showing the newest 10 (GH_DASHBOARD_LIMIT)"
    assert_contains "(10/10)"
}

test_piped_run_makes_no_extra_requests() {
    # Without a terminal or --verbose nothing shows the totals,
    # so the light pass is skipped.
    dashboard
    assert_status 0
    assert_eq "$(graphql_sizes)" "20" "requests"
}
