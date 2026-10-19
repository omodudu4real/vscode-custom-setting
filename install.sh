#!/bin/bash
# VS Code customization installer. Ubuntu/Debian only.
# Run as your NORMAL user (not with sudo): ./install.sh
# Test only the settings.json step:        ./install.sh --settings-only [path/to/settings.json]
set -e

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run this with sudo. Run it as your normal user."; exit 1
fi

USER_NAME="$(whoami)"
CFG="$HOME/.VSC_customize"
SRC="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.config/Code/User/settings.json"
BACKUP_DIR="$HOME/.VSC_customize.backup-$(date +%Y%m%d-%H%M%S)"

# ---------- settings.json helper (Python, understands JSON with comments) ----------
SETTINGS_PY=$(cat <<'PY'
import sys, os, json, shutil

KEY = "vscode_custom_css.imports"
WS = " \t\r\n\ufeff"

def skip_ws(t, i):
    n = len(t)
    while i < n:
        if t[i] in WS:
            i += 1
        elif t.startswith("//", i):
            j = t.find("\n", i)
            i = n if j == -1 else j
        elif t.startswith("/*", i):
            j = t.find("*/", i + 2)
            if j == -1:
                raise ValueError("unterminated /* comment")
            i = j + 2
        else:
            break
    return i

def str_end(t, i):
    j = i + 1
    n = len(t)
    while j < n:
        if t[j] == "\\":
            j += 2
            continue
        if t[j] == '"':
            return j + 1
        if t[j] == "\n":
            break
        j += 1
    raise ValueError("unterminated string")

def value_end(t, i):
    n = len(t)
    if i >= n:
        raise ValueError("file ends after a key")
    if t[i] == '"':
        return str_end(t, i)
    if t[i] in "[{":
        depth = 0
        j = i
        while j < n:
            j2 = skip_ws(t, j)
            if j2 != j:
                j = j2
                continue
            c = t[j]
            if c == '"':
                j = str_end(t, j)
                continue
            if c in "[{":
                depth += 1
            elif c in "]}":
                depth -= 1
                if depth == 0:
                    return j + 1
            j += 1
        raise ValueError("unterminated value")
    j = i
    while j < n and t[j] not in ",}] \t\r\n":
        j += 1
    return j

def strip_comments(t):
    out = []
    i = 0
    n = len(t)
    while i < n:
        if t[i] == '"':
            e = str_end(t, i)
            out.append(t[i:e])
            i = e
        elif t.startswith("//", i):
            j = t.find("\n", i)
            i = n if j == -1 else j
        elif t.startswith("/*", i):
            j = t.find("*/", i + 2)
            if j == -1:
                raise ValueError("unterminated /* comment")
            i = j + 2
            out.append(" ")
        else:
            out.append(t[i])
            i += 1
    return "".join(out)

def drop_trailing_commas(s):
    out = []
    i = 0
    n = len(s)
    while i < n:
        if s[i] == '"':
            e = str_end(s, i)
            out.append(s[i:e])
            i = e
        elif s[i] == ",":
            j = i + 1
            while j < n and s[j] in WS:
                j += 1
            if not (j < n and s[j] in "]}"):
                out.append(",")
            i += 1
        else:
            out.append(s[i])
            i += 1
    return "".join(out)

def parse(t):
    return json.loads(drop_trailing_commas(strip_comments(t)).lstrip("\ufeff"))

def analyze(t):
    n = len(t)
    i = 0
    stack = []
    a = {"open": None, "close": None, "prev": None, "keys": []}
    pairs = {"]": "[", "}": "{"}
    while True:
        i = skip_ws(t, i)
        if i >= n:
            break
        c = t[i]
        if a["close"] is not None:
            raise ValueError("unexpected content after the closing }")
        if a["open"] is None:
            if c != "{":
                raise ValueError("the top level of the file is not a { } object")
            a["open"] = i
            stack.append("{")
            a["prev"] = i
            i += 1
            continue
        if c == '"':
            e = str_end(t, i)
            if len(stack) == 1:
                k = skip_ws(t, e)
                if k < n and t[k] == ":":
                    vs = skip_ws(t, k + 1)
                    a["keys"].append((json.loads(t[i:e]), i, vs))
            a["prev"] = e - 1
            i = e
            continue
        if c in "[{":
            stack.append(c)
        elif c in "]}":
            if not stack or pairs[c] != stack[-1]:
                raise ValueError("unbalanced brackets")
            stack.pop()
            if not stack:
                a["close"] = i
                i += 1
                continue
        a["prev"] = i
        i += 1
    if a["open"] is not None and a["close"] is None:
        raise ValueError("the closing } of the file is missing")
    return a

def expected(home):
    base = "file://%s/.VSC_customize/" % home
    return [base + "custom-css.css", base + "custom-script.js", base + "colors/colors.css"]

def entry(home):
    items = ",\n".join("    " + json.dumps(p) for p in expected(home))
    return '"%s": [\n%s\n  ]' % (KEY, items)

def decide(t, home):
    a = analyze(t)
    if a["open"] is not None:
        try:
            parse(t)
        except ValueError as e:
            raise ValueError("the file is not valid JSON: %s" % e)
    found = [k for k in a["keys"] if k[0] == KEY]
    if len(found) > 1:
        raise ValueError("the setting %s appears more than once" % KEY)
    if not found:
        return "ABSENT", "", a, None
    _, ks, vs = found[0]
    ve = value_end(t, vs)
    cur = t[vs:ve]
    try:
        val = parse(cur)
    except ValueError:
        val = None
    if val == expected(home):
        return "SAME", "", a, None
    return "DIFFERENT", " ".join(cur.split())[:300], a, (ks, ve)

def build(t, home, mode, status, a, span):
    ent = entry(home)
    if status == "ABSENT":
        header = "\n  // CUSTOM CSS AND SCRIPTS SETTINGS FOR VSCODE\n  " + ent + "\n"
        if a["open"] is None:
            sep = "\n" if t and not t.endswith("\n") else ""
            return t + sep + "{" + header + "}\n"
        p = a["prev"]
        comma = "" if t[p] in "{," else ","
        return t[:p + 1] + comma + t[p + 1:a["close"]] + header + t[a["close"]:]
    ks, ve = span
    if mode == "replace":
        return t[:ks] + ent + t[ve:]
    if mode == "comment":
        if "*/" in t[ks:ve]:
            raise ValueError("your existing value contains */ so it cannot be commented out safely; choose replace or skip")
        return t[:ks] + "/* disabled by installer: " + t[ks:ve] + " */ " + ent + t[ve:]
    raise ValueError("unknown mode")

def main():
    cmd, path, home = sys.argv[1], sys.argv[2], sys.argv[3]
    mode = sys.argv[4] if len(sys.argv) > 4 else "add"
    try:
        with open(path, encoding="utf-8", newline="") as f:
            t = f.read()
        status, detail, a, span = decide(t, home)
        if cmd == "check":
            print(status + ("\t" + detail if detail else ""))
            return 0
        if status == "SAME":
            print("already configured")
            return 0
        new = build(t, home, mode, status, a, span)
        parse(new)
        real = os.path.realpath(path)
        tmp = real + ".installer-tmp"
        with open(tmp, "w", encoding="utf-8", newline="") as f:
            f.write(new)
        shutil.copymode(real, tmp)
        os.replace(tmp, real)
        print("written")
        return 0
    except (ValueError, OSError) as e:
        if cmd == "check":
            print("INVALID\t%s" % e)
            return 0
        print("ERROR\t%s" % e)
        return 1

sys.exit(main())
PY
)

