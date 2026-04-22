#!/usr/bin/env bash
set -euo pipefail

ports=()

for port in {3000..3010}; do
  if  curl -fsS -m 1 http://localhost:$port/info >/dev/null 2>&1; then
    ports+=("$port")
  fi
done

# exit early if none found
[ ${#ports[@]} -eq 0 ] && exit 0

# Update injected custom CSS for server 1
for port in "${ports[@]}"; do
  curl -fsS -m 2 -X POST http://localhost:$port/execute \
    -H "Content-Type: application/json" \
    -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || true
done

# Small pause so VS Code registers the update request
# sleep 0.4

# Reload the current VS Code window
for port in "${ports[@]}"; do
  curl -fsS -m 2 -X POST http://localhost:$port/execute \
    -H "Content-Type: application/json" \
    -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || true
done

