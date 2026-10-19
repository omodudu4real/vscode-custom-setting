#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
echo "DPkg::Post-Invoke { \"python3 $DIR/apply.py >> /var/log/vscode-webview-css.log 2>&1 || true\"; };" | sudo tee /etc/apt/apt.conf.d/99vscode-webview-css
