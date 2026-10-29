#!/bin/bash
#
# Search filters, batching, the PR limit and retries.

test_default_search_is_all_open_prs() {
    dashboard
    assert_status 0
    grep -q 'q=repo:acme/widgets is:pr is:open sort:created-desc$' "$FAKE_LOG" ||
        fail "unexpected search query: $(grep '^graphql' "$FAKE_LOG")"
}

test_all_flag_same_as_default() {
    dashboard --all
    assert_status 0
    grep -q 'q=repo:acme/widgets is:pr is:open sort:created-desc$' "$FAKE_LOG" ||
        fail "unexpected search query: $(grep '^graphql' "$FAKE_LOG")"
}

test_mine_filters_by_author() {
    dashboard --mine
    assert_status 0
    grep -q 'q=repo:acme/widgets is:pr is:open sort:created-desc author:octocat$' "$FAKE_LOG" ||
        fail "unexpected search query: $(grep '^graphql' "$FAKE_LOG")"
}

# The q= of the first search the last run made.
search_query() {
    grep '^graphql ' "$FAKE_LOG" | head -1 | sed 's/.* q=//'
}

test_author_searches_user_and_bot_forms() {
    dashboard --author alice
    assert_status 0
    assert_eq "$(search_query)" \
        "repo:acme/widgets is:pr is:open sort:created-desc author:alice author:app/alice" "search"
    assert_contains "PRs: 14"
}

test_author_equals_form() {
    dashboard --author=alice
    assert_status 0
    assert_eq "$(search_query)" \
        "repo:acme/widgets is:pr is:open sort:created-desc author:alice author:app/alice" "search"
}

test_author_several_names() {
    dashboard --author alice,bob
    assert_status 0
    assert_eq "$(search_query)" \
        "repo:acme/widgets is:pr is:open sort:created-desc author:alice author:app/alice author:bob author:app/bob" "search"
}

test_author_strips_at_sign_and_bot_suffix() {
    dashboard --author "@alice,dependabot[bot],,"
    assert_status 0
    assert_eq "$(search_query)" \
        "repo:acme/widgets is:pr is:open sort:created-desc author:alice author:app/alice author:dependabot author:app/dependabot" "search"
}

test_author_at_me() {
    dashboard --author @me
    assert_status 0
    assert_eq "$(search_query)" \
        "repo:acme/widgets is:pr is:open sort:created-desc author:@me" "search"
}

# Write the fixture PRs with the given numbers to a file; echo its path.
pick_prs() {
    local file
    file="$TEST_TMP/pick-$(echo "$*" | tr ' ' '-').json"
    jq --arg nums " $* " '[.[] | select(.number) | select((" \(.number) ") as $n | $nums | contains($n))]' \
        "$FIXTURES/states.json" | tr -d '\r' > "$file"
    echo "$file"
}

test_review_searches_requested_and_reviewed() {
    # Regression: --review only searched review-requested:, which GitHub
    # clears as soon as you submit a review, so reviewed PRs vanished.
    dashboard --review
    assert_status 0
    grep -q 'q=repo:acme/widgets is:pr is:open sort:created-desc review-requested:octocat -author:octocat$' "$FAKE_LOG" ||
        fail "missing review-requested search: $(grep '^graphql' "$FAKE_LOG")"
    grep -q 'q=repo:acme/widgets is:pr is:open sort:created-desc reviewed-by:octocat -author:octocat$' "$FAKE_LOG" ||
        fail "missing reviewed-by search: $(grep '^graphql' "$FAKE_LOG")"
}

test_review_merges_both_searches_without_duplicates() {
    FAKE_PRS_REQUESTED="$(pick_prs 101 102 103)"
    FAKE_PRS_REVIEWED="$(pick_prs 103 105 108)"
    export FAKE_PRS_REQUESTED FAKE_PRS_REVIEWED
    dashboard --review
    assert_status 0
    assert_contains "PRs: 5"
    local numbers
    numbers="$(table_lines | grep '^#[0-9]' | awk '{print $1}' | tr '\n' ' ')"
    assert_eq "$numbers" "#108 #105 #103 #102 #101 " "merged PRs, newest first"
}

test_review_with_only_reviewed_prs() {
    # Nothing requested any more, but you reviewed these: they must show.
    echo '[]' > "$TEST_TMP/none.json"
    FAKE_PRS_REQUESTED="$TEST_TMP/none.json"
    FAKE_PRS_REVIEWED="$(pick_prs 102 103)"
    export FAKE_PRS_REQUESTED FAKE_PRS_REVIEWED
    dashboard --review
    assert_status 0
    assert_contains "PRs: 2"
    assert_row 103 "✗ alice 💬 bob"
}

