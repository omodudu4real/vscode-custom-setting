#!/bin/bash

curl -fsS -m 1 -X POST http://localhost:3000/execute \
-H "Content-Type: application/json" \
-d '{"command":"workbench.action.reloadWindow"}'
