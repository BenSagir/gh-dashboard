#!/bin/bash
#
# The animated progress bar (forced on with GH_DASHBOARD_PROGRESS=1,
# since the tests don't run in a terminal).

# Every bar frame drawn, one per line: "<filled eighths> <count> <total> <cells>".
progress_frames() {
    printf '%s' "$OUTPUT" | perl -CSD -ne '
        for (split /\r/) {
            next unless /Fetching PRs (\S+) (\d+)\/(\d+)/;
            my ($bar, $count, $total) = ($1, $2, $3);
            my %part = ("▏",1,"▎",2,"▍",3,"▌",4,"▋",5,"▊",6,"▉",7);
            my $eighths = 0;
            for my $c (split //, $bar) {
                if    ($c eq "█")      { $eighths += 8 }
                elsif ($part{$c})      { $eighths += $part{$c} }
            }
            print "$eighths $count $total ", length($bar), "\n";
        }'
}

test_progress_bar_animates_between_batches() {
    export GH_DASHBOARD_PROGRESS=1 FAKE_DELAY=0.8
    GH_DASHBOARD_BATCH=5 dashboard
    assert_status 0
    assert_contains "Counting open PRs…"
    local frames; frames="$(progress_frames)"
    [[ -n "$frames" ]] || fail "no progress frames drawn"
    # Requests return 1 PR (calibration), then 5, 5, 3: counts strictly
    # between 1 and 6 prove it animated rather than jumping 1 -> 6.
    printf '%s\n' "$frames" | awk '$2 > 1 && $2 < 6 { found = 1 } END { exit !found }' ||
        fail "bar did not move during the first batch: $(printf '%s' "$frames" | tr '\n' '|')"
}

test_progress_bar_never_moves_backwards() {
    # Call 1 is the count, call 2 the single-PR calibration; calls 3
    # and 4 (the first batch) fail, so it's retried smaller while the
    # bar is animating.
    export GH_DASHBOARD_PROGRESS=1 FAKE_DELAY=0.6 FAKE_FAIL_CALLS="3 4"
    GH_DASHBOARD_BATCH=5 dashboard
    assert_status 0
    [[ -n "$(progress_frames)" ]] || fail "no progress frames drawn"
    progress_frames | awk '
        $1 < e || $2 < c { print "went back at frame " NR ": " $0; bad = 1 }
        { e = $1; c = $2 }
        END { exit bad }' || fail "progress went backwards"
}

test_progress_bar_holds_one_short_until_the_response() {
    # Calls: 1 count, 2 one-PR calibration, 3 the first batch of 2,
    # which is unexpectedly slow. The bar animates to 2/5 (one short
    # of the batch end at 3) and waits there for the response.
    export GH_DASHBOARD_PROGRESS=1 FAKE_DELAY=0.3 FAKE_SLOW_CALLS=3 FAKE_SLOW_DELAY=2
    GH_DASHBOARD_BATCH=2 GH_DASHBOARD_LIMIT=5 dashboard
    assert_status 0
    local held
    held="$(progress_frames | awk '$2 == 2' | wc -l | tr -d ' ')"
    [[ "$held" -ge 5 ]] || fail "expected the bar to hold at 2/5 for several frames, got $held"
}

test_progress_calibrates_with_1_then_5_prs() {
    generate_prs 45
    export GH_DASHBOARD_PROGRESS=1
    dashboard
    assert_status 0
    # count request, then detail requests of 1 and 5 PRs to measure
    # the speed, then batches of 20 (the last gets the 19 left).
    assert_eq "$(graphql_sizes)" "1 1 5 20 20" "requests"
    assert_contains "PRs: 45"
}

test_progress_speed_follows_measured_requests() {
    # Detail requests take 0.2s + 0.6s per PR, far from the 0.25s
    # default. The 1- and 5-PR requests measure it, so during the
    # first full batch (8 PRs, counts 6 to 13, about 0.6s per PR)
    # the bar keeps moving: no count stays up for much more than one
    # PR's time. With a wrong estimate it would sit at the batch end
    # for seconds.
    generate_prs 30
    export GH_DASHBOARD_PROGRESS=1 FAKE_DELAY=0.2 FAKE_DELAY_PER_PR=0.6
    GH_DASHBOARD_BATCH=8 GH_DASHBOARD_LIMIT=14 dashboard
    assert_status 0
    assert_eq "$(graphql_sizes)" "1 1 5 8" "requests"
    local longest
    longest="$(progress_frames | awk '
        $2 >= 6 && $2 <= 13 { run = ($2 == prev) ? run + 1 : 1; if (run > max) max = run }
        { prev = $2 }
        END { print max + 0 }')"
    [[ "$longest" -le 12 ]] || fail "bar stood still for $longest frames during the first full batch"
}

test_progress_bar_is_always_30_cells() {
    export GH_DASHBOARD_PROGRESS=1 FAKE_DELAY=0.4
    GH_DASHBOARD_BATCH=5 dashboard
    assert_status 0
    assert_eq "$(progress_frames | awk '{ print $4 }' | sort -u)" "30" "bar width"
}

test_no_progress_bar_when_not_a_terminal() {
    dashboard
    assert_status 0
    assert_not_contains "Fetching PRs"
    assert_not_contains "Counting open PRs"
}

test_progress_off_with_verbose() {
    export GH_DASHBOARD_PROGRESS=1
    dashboard --verbose
    assert_status 0
    assert_not_contains "Fetching PRs █"
    assert_contains "Fetching details"
}
