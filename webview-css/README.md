# Custom CSS for VS Code webview content

Styles the inside of webviews (extension details pages, Markdown preview, etc.).
The Custom CSS and JS Loader cannot reach them because the content lives in a
separate iframe document.

## How it works

- Webview content is an inner iframe (#active-frame) inside
  /usr/share/code/resources/app/out/vs/workbench/contrib/webview/browser/pre/index.html
- That page has a Content-Security-Policy allowing only inline scripts whose
  SHA-256 hash is listed, and VS Code does not serve extra files from that folder.
- apply.py makes two edits:
  1. inserts an inline script before </body> that injects custom.css into the iframe
  2. adds that script's hash to the script-src line in <head>
- The patch is wrapped in MYCSS-START / MYCSS-END markers, so re-running removes
  the old patch first and applies a fresh one.

## Files

- custom.css          your styles (edit this)
- apply.py            applies the patch
- install-hook.sh     installs the apt hook (run once per machine)
- index.clean.html    clean copy of index.html from the VS Code version used

The hook lives outside this folder: /etc/apt/apt.conf.d/99vscode-webview-css
Log: /var/log/vscode-webview-css.log

## Setup on a new machine

1. Clone this folder.
2. Run: ~/.VSC_customize/webview-css/install-hook.sh
3. Run: sudo python3 ~/.VSC_customize/webview-css/apply.py
4. Restart VS Code.

## Changing the styling

1. Edit custom.css (no sudo needed).
2. Run: sudo python3 ~/.VSC_customize/webview-css/apply.py
3. Fully restart VS Code.

To find selectors: command palette > "Developer: Open Webview Developer Tools",
then use the element picker.

## After a VS Code update

Automatic: the apt hook re-runs apply.py after every apt/dpkg run.
Restart VS Code afterwards, and check that the extension details page still
shows content. If styling is missing, check the log.

## Undo / emergency restore

    sudo cp ~/.VSC_customize/webview-css/index.clean.html /usr/share/code/resources/app/out/vs/workbench/contrib/webview/browser/pre/index.html

Note: the hook will re-apply the patch on the next apt run. To disable it:

    sudo rm /etc/apt/apt.conf.d/99vscode-webview-css

Or reinstall the clean file:  sudo apt install --reinstall code

## Known limits

- Linux .deb install only (/usr/share/code). Not snap or flatpak.
- If a future VS Code changes index.html (the active-frame id, the CSP format),
  the script may stop working. It refuses to patch if the structure looks wrong.
- If VS Code shows an "installation appears to be corrupt" popup, use the
  "Fix VSCode Checksums" extension or choose "Don't Show Again".
- Never open index.html with `sudo code`. Edit with nano.