test_review_limit_applies_after_merge() {
    generate_prs 30
    # Search returns newest first; the generated fixture is oldest first.
    jq reverse "$FAKE_PRS" | tr -d '\r' > "$TEST_TMP/newest-first.json"
    FAKE_PRS="$TEST_TMP/newest-first.json"
    FAKE_PRS_REQUESTED="$FAKE_PRS"
    FAKE_PRS_REVIEWED="$FAKE_PRS"
    export FAKE_PRS_REQUESTED FAKE_PRS_REVIEWED
    GH_DASHBOARD_LIMIT=20 dashboard --review
    assert_status 0
    assert_contains "PRs: 20"
    assert_eq "$(table_lines | grep '^#[0-9]' | head -1 | awk '{print $1}')" "#1030" "newest PR first"
}

test_no_open_prs() {
    echo '[]' > "$TEST_TMP/empty.json"
    export FAKE_PRS="$TEST_TMP/empty.json"
    dashboard
    assert_status 0
    assert_contains "PRs: 0"
    assert_contains "Legend:"
    assert_eq "$(table_lines | grep -c '^#[0-9]' || true)" "0" "row count"
}

test_fetches_in_batches_until_last_page() {
    generate_prs 45
    GH_DASHBOARD_BATCH=20 dashboard
    assert_status 0
    assert_eq "$(graphql_sizes)" "20 20 20" "batch sizes"
    grep -q 'first=20 after=20 ' "$FAKE_LOG" || fail "second page should start at cursor 20"
    grep -q 'first=20 after=40 ' "$FAKE_LOG" || fail "third page should start at cursor 40"
    assert_contains "PRs: 45"
    assert_eq "$(table_lines | grep -c '^#[0-9]')" "45" "row count"
}

test_stops_when_page_count_divides_evenly() {
    generate_prs 40
    GH_DASHBOARD_BATCH=20 dashboard
    assert_status 0
    assert_eq "$(graphql_sizes)" "20 20" "batch sizes"
    assert_contains "PRs: 40"
}

test_limit_caps_results_and_last_request() {
    generate_prs 45
    GH_DASHBOARD_LIMIT=30 GH_DASHBOARD_BATCH=20 dashboard
    assert_status 0
    assert_eq "$(graphql_sizes)" "20 10" "batch sizes"
    assert_contains "PRs: 30"
    assert_eq "$(table_lines | grep -c '^#[0-9]')" "30" "row count"
}

test_default_limit_is_200() {
    generate_prs 210
    dashboard
    assert_status 0
    assert_contains "PRs: 200"
}

test_keeps_newest_first_order_across_pages() {
    generate_prs 25
    GH_DASHBOARD_BATCH=10 dashboard
    assert_status 0
    local numbers expected
    numbers="$(table_lines | grep '^#[0-9]' | awk '{print $1}' | tr '\n' ' ')"
    expected="$(seq 1001 1025 | sed 's/^/#/' | tr '\n' ' ')"
    assert_eq "$numbers" "$expected" "PR order"
}

test_ignores_non_pull_request_search_results() {
    dashboard
    assert_status 0
    # states.json has 14 PRs plus one empty (non-PR) search node.
    assert_contains "PRs: 14"
}

test_retry_halves_batch_then_grows_back() {
    generate_prs 45
    export FAKE_FAIL_FIRST=2
    GH_DASHBOARD_BATCH=20 dashboard
    assert_status 0
    # 20 fails, 10 fails, 5 succeeds, then it grows back: 10, 20, 20
    # (the last request asks for 20; only 10 are left).
    assert_eq "$(graphql_sizes)" "20 10 5 10 20 20" "batch sizes"
    assert_contains "PRs: 45"
    assert_eq "$(table_lines | grep -c '^#[0-9]')" "45" "row count"
}

test_gives_up_after_four_failed_attempts() {
    export FAKE_FAIL_FIRST=99
    dashboard
    assert_status 1
    assert_contains "Fetching PRs failed after 4 attempts."
    assert_contains "HTTP 504: 504 Gateway Timeout"
    assert_eq "$(graphql_sizes)" "20 10 5 2" "batch sizes"
}

test_warnings_on_stderr_do_not_break_parsing() {
    # gh can print warnings to stderr on a successful request; only
    # stdout is the response. (CI once flaked on exactly this.)
    export FAKE_STDERR_NOISE=1
    dashboard
    assert_status 0
    assert_contains "PRs: 14"
    dashboard --author-list
    assert_status 0
    assert_contains "14 PRs by 7 authors"
    GH_DASHBOARD_PROGRESS=1 dashboard
    assert_status 0
    assert_contains "PRs: 14"
}
