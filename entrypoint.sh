#!/bin/sh
# PXE Aurora Server - All-in-One entrypoint
# Starts nginx in background and dnsmasq in foreground
# with proper SIGTERM/SIGINT signal handling for graceful shutdown.

NGINX_BIN="${NGINX_BIN:-nginx}"
DNSMASQ_BIN="${DNSMASQ_BIN:-dnsmasq}"

# Graceful shutdown handler
cleanup() {
    echo "[entrypoint] Shutting down nginx (PID ${nginx_pid:-unknown})..."
    kill "${nginx_pid}" 2>/dev/null || true
    exit 0
}

# Trap Docker stop (SIGTERM) and Ctrl+C (SIGINT)
trap cleanup TERM INT

# Start nginx in background
echo "[entrypoint] Starting nginx..."
"${NGINX_BIN}" -g 'daemon off;' &
nginx_pid=$!
echo "[entrypoint] nginx started (PID ${nginx_pid})"

# Start dnsmasq in foreground — keeps container alive
echo "[entrypoint] Starting dnsmasq..."
"${DNSMASQ_BIN}" --no-daemon "$@"
dnsmasq_exit=$?

echo "[entrypoint] dnsmasq exited with code ${dnsmasq_exit}, stopping nginx..."
kill "${nginx_pid}" 2>/dev/null || true
wait "${nginx_pid}" 2>/dev/null || true

exit "${dnsmasq_exit}"
