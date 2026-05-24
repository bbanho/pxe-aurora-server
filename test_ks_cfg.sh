#!/usr/bin/env bash
set -euo pipefail

# Test: tftpboot/ks.cfg validation for PXE Aurora Server
# RED phase: this test should FAIL first (no ks.cfg exists)

WORKTREE="/var/home/bruno/Documentos/workspace/pxe/.hive/.worktrees/pxe-aurora-server/06-kickstart"
KS_CFG="$WORKTREE/tftpboot/ks.cfg"
errors=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; errors=$((errors + 1)); }

check_directive() {
    local pattern="$1"
    local label="$2"
    if grep -qE "$pattern" "$KS_CFG" 2>/dev/null; then
        pass "$label"
    else
        fail "$label (expected '$pattern')"
    fi
}

echo "=== ks.cfg Validation ==="

# Test 1: File exists
echo "--- Test: File exists ---"
if [ -f "$KS_CFG" ]; then
    pass "tftpboot/ks.cfg exists"
else
    fail "tftpboot/ks.cfg does not exist"
fi

# Test 2: Text mode (sem GUI)
echo "--- Test: Installer mode ---"
check_directive "^text$" "text mode (no GUI)"

# Test 3: Keyboard layout
echo "--- Test: Keyboard ---"
check_directive "keyboard.*br-abnt2" "keyboard br-abnt2"

# Test 4: Language
echo "--- Test: Language ---"
check_directive "lang pt_BR\.UTF-8" "lang pt_BR.UTF-8"

# Test 5: Timezone
echo "--- Test: Timezone ---"
check_directive "timezone America/Sao_Paulo.*--utc" "timezone America/Sao_Paulo --utc"

# Test 6: Network
echo "--- Test: Network ---"
check_directive "network.*--bootproto=dhcp.*--device=link.*--activate" "network DHCP via link device"
check_directive "network.*--bootproto=dhcp" "network DHCP"
check_directive "network.*--activate" "network activate"

# Test 7: Disk clearing
echo "--- Test: Disk clearing ---"
check_directive "clearpart.*--all.*--initlabel.*--disklabel=gpt" "clearpart all initlabel GPT"
check_directive "clearpart.*--all" "clearpart --all"
check_directive "clearpart.*--initlabel" "clearpart --initlabel"
check_directive "clearpart.*--disklabel=gpt" "clearpart --disklabel=gpt"

# Test 8: Partitions
echo "--- Test: Partitioning ---"
check_directive "^reqpart --add-boot$" "reqpart --add-boot"
check_directive "^part / --grow --fstype=xfs$" "part / --grow --fstype=xfs"

# Test 9: ostreecontainer
echo "--- Test: OSTree container ---"
check_directive "ostreecontainer --url ghcr\.io/ublue-os/aurora:latest --no-signature-verification" "ostreecontainer Aurora latest"

# Test 10: Root password
echo "--- Test: Root password ---"
check_directive "^rootpw --lock$" "rootpw --lock"

# Test 11: User creation
echo "--- Test: User ---"
check_directive "^user --name=aurora --groups=wheel" "user aurora in wheel group"

# Test 12: Reboot
echo "--- Test: Reboot ---"
check_directive "^reboot --eject$" "reboot --eject"

echo ""
echo "=== Results: $errors failures ==="

# Check for any raw password (security concern)
if grep -q "^user.*--password=" "$KS_CFG" 2>/dev/null; then
    pass "user has --password flag (temporary password expected)"
fi

exit $errors
