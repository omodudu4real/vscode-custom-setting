import base64, hashlib, json, os, re, sys

BASE = os.path.dirname(os.path.abspath(__file__))
CSS_FILE = os.path.join(BASE, "custom.css")
TARGET = "/usr/share/code/resources/app/out/vs/workbench/contrib/webview/browser/pre/index.html"

def strip_patch(text):
    m = re.search(r"<!--MYCSS-START hash=([A-Za-z0-9+/=]+)-->.*?<!--MYCSS-END-->\n?", text, re.S)
    if m:
        text = text.replace(m.group(0), "")
        text = text.replace("'sha256-%s' " % m.group(1), "")
    return text

with open(TARGET, encoding="utf-8") as f:
    clean = strip_patch(f.read())

if "script-src 'sha256-" not in clean or "</body>" not in clean:
    print("Unexpected index.html structure. Not touching it.")
    sys.exit(1)

with open(CSS_FILE, encoding="utf-8") as f:
    css = f.read()

js = """
(function () {
  const CSS = %s;
  setInterval(() => {
    const f = document.getElementById('active-frame');
    try {
      const d = f && f.contentDocument;
      if (!d || !d.body || d.readyState !== 'complete') return;
      if (d.documentElement.hasAttribute('data-my-css')) return;
      d.documentElement.setAttribute('data-my-css', '1');
      const s = new f.contentWindow.CSSStyleSheet();
      s.replaceSync(CSS);
      d.adoptedStyleSheets = [...d.adoptedStyleSheets, s];
    } catch (e) {}
  }, 500);
})();
""" % json.dumps(css)

h = base64.b64encode(hashlib.sha256(js.encode()).digest()).decode()
new = clean.replace("script-src 'sha256-", "script-src 'sha256-%s' 'sha256-" % h, 1)
block = "<!--MYCSS-START hash=%s--><script>%s</script><!--MYCSS-END-->\n" % (h, js)
i = new.rfind("</body>")
new = new[:i] + block + new[i:]

with open(TARGET, "w", encoding="utf-8") as f:
    f.write(new)
print("Done, hash:", h)
