#!/bin/bash
#
# Test runner. No dependencies beyond what gh-dashboard needs.
#
#   tests/run.sh             run everything
#   tests/run.sh retry       run tests whose name contains "retry"

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=tests/lib.sh
source "$TESTS_DIR/lib.sh"

for file in "$TESTS_DIR"/test_*.sh; do
    # shellcheck source=/dev/null
    source "$file"
done

FILTER="${1:-}"
PASSED=0
FAILED=0
FAILED_NAMES=""

echo "gh-dashboard tests — bash $BASH_VERSION, $(jq --version | tr -d '\r'), $(uname -s)"
echo

for name in $(declare -F | awk '{print $3}' | grep '^test_'); do

    [[ -n "$FILTER" && "$name" != *"$FILTER"* ]] && continue

    if ( set -euo pipefail; setup; trap teardown EXIT; "$name" ); then
        PASSED=$(( PASSED + 1 ))
        echo "  ✓ ${name#test_}"
    else
        FAILED=$(( FAILED + 1 ))
        FAILED_NAMES="$FAILED_NAMES ${name#test_}"
        echo "  ✗ ${name#test_}"
    fi

done

echo
echo "$PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
    echo "Failed:$FAILED_NAMES"
    exit 1
fi
