#!/usr/bin/env bash

set -uo pipefail

# ============================================================
# Vapor CI Benchmark
#
# Measures:
#   - Dependency resolve
#   - Clean debug build
#   - Unit tests
#   - Release build
#
# Outputs:
#   - Time
#   - Maximum memory
#   - GitHub Actions Job Summary (when running in CI)
# ============================================================

RESULTS_FILE="${RUNNER_TEMP:-/tmp}/vapor-benchmark-results.tsv"

OS="$(uname -s)"
ARCH="$(uname -m)"

echo "========================================"
echo " Vapor CI Benchmark"
echo "========================================"
echo "OS:        ${OS}"
echo "Architecture: ${ARCH}"
echo "Swift:"
swift --version
echo "========================================"
echo

printf "Benchmark\tTime\tMemory\n" > "$RESULTS_FILE"

format_time() {
    local seconds="$1"

    awk -v t="$seconds" '
    BEGIN {
        if (t < 60)
            printf "%.2fs", t
        else
            printf "%dm %.2fs", int(t/60), t % 60
    }'
}

format_memory() {
    local kb="$1"

    if [[ -z "$kb" || "$kb" == "0" ]]; then
        echo "N/A"
    elif (( kb >= 1048576 )); then
        awk -v k="$kb" 'BEGIN { printf "%.2f GB", k / 1048576 }'
    else
        awk -v k="$kb" 'BEGIN { printf "%.0f MB", k / 1024 }'
    fi
}

run_benchmark() {
    local name="$1"
    shift
    local command=("$@")

    echo
    echo "========================================"
    echo " ${name}"
    echo "========================================"

    local start
    local end
    local elapsed
    local memory_kb=0

    start="$(python3 -c 'import time; print(time.monotonic())')"

    if [[ "$OS" == "Darwin" ]]; then
        # macOS `time -l` writes statistics to stderr.
        local output
        output=$(
            {
                /usr/bin/time -l "${command[@]}"
            } 2>&1
        )
        local status=$?

        echo "$output"

        memory_kb=$(
            echo "$output" |
                awk '/maximum resident set size/ {
                    print int($1 / 1024)
                }' |
                tail -1
        )

        if [[ -z "$memory_kb" ]]; then
            memory_kb=0
        fi

        if [[ $status -ne 0 ]]; then
            echo
            echo "❌ ${name} failed"
            exit "$status"
        fi
    else
        local output
        output=$(
            {
                /usr/bin/time -v "${command[@]}"
            } 2>&1
        )
        local status=$?

        echo "$output"

        memory_kb=$(
            echo "$output" |
                awk -F: '/Maximum resident set size/ {
                    gsub(/ /, "", $2)
                    print $2
                }' |
                tail -1
        )

        if [[ -z "$memory_kb" ]]; then
            memory_kb=0
        fi

        if [[ $status -ne 0 ]]; then
            echo
            echo "❌ ${name} failed"
            exit "$status"
        fi
    fi

    end="$(python3 -c 'import time; print(time.monotonic())')"

    elapsed="$(python3 -c "print($end - $start)")"

    local formatted_time
    local formatted_memory

    formatted_time="$(format_time "$elapsed")"
    formatted_memory="$(format_memory "$memory_kb")"

    printf "%s\t%s\t%s\n" \
        "$name" \
        "$formatted_time" \
        "$formatted_memory" \
        >> "$RESULTS_FILE"

    echo
    echo "✅ ${name}"
    echo "Time:   ${formatted_time}"
    echo "Memory: ${formatted_memory}"
}

# ------------------------------------------------------------
# Benchmarks
# ------------------------------------------------------------

run_benchmark \
    "Dependency Resolve" \
    swift package resolve

echo
echo "Cleaning .build..."
rm -rf .build

run_benchmark \
    "Debug Build" \
    swift build

run_benchmark \
    "Unit Tests" \
    swift test

run_benchmark \
    "Release Build" \
    swift build -c release

# ------------------------------------------------------------
# Output table
# ------------------------------------------------------------

echo
echo
echo "========================================"
echo " Benchmark Results"
echo "========================================"
echo

printf "| %-24s | %-12s | %-12s |\n" \
    "Benchmark" "Time" "Memory"

printf "|--------------------------|--------------|--------------|\n"

tail -n +2 "$RESULTS_FILE" |
while IFS=$'\t' read -r name time memory; do
    printf "| %-24s | %-12s | %-12s |\n" \
        "$name" "$time" "$memory"
done

echo
echo "Results file: $RESULTS_FILE"

# ------------------------------------------------------------
# GitHub Actions Summary
# ------------------------------------------------------------

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then

    {
        echo "## 🚀 Vapor CI Benchmark"
        echo
        echo "| Benchmark | Time | Memory |"
        echo "|---|---:|---:|"

        tail -n +2 "$RESULTS_FILE" |
        while IFS=$'\t' read -r name time memory; do
            echo "| ${name} | ${time} | ${memory} |"
        done

        echo
        echo "**Environment**"
        echo
        echo "- OS: \`${OS}\`"
        echo "- Architecture: \`${ARCH}\`"
        echo "- Swift:"
        echo
        echo '```text'
        swift --version
        echo '```'
    } >> "$GITHUB_STEP_SUMMARY"

fi