CHOICE=""

ask() {
  if [ ! -r /dev/tty ]; then CHOICE="n"; return; fi
  local ans
  while true; do
    printf '\nThe %s "%s" already exists and is different.\n  y = overwrite it\n  n = skip (keep yours)\n  b = backup yours, then overwrite\nChoice [y/n/b]: ' "$2" "$1" > /dev/tty
    read -r ans < /dev/tty
    case "$ans" in
      y|n|b) CHOICE="$ans"; return ;;
    esac
  done
}

ask_settings() {
  if [ ! -r /dev/tty ]; then CHOICE="n"; return; fi
  local ans
  while true; do
    printf '\nYour settings.json already has "vscode_custom_css.imports" with a different value:\n  %s\n\n  y = replace it with the new value\n  c = comment yours out, then add the new value\n  n = skip (keep yours; the new files will not be loaded)\n(A backup of settings.json is made first.)\nChoice [y/c/n]: ' "$1" > /dev/tty
    read -r ans < /dev/tty
    case "$ans" in
      y|c|n) CHOICE="$ans"; return ;;
    esac
  done
}

apply_settings() {
  cp -p "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
  if python3 -c "$SETTINGS_PY" apply "$SETTINGS" "$HOME" "$1"; then
    echo "  settings.json updated (backup saved next to it as settings.json.bak.*)"
  else
    echo "  settings.json was NOT changed."
  fi
}

