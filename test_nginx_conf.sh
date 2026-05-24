#!/usr/bin/env bash
set -euo pipefail

# Test: config/nginx.conf should exist with required directives
CONFIG="config/nginx.conf"
errors=0

echo "--- Test: $CONFIG ---"

# File must exist
if [ ! -f "$CONFIG" ]; then
    echo "FAIL: $CONFIG not found"
    exit 1
fi

check_directive() {
    local pattern="$1"
    local label="$2"
    if grep -qE "$pattern" "$CONFIG"; then
        echo "PASS: $label"
    else
        echo "FAIL: $label (expected '$pattern')"
        errors=$((errors + 1))
    fi
}

# Acceptance criteria
check_directive "listen\s+8080" "listen 8080"
check_directive "root\s+/tftpboot" "root /tftpboot"
check_directive "autoindex\s+on" "autoindex on"
check_directive "application/octet-stream" "mime type for binaries"
check_directive "sendfile\s+on" "sendfile on"

# Structural sanity
check_directive "server\s*{" "server block open"
check_directive "}" "server block close"
check_directive "types\s*{" "types block open"

echo ""
if [ "$errors" -eq 0 ]; then
    echo "All tests PASSED"
    exit 0
else
    echo "$errors test(s) FAILED"
    exit 1
fi
