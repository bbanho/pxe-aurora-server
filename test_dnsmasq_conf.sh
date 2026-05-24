#!/bin/bash
# Test: validate dnsmasq.conf for PXE Aurora Server
# RED phase: this test should FAIL first (no config file exists)

set -euo pipefail

CONFIG="config/dnsmasq.conf"
WORKTREE="/var/home/bruno/Documentos/workspace/pxe/.hive/.worktrees/pxe-aurora-server/03-dnsmasq-conf"
CONFIG_PATH="$WORKTREE/$CONFIG"

failures=0
pass()  { echo "  PASS: $1"; }
fail()  { echo "  FAIL: $1"; failures=$((failures + 1)); }

echo "=== dnsmasq.conf Validation ==="

# Test 1: File exists
echo "--- Test: File exists ---"
if [ -f "$CONFIG_PATH" ]; then
    pass "config/dnsmasq.conf exists"
else
    fail "config/dnsmasq.conf does not exist"
fi

# Test 2: dnsmasq syntax validation
echo "--- Test: dnsmasq syntax ---"
if dnsmasq --test -C "$CONFIG_PATH" 2>&1; then
    pass "dnsmasq syntax is valid"
else
    fail "dnsmasq syntax is invalid"
fi

# Test 3: Interface binding
echo "--- Test: Interface config ---"
if grep -q "^interface=enp3s0$" "$CONFIG_PATH" 2>/dev/null; then
    pass "interface=enp3s0 set"
else
    fail "interface=enp3s0 missing"
fi

if grep -q "^bind-dynamic$" "$CONFIG_PATH" 2>/dev/null; then
    pass "bind-dynamic set"
else
    fail "bind-dynamic missing"
fi

# Test 4: DHCP range
echo "--- Test: DHCP range ---"
if grep -q "^dhcp-range=192\.168\.200\.150,192\.168\.200\.250,12h$" "$CONFIG_PATH" 2>/dev/null; then
    pass "dhcp-range correct"
else
    fail "dhcp-range missing or incorrect"
fi

# Test 5: DHCP options (gateway and DNS)
echo "--- Test: DHCP options ---"
if grep -q "^dhcp-option=3,192\.168\.200\.1$" "$CONFIG_PATH" 2>/dev/null; then
    pass "dhcp-option=3 (gateway) set"
else
    fail "dhcp-option=3 (gateway) missing"
fi

if grep -q "^dhcp-option=6,192\.168\.200\.1$" "$CONFIG_PATH" 2>/dev/null; then
    pass "dhcp-option=6 (DNS) set"
else
    fail "dhcp-option=6 (DNS) missing"
fi

# Test 6: BIOS tag (arch 0)
echo "--- Test: BIOS tag ---"
if grep -q "dhcp-match=set:bios,option:client-arch,0" "$CONFIG_PATH" 2>/dev/null; then
    pass "BIOS tag (arch 0) configured"
else
    fail "BIOS tag (arch 0) missing"
fi

# Test 7: UEFI tags (arch 7,9)
echo "--- Test: UEFI tags ---"
if grep -q "dhcp-match=set:efi64,option:client-arch,7" "$CONFIG_PATH" 2>/dev/null; then
    pass "UEFI tag (arch 7) configured"
else
    fail "UEFI tag (arch 7) missing"
fi

if grep -q "dhcp-match=set:efi64,option:client-arch,9" "$CONFIG_PATH" 2>/dev/null; then
    pass "UEFI tag (arch 9) configured"
else
    fail "UEFI tag (arch 9) missing"
fi

# Test 8: iPXE anti-loop userclass
echo "--- Test: iPXE anti-loop ---"
if grep -q "dhcp-userclass=set:ipxe,iPXE" "$CONFIG_PATH" 2>/dev/null; then
    pass "iPXE userclass (anti-loop) configured"
else
    fail "iPXE userclass (anti-loop) missing"
fi

# Test 9: BIOS boot file
echo "--- Test: BIOS boot file ---"
if grep -q "dhcp-boot=tag:bios,undionly\.kpxe" "$CONFIG_PATH" 2>/dev/null; then
    pass "BIOS boot file: undionly.kpxe"
else
    fail "BIOS boot file missing or incorrect"
fi

# Test 10: UEFI boot file
echo "--- Test: UEFI boot file ---"
if grep -q "dhcp-boot=tag:efi64,ipxe\.efi" "$CONFIG_PATH" 2>/dev/null; then
    pass "UEFI boot file: ipxe.efi"
else
    fail "UEFI boot file missing or incorrect"
fi

# Test 11: iPXE HTTP chainload
echo "--- Test: iPXE chainload ---"
if grep -q "dhcp-boot=tag:ipxe,http://192\.168\.200\.115:8080/boot\.ipxe" "$CONFIG_PATH" 2>/dev/null; then
    pass "iPXE chainload to HTTP configured"
else
    fail "iPXE chainload to HTTP missing or incorrect"
fi

# Test 12: TFTP config
echo "--- Test: TFTP config ---"
if grep -q "^enable-tftp$" "$CONFIG_PATH" 2>/dev/null; then
    pass "enable-tftp set"
else
    fail "enable-tftp missing"
fi

if grep -q "^tftp-root=/tftpboot$" "$CONFIG_PATH" 2>/dev/null; then
    pass "tftp-root=/tftpboot set"
else
    fail "tftp-root=/tftpboot missing or incorrect"
fi

echo ""
echo "=== Results: $failures failures ==="
exit $failures
