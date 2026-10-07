#!/bin/bash
#
# What each column shows, alignment, colors and links.
# Fixture: tests/fixtures/states.json

test_header_shows_repo_and_count() {
    dashboard
    assert_status 0
    assert_contains "GitHub PR Dashboard — acme/widgets"
    assert_contains "PRs: 14"
    assert_contains "Legend:"
}

test_pr_without_reviewers_shows_dash() {
    # Regression: an empty reviewer list crashed bash 3.2 under set -u.
    dashboard
    assert_status 0
    assert_row 101 "#101" "Add login page" "alice" "—" "✓ PASS" "0/0" "✓ READY"
}

test_pending_and_approved_reviewers() {
    dashboard
    assert_row 102 "◷ carol ✓ dave" "1/2" "◷ REVIEW"
}

test_changes_requested_and_commented_reviewers() {
    dashboard
    assert_row 103 "✗ alice 💬 bob" "0/2" "✗ CHANGES"
}

test_draft_pr() {
    dashboard
    assert_row 104 "Update dependencies [DRAFT]" "◷ RUN" "◷ DRAFT"
}

test_conflict_beats_ci_failure() {
    dashboard
    assert_row 105 "✗ FAIL" "✗ CONFLICT"
}

test_ci_error_counts_as_failure() {
    dashboard
    assert_row 106 "✗ FAIL" "✗ CI FAIL"
}

test_ci_expected_counts_as_running() {
    dashboard
    assert_row 107 "✓ carol" "◷ RUN" "1/1" "◷ CI RUN"
}

test_no_ci_and_blocked() {
    dashboard
    assert_row 108 "— NONE" "✗ BLOCKED"
}

test_team_review_request_shows_team_name() {
    dashboard
    assert_row 109 "◷ frontend-team" "0/1"
}

test_long_values_are_truncated_with_ellipsis() {
    dashboard
    assert_row 110 "This pull request has a deliberat…" "a-very-long-u…" "◷ reviewer-number-one ◷ revie…"
}

test_deleted_author_shows_dash() {
    dashboard
    assert_row 113 "PR from a deleted account" "—"
}

test_unknown_mergeability() {
    dashboard
    assert_row 114 "? UNKNOWN"
}

test_columns_aligned_without_color() {
    dashboard
    assert_status 0
    assert_aligned
}

test_columns_aligned_with_color_and_links() {
    CLICOLOR_FORCE=1 dashboard
    assert_status 0
    assert_aligned
}

test_unicode_and_emoji_titles_aligned() {
    dashboard
    assert_row 111 "Café menu — תפריט עברית" "💬 bob"
    assert_row 112 "🚀 Ship it 🚀"
    local w111 w112
    w111="$(row_for 111 | visible_widths)"
    w112="$(row_for 112 | visible_widths)"
    assert_eq "$w111" "$TABLE_WIDTH" "row 111 width"
    assert_eq "$w112" "$TABLE_WIDTH" "row 112 width"
}

test_piped_output_has_no_escape_codes() {
    dashboard
    assert_status 0
    [[ "$OUTPUT" != *$'\e'* ]] || fail "piped output contains escape codes"
    assert_not_contains "Click a PR title"
}

test_clicolor_force_adds_colors_and_links() {
    CLICOLOR_FORCE=1 dashboard
    assert_status 0
    assert_contains $'\e[32m✓ PASS'
    assert_contains $'\e]8;;https://github.com/acme/widgets/pull/101\aAdd login page'
    assert_contains "Click a PR title"
}

test_commented_reviews_are_orange() {
    CLICOLOR_FORCE=1 dashboard
    assert_contains $'\e[38;5;208m💬 bob'
}

test_no_color_wins_over_clicolor_force() {
    NO_COLOR=1 CLICOLOR_FORCE=1 dashboard
    assert_status 0
    [[ "$OUTPUT" != *$'\e'* ]] || fail "NO_COLOR output contains escape codes"
}

test_clicolor_force_zero_means_off() {
    CLICOLOR_FORCE=0 dashboard
    [[ "$OUTPUT" != *$'\e'* ]] || fail "CLICOLOR_FORCE=0 output contains escape codes"
}