patch_settings() {
  mkdir -p "$(dirname "$SETTINGS")"
  [ -f "$SETTINGS" ] || : > "$SETTINGS"
  local result status detail
  result="$(python3 -c "$SETTINGS_PY" check "$SETTINGS" "$HOME")" || result=$'INVALID\tthe checker failed to run'
  status="${result%%$'\t'*}"
  detail=""
  [ "$result" != "$status" ] && detail="${result#*$'\t'}"

  case "$status" in
    SAME)
      echo "  vscode_custom_css.imports is already set correctly." ;;
    ABSENT)
      apply_settings add ;;
    DIFFERENT)
      ask_settings "$detail"
      case "$CHOICE" in
        y) apply_settings replace ;;
        c) apply_settings comment ;;
        *) echo "  settings.json left as it is." ;;
      esac ;;
    *)
      echo "  Could not safely edit $SETTINGS"
      echo "  Reason: $detail"
      echo "  Nothing was changed. Add this inside the top-level { } yourself:"
      cat <<BLOCK

  "vscode_custom_css.imports": [
    "file://$HOME/.VSC_customize/custom-css.css",
    "file://$HOME/.VSC_customize/custom-script.js",
    "file://$HOME/.VSC_customize/colors/colors.css"
  ]

BLOCK
      ;;
  esac
}

if [ "$1" = "--settings-only" ]; then
  [ -n "$2" ] && SETTINGS="$2"
  patch_settings
  exit 0
fi

if ! command -v apt-get >/dev/null; then
  echo "This installer supports Ubuntu/Debian (apt) only."; exit 1
fi

echo "== 1. Install VS Code from Microsoft's apt repository =="
sudo apt-get update
sudo apt-get install -y wget gpg apt-transport-https
if [ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  rm -f /tmp/packages.microsoft.gpg
fi
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
sudo apt-get update
sudo apt-get install -y code

echo "== 2. Copy the config into $CFG =="
mkdir -p "$CFG"

same() {
  if [ -d "$1" ] && [ -d "$2" ]; then diff -rq "$1" "$2" >/dev/null 2>&1
  elif [ -f "$1" ] && [ -f "$2" ]; then cmp -s "$1" "$2"
  else return 1; fi
}

if [ "$SRC" = "$CFG" ]; then
  echo "Already running from $CFG, nothing to copy."
else
  for s in "$SRC"/* "$SRC"/.[!.]*; do
    [ -e "$s" ] || continue
    name="$(basename "$s")"
    case "$name" in .git|install.sh) continue ;; esac
    d="$CFG/$name"
    kind="file"; [ -d "$s" ] && kind="folder"

    if [ ! -e "$d" ]; then
      cp -a "$s" "$d"; echo "  copied: $name"; continue
    fi
    if same "$s" "$d"; then continue; fi

    ask "$name" "$kind"
    case "$CHOICE" in
      y) rm -rf "$d"; cp -a "$s" "$d"; echo "  overwritten: $name" ;;
      b) mkdir -p "$BACKUP_DIR"
         mv "$d" "$BACKUP_DIR/$name"
         cp -a "$s" "$d"
         echo "  backed up and overwritten: $name" ;;
      *) echo "  skipped: $name" ;;
    esac
  done
  if [ -d "$BACKUP_DIR" ]; then echo "Your old files were saved in: $BACKUP_DIR"; fi
fi

mkdir -p "$CFG/colors" "$CFG/webview-css"
for f in custom-css.css custom-script.js colors/colors.css; do
  [ -f "$CFG/$f" ] || touch "$CFG/$f"
done

echo "== 3. Ownership (limited, keeps chrome-sandbox safe) =="
sudo chown -R "$USER_NAME" /usr/share/code/resources/app/out
sudo chown "$USER_NAME" /usr/share/code/resources/app/product.json 2>/dev/null || true

echo "== 4. settings.json =="
patch_settings

echo "== 5. Extensions =="
for ext in be5invis.vscode-custom-css \
           mikaelkristiansson87.react-theme-vscode \
           crimson206.vscode-command-server \
           eamodio.gitlens; do
  code --install-extension "$ext" --force
done

echo "== 6. Webview CSS patch + apt hook (keeps ownership after updates) =="
HOOK="DPkg::Post-Invoke { \"chown -R $USER_NAME /usr/share/code/resources/app/out >/dev/null 2>&1; python3 $CFG/webview-css/apply.py >> /var/log/vscode-webview-css.log 2>&1 || true\"; };"
echo "$HOOK" | sudo tee /etc/apt/apt.conf.d/99vscode-webview-css >/dev/null
if [ -f "$CFG/webview-css/apply.py" ]; then
  [ -f "$CFG/webview-css/custom.css" ] || touch "$CFG/webview-css/custom.css"
  sudo python3 "$CFG/webview-css/apply.py" || true
else
  echo "webview-css/apply.py not found, skipping the webview patch (ownership hook still installed)."
fi

cat <<MSG

Done. Two manual steps remain:
 1. Open VS Code, press Ctrl+Shift+P and run:  Enable Custom CSS and JS
 2. Restart VS Code when it asks.
After each VS Code update, run "Reload Custom CSS and JS" once from the command palette.
MSG
