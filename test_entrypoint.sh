#!/usr/bin/env bash
# Test: entrypoint.sh validation
# Tests that entrypoint.sh meets acceptance criteria:
# 1. File exists and is executable
# 2. Has proper shebang
# 3. Has SIGTERM/SIGINT trap for graceful shutdown
# 4. Starts nginx in background
# 5. Starts dnsmasq in foreground (keeps container alive)
# 6. Propagates exit codes correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENTRYPOINT="${SCRIPT_DIR}/entrypoint.sh"
PASS=0
FAIL=0

pass() {
    PASS=$((PASS + 1))
    echo "  ✓ $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo "  ✗ $1"
}

check() {
    local name="$1"
    local result="$2"
    if [ "$result" = "true" ]; then
        pass "$name"
    else
        fail "$name"
    fi
}

echo "=== TDD RED Phase: Testing entrypoint.sh ==="
echo ""

# Test 1: File exists
echo "1) File existence and permissions"
exists="false"
[ -f "$ENTRYPOINT" ] && exists="true"
check "entrypoint.sh exists" "$exists"

# Test 2: File is executable
executable="false"
[ -x "$ENTRYPOINT" ] && executable="true"
check "entrypoint.sh is executable (+x)" "$executable"

# Test 3: Has shebang
echo "2) Shebang"
if [ "$exists" = "true" ]; then
    shebang="$(head -1 "$ENTRYPOINT")"
    case "$shebang" in
        "#!/bin/sh"|"#!/bin/bash"|"#!/usr/bin/env bash"|"#!/usr/bin/env sh")
            check "Shebang line: $shebang" "true"
            ;;
        *)
            check "Shebang line: $shebang (unexpected)" "false"
            ;;
    esac
else
    check "Shebang (file missing)" "false"
fi

# Test 4: Has trap for SIGTERM and SIGINT
echo "3) Signal handling"
if [ "$exists" = "true" ]; then
    # Check for trap with TERM or INT signals
    has_trap="false"
    if grep -q 'trap\s' "$ENTRYPOINT" && (grep -Eq 'TERM|INT' "$ENTRYPOINT"); then
        has_trap="true"
    fi
    check "trap for SIGTERM/SIGINT" "$has_trap"

    # Check trap calls cleanup function or kill
    has_trap_handler="false"
    if grep -q 'trap\s.*\s\(TERM\|INT\|EXIT\)' "$ENTRYPOINT" || grep -qE "trap '.*(kill|exit|cleanup).*' (TERM|INT)" "$ENTRYPOINT"; then
        has_trap_handler="true"
    fi
    check "trap calls kill/cleanup" "$has_trap_handler"
else
    check "trap for SIGTERM/SIGINT (file missing)" "false"
    check "trap calls kill/cleanup (file missing)" "false"
fi

# Test 5: Starts nginx in background
echo "4) nginx startup"
if [ "$exists" = "true" ]; then
    nginx_bg="false"
    if grep -q 'nginx' "$ENTRYPOINT"; then
        nginx_bg="true"
    fi
    check "nginx referenced in script" "$nginx_bg"

    nginx_background="false"
    # Match literal nginx or NGINX_BIN var with & (background) or daemon off (nginx fork mode)
    if grep -qE '(nginx|NGINX_BIN).*(&|daemon off)' "$ENTRYPOINT" || grep -qE '(start|Starting).*nginx.*&' "$ENTRYPOINT"; then
        nginx_background="true"
    fi
    check "nginx runs in background (&)" "$nginx_background"
else
    check "nginx referenced (file missing)" "false"
    check "nginx background (file missing)" "false"
fi

# Test 6: Starts dnsmasq in foreground
echo "5) dnsmasq startup"
if [ "$exists" = "true" ]; then
    dnsmasq_fg="false"
    if grep -q 'dnsmasq' "$ENTRYPOINT"; then
        dnsmasq_fg="true"
    fi
    check "dnsmasq referenced in script" "$dnsmasq_fg"

    dnsmasq_foreground="false"
    # Match literal dnsmasq or DNSMASQ_BIN var with --no-daemon (foreground)
    # Ensure no & (background) on the --no-daemon line
    if grep -qE '(dnsmasq|DNSMASQ_BIN).*--no-daemon' "$ENTRYPOINT"; then
        if grep -qE '(dnsmasq|DNSMASQ_BIN).*--no-daemon.*&' "$ENTRYPOINT"; then
            dnsmasq_foreground="false"
        else
            dnsmasq_foreground="true"
        fi
    fi
    check "dnsmasq runs in foreground (--no-daemon, no &)" "$dnsmasq_foreground"
else
    check "dnsmasq referenced (file missing)" "false"
    check "dnsmasq foreground (file missing)" "false"
fi

# Test 7: Exit code propagation
echo "6) Exit code propagation"
if [ "$exists" = "true" ]; then
    exit_propagate="false"
    # Match exit code capture (_exit=$?) and exit with that code
    if grep -qE '_exit=\$|exit_code=\$|exit "\$\{?[a-z_]+_exit' "$ENTRYPOINT" || grep -qE 'set -e|set -o errexit' "$ENTRYPOINT"; then
        exit_propagate="true"
    fi
    check "Exit code propagation" "$exit_propagate"
else
    check "Exit code propagation (file missing)" "false"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
