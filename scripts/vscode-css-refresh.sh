#!/usr/bin/env bash
set -euo pipefail

# Do nothing if VS Code command server is not reachable
if ! curl -fsS -m 1 http://localhost:3000/info >/dev/null 2>&1; then
  exit 0
fi

# Update injected custom CSS for server 1
curl -fsS -m 2 -X POST http://localhost:3000/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Small pause so VS Code registers the update request
sleep 0.4

# Reload the current VS Code window for server 1
curl -fsS -m 2 -X POST http://localhost:3000/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0

# Update injected custom CSS for server 2
curl -fsS -m 2 -X POST http://localhost:3001/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 2
curl -fsS -m 2 -X POST http://localhost:3001/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 3
curl -fsS -m 2 -X POST http://localhost:3002/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 3
curl -fsS -m 2 -X POST http://localhost:3002/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 4
curl -fsS -m 2 -X POST http://localhost:3003/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 4
curl -fsS -m 2 -X POST http://localhost:3003/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 5
curl -fsS -m 2 -X POST http://localhost:3004/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 5
curl -fsS -m 2 -X POST http://localhost:3004/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 6
curl -fsS -m 2 -X POST http://localhost:3005/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 6
curl -fsS -m 2 -X POST http://localhost:3005/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 7
curl -fsS -m 2 -X POST http://localhost:3006/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 7
curl -fsS -m 2 -X POST http://localhost:3006/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 8
curl -fsS -m 2 -X POST http://localhost:3007/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 8
curl -fsS -m 2 -X POST http://localhost:3007/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 9
curl -fsS -m 2 -X POST http://localhost:3008/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 9
curl -fsS -m 2 -X POST http://localhost:3008/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0


# Update injected custom CSS for server 10
curl -fsS -m 2 -X POST http://localhost:3009/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"extension.updateCustomCSS","args":[]}' >/dev/null 2>&1 || exit 0

# Reload the current VS Code window for server 10
curl -fsS -m 2 -X POST http://localhost:3009/execute \
  -H "Content-Type: application/json" \
  -d '{"command":"workbench.action.reloadWindow","args":[]}' >/dev/null 2>&1 || exit 0
