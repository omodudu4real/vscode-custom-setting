#!/usr/bin/env bash

set -euo pipefail

# Update injected custom CSS and reload every available VS Code command server.
# Servers that are not running are simply skipped.

for port in {3000..3009}; do

    # Skip if this VS Code command server is not reachable.
    if ! curl -fsS -m 1 "http://localhost:$port/info" >/dev/null 2>&1; then
        continue
    fi

    # Update injected custom CSS.
    curl -fsS -m 2 -X POST "http://localhost:$port/execute" \
        -H "Content-Type: application/json" \
        -d '{"command":"extension.updateCustomCSS","args":[]}' \
        >/dev/null 2>&1 || continue

    # Small pause so VS Code registers the update request.
    sleep 0.4

    # Reload the current VS Code window.
    curl -fsS -m 2 -X POST "http://localhost:$port/execute" \
        -H "Content-Type: application/json" \
        -d '{"command":"workbench.action.reloadWindow","args":[]}' \
        >/dev/null 2>&1 || continue

done
