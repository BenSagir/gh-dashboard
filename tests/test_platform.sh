#!/bin/bash
#
# Portability: Windows line endings, file hygiene.

# Simulate Git Bash on Windows: uname reports MINGW and jq writes
# CRLF line endings, like jq.exe does.
simulate_windows_jq() {
    local uname_output="$1"
    local real_jq; real_jq="$(command -v jq)"
    local bin="$TEST_TMP/winbin"
    mkdir -p "$bin"
    printf '#!/bin/bash\necho %s\n' "$uname_output" > "$bin/uname"
    printf '#!/bin/bash\n"%s" "$@" | perl -pe "s/\\n/\\r\\n/"\n' "$real_jq" > "$bin/jq"
    chmod +x "$bin/uname" "$bin/jq"
    "$bin/jq" -n '"x"' | od -c | grep -q '\\r' || fail "CRLF jq simulation is not producing \\r"
    export PATH="$bin:$PATH"
}

# Output without the clock line, for comparing two runs.
stable_output() {
    printf '%s\n' "$OUTPUT" | grep -v 'Updated:'
}

test_windows_crlf_jq_output_matches_unix() {
    dashboard
    local expected; expected="$(stable_output)"

    simulate_windows_jq "MINGW64_NT-10.0-22631"
    dashboard
    assert_status 0
    [[ "$OUTPUT" != *$'\r'* ]] || fail "output contains carriage returns"
    assert_eq "$(stable_output)" "$expected" "Windows-simulated output"
}

test_windows_simulation_breaks_without_the_fix() {
    # Sanity check that the test above can fail: same CRLF jq,
    # but uname says macOS so the CRLF fix is not enabled.
    dashboard
    local expected; expected="$(stable_output)"

    simulate_windows_jq "Darwin"
    dashboard
    [[ "$(stable_output)" != "$expected" ]] || fail "CRLF jq without the fix should change the output"
}

test_windows_paging_with_crlf_cursors() {
    generate_prs 45
    simulate_windows_jq "MSYS_NT-10.0"
    GH_DASHBOARD_BATCH=20 dashboard
    assert_status 0
    assert_contains "PRs: 45"
    grep -q 'after=20 ' "$FAKE_LOG" || fail "cursor should be passed without a trailing CR"
}

test_script_has_unix_line_endings() {
    if grep -q $'\r' "$SCRIPT"; then fail "gh-dashboard contains CR characters"; fi
}

test_script_is_executable() {
    [[ -x "$SCRIPT" ]] || fail "gh-dashboard is not executable"
}

test_script_has_valid_syntax() {
    bash -n "$SCRIPT" || fail "bash -n failed"
}

# A UTF-8 locale available on this machine, if any.
utf8_locale() {
    locale -a 2>/dev/null | tr -d '\r' | grep -i -m1 -E '^(C|en_US)\.utf-?8$' || true
}

test_no_variable_runs_into_a_non_ascii_character() {
    # Under a UTF-8 locale bash 3.2 can read "$bar█" as a variable named
    # "bar" plus the first byte of █, which then fails under set -u.
    # Such variables must be written ${bar}█.
    local hits
    hits="$(perl -ne 'print "$.: $_" if /\$[A-Za-z_][A-Za-z0-9_]*[^\x00-\x7F]/' "$SCRIPT")"
    [[ -z "$hits" ]] || fail "unbraced variable before a non-ASCII character:
$hits"
}

test_works_under_a_utf8_locale() {
    local loc; loc="$(utf8_locale)"
    if [[ -z "$loc" ]]; then
        echo "    (skipped: no UTF-8 locale installed)" >&2
        return 0
    fi
    dashboard
    local expected; expected="$(stable_output)"

    export LC_ALL="$loc" GH_DASHBOARD_PROGRESS=1
    local stdout
    set +e
    stdout="$(cd "$WORK" && "$SCRIPT" 2>"$TEST_TMP/stderr")"
    # shellcheck disable=SC2034  # read by assert_status (tests/lib.sh)
    STATUS=$?
    set -e
    OUTPUT="$stdout"
    assert_status 0
    if grep -q 'unbound variable' "$TEST_TMP/stderr"; then
        fail "under $loc: $(cat "$TEST_TMP/stderr")"
    fi
    grep -q 'Fetching PRs' "$TEST_TMP/stderr" || fail "under $loc: progress bar not drawn"
    assert_eq "$(stable_output)" "$expected" "table under $loc"
}
