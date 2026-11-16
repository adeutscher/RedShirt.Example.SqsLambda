#!/usr/bin/env bash
#
# Build stage: restore, build, and test the solution with code coverage.
#
# Nothing in this script names a specific Lambda, but it assumes the repository follows
# the same layout and tooling as the other Lambda repos:
#
# Repository layout:
#   * This script lives two levels below the repository root (scripts/cicd/build.sh).
#   * Exactly one .sln or .slnx in the repository root, unless SLN_FILE is set.
#   * Optional: .sln or .slnx files directly under tools/. They are built
#     (restore and build only, no tests) after the main solution.
#
# .NET and test projects:
#   * .NET 10 SDK or later, with global.json setting
#     "test": { "runner": "Microsoft.Testing.Platform" }. Older SDKs or the VSTest
#     runner reject the "dotnet test" options used here.
#   * Every test project in the solution uses xunit.v3 4.x or later. Earlier versions
#     do not have --report-xunit-xml, and any test app that rejects an option exits
#     with code 5 and runs zero tests.
#
# Tools:
#   * dotnet-coverage, as "dotnet coverage", on PATH, or in ~/.dotnet/tools.
#     To install: dotnet tool install --global dotnet-coverage
#   * bash, find, and sort.
#   * /proc/sys/kernel/random/uuid or uuidgen, for the coverage session ID.
#   * TMPDIR left unset. dotnet-coverage writes its data files to /tmp regardless, and
#     with TMPDIR pointing elsewhere the coverage report comes out empty.
#
# Settings (environment variables):
#   * SLN_FILE: solution to build. Default: the single .sln or .slnx in the root.
#   * BUILD_CONFIGURATION: build configuration. Default: Release.
#
# Options:
#   * -p: run test apps in parallel. See the note above test_inner below.
#   * -h: print usage and exit.
#
# Output (artifacts/ci/):
#   * coverage.cobertura.xml: code coverage for the whole test run.
#   * *.xunit.xml: one xUnit.net XML report per test project.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [-p] [-h]

Restore, build, and test the solution with code coverage.

Options:
  -p  Run test apps in parallel. Use only where the coverage profiler crash
      (https://github.com/microsoft/codecoverage/issues/253) has not been observed.
  -h  Show this help and exit.

Environment:
  SLN_FILE             Solution to build. Default: the single .sln or .slnx in the root.
  BUILD_CONFIGURATION  Build configuration. Default: Release.
EOF
}

parallel_tests=false
while getopts ":ph" opt; do
  case "$opt" in
    p) parallel_tests=true ;;
    h) usage; exit 0 ;;
    \?) echo "ERROR: unknown option -$OPTARG" >&2; usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
if [[ $# -gt 0 ]]; then
  echo "ERROR: unexpected argument: $1" >&2
  usage >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

# Use SLN_FILE when set. Otherwise require exactly one root .sln or .slnx.
resolve_sln_file() {
  if [[ -n "${SLN_FILE:-}" ]]; then
    printf '%s\n' "$SLN_FILE"
    return
  fi

  local matches=()
  shopt -s nullglob
  matches=( *.sln *.slnx )
  shopt -u nullglob

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "ERROR: no .sln or .slnx file in the repository root. Set SLN_FILE." >&2
    exit 1
  fi
  if [[ ${#matches[@]} -gt 1 ]]; then
    echo "ERROR: multiple solution files in the repository root. Set SLN_FILE." >&2
    printf '  %s\n' "${matches[@]}" >&2
    exit 1
  fi
  printf '%s\n' "${matches[0]}"
}

sln="$(resolve_sln_file)" || exit 1
configuration="${BUILD_CONFIGURATION:-Release}"

echo "==> dotnet restore $sln"
dotnet restore "$sln"

echo "==> dotnet build $sln (--no-restore, -c $configuration)"
dotnet build "$sln" --no-restore --configuration "$configuration"

# Tool solutions are kept out of the main solution (and the Docker build). Build them so they
# do not rot, but do not test them here.
tool_solutions=()
while IFS= read -r path; do
  tool_solutions+=( "$path" )
done < <(find tools -maxdepth 1 -type f \( -name '*.sln' -o -name '*.slnx' \) 2>/dev/null | LC_ALL=C sort)

for tool_sln in "${tool_solutions[@]}"; do
  echo "==> dotnet build $tool_sln (-c $configuration)"
  dotnet build "$tool_sln" --configuration "$configuration"
done

mkdir -p artifacts/ci
# By default, run test apps one at a time. Test apps starting in parallel under one dotnet-coverage
# session race in the coverage profiler and crash with SIGBUS (exit 135), usually hidden by a restart.
# Workaround for https://github.com/microsoft/codecoverage/issues/253. Remove once that is fixed.
# -p skips the workaround, for environments where that issue does not seem to have been observed.
test_parallel_args=" --max-parallel-test-modules 1"
if [[ "$parallel_tests" == true ]]; then
  test_parallel_args=""
fi
test_inner="dotnet test $sln --no-build --configuration $configuration${test_parallel_args} --report-xunit-xml --results-directory artifacts/ci"

echo "==> $test_inner"
coverage_cmd=""
if dotnet coverage --help >/dev/null 2>&1; then
  coverage_cmd="dotnet coverage"
elif command -v dotnet-coverage >/dev/null 2>&1; then
  coverage_cmd="dotnet-coverage"
elif [[ -x "${HOME}/.dotnet/tools/dotnet-coverage" ]]; then
  coverage_cmd="${HOME}/.dotnet/tools/dotnet-coverage"
else
  echo "ERROR: dotnet coverage is not installed." >&2
  exit 1
fi

# dotnet-coverage leaves CodeCoverage.<session-id>.* files in /tmp. Use a known session ID so
# this run's files can be removed. Clean up on any exit, including test failures and crashes.
if [[ -r /proc/sys/kernel/random/uuid ]]; then
  coverage_session="$(cat /proc/sys/kernel/random/uuid)"
else
  coverage_session="$(uuidgen | tr '[:upper:]' '[:lower:]')"
fi

cleanup_coverage_tmp() {
  find /tmp -maxdepth 1 -name "CodeCoverage.${coverage_session}.*" -delete 2>/dev/null || true
}
trap cleanup_coverage_tmp EXIT

$coverage_cmd collect --session-id "$coverage_session" "$test_inner" -f xml -o artifacts/ci/coverage.cobertura.xml

echo "==> build clean"
