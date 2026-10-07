#!/bin/bash
#
# Helpers shared by all test files. Sourced by tests/run.sh.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$ROOT/gh-dashboard"
FAKE_BIN="$TESTS_DIR/fake-bin"
FIXTURES="$TESTS_DIR/fixtures"

# Table width implied by COL_WIDTHS: 6+34+14+30+10+11+12 + 6 gaps.
TABLE_WIDTH=123


# ------------------------------------------------------------
# Per-test environment
# ------------------------------------------------------------

setup() {
    TEST_TMP="$(mktemp -d)"
    WORK="$TEST_TMP/repo"
    mkdir -p "$WORK"
    git -C "$WORK" init -q

    # Keep the user's real settings out of the tests.
    unset GH_TOKEN GH_HOST NO_COLOR CLICOLOR_FORCE \
          GH_DASHBOARD_LIMIT GH_DASHBOARD_BATCH FAKE_REPO_TOKEN FAKE_FAIL_FIRST

    export PATH="$FAKE_BIN:$PATH"
    export FAKE_STATE_DIR="$TEST_TMP"
    export FAKE_LOG="$TEST_TMP/gh.log"
    export FAKE_ACCOUNTS="octocat:tok-octo:active"
    export FAKE_REPO="acme/widgets"
    export FAKE_PRS="$FIXTURES/states.json"
    : > "$FAKE_LOG"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Write N generated PRs (numbers 1001..) to a fixture file and
# point FAKE_PRS at it.
generate_prs() {
    local n="$1"
    FAKE_PRS="$TEST_TMP/generated.json"
    jq -n --argjson n "$n" '[range(1; $n + 1) | {
        number: (1000 + .), title: "Generated PR \(.)",
        url: "https://github.com/acme/widgets/pull/\(1000 + .)",
        isDraft: false, reviewDecision: null,
        mergeable: "MERGEABLE", mergeStateStatus: "CLEAN",
        author: {login: "alice"},
        reviewRequests: {nodes: []}, latestReviews: {nodes: []},
        commits: {nodes: [{commit: {statusCheckRollup: {state: "SUCCESS"}}}]}
    }]' | tr -d '\r' > "$FAKE_PRS"
    export FAKE_PRS
}


# ------------------------------------------------------------
# Running the dashboard
# ------------------------------------------------------------

# Runs the script in $WORK. Sets OUTPUT (stdout+stderr) and STATUS.
dashboard() {
    local dir="${RUN_IN:-$WORK}"
    set +e
    OUTPUT="$(cd "$dir" && "$SCRIPT" "$@" 2>&1)"
    STATUS=$?
    set -e
}

# Lines of the table: header, separator and PR rows.
table_lines() {
    printf '%s\n' "$OUTPUT" | strip_escapes | grep -E '^(#|─)'
}

# The rendered row for one PR number, escapes stripped.
row_for() {
    printf '%s\n' "$OUTPUT" | strip_escapes | grep -E "^#$1 " || true
}

# The graphql "first=N" sizes requested, in order, space-separated.
graphql_sizes() {
    grep '^graphql ' "$FAKE_LOG" | sed -E 's/.*first=([0-9]+).*/\1/' | tr '\n' ' ' | sed 's/ $//'
}

strip_escapes() {
    perl -pe 's/\e\[[0-9;]*m//g; s/\e\]8;;[^\a]*\a//g; s/\r//g'
}

# Display width of each input line, measured independently of the
# script: Unicode East Asian Width Wide/Fullwidth = 2 columns,
# combining marks = 0, everything else = 1.
visible_widths() {
    strip_escapes | perl -CSD -ne '
        chomp;
        my $w = 0;
        for my $c (/\X/g) {
            if    ($c =~ /^\p{M}/)                        { }
            elsif ($c =~ /^[\p{Ea=W}\p{Ea=F}]/)          { $w += 2 }
            else                                          { $w += 1 }
        }
        print "$w\n";
    '
}


# ------------------------------------------------------------
# Assertions (each one fails the current test with a message)
# ------------------------------------------------------------

fail() {
    echo "    FAIL: $*" >&2
    if [[ -n "${OUTPUT:-}" ]]; then
        echo "    --- output ---" >&2
        printf '%s\n' "$OUTPUT" | strip_escapes | sed 's/^/    | /' >&2
    fi
    exit 1
}

assert_status() {
    [[ "$STATUS" == "$1" ]] || fail "expected exit status $1, got $STATUS"
}

assert_contains() {
    [[ "$OUTPUT" == *"$1"* ]] || fail "expected output to contain: $1"
}

assert_not_contains() {
    [[ "$OUTPUT" != *"$1"* ]] || fail "expected output NOT to contain: $1"
}

assert_eq() {
    [[ "$1" == "$2" ]] || fail "${3:-values differ}: expected [$2], got [$1]"
}

# assert_row NUMBER TEXT... : the PR's row contains every TEXT.
assert_row() {
    local number="$1"; shift
    local row; row="$(row_for "$number")"
    [[ -n "$row" ]] || fail "no row for PR #$number"
    local text
    for text in "$@"; do
        [[ "$row" == *"$text"* ]] || fail "row #$number should contain [$text], got: $row"
    done
}

# Every table line has the same display width as the header.
assert_aligned() {
    local widths
    widths="$(table_lines | visible_widths | sort -u | tr '\n' ' ' | sed 's/ $//')"
    assert_eq "$widths" "$TABLE_WIDTH" "table line widths"
}
