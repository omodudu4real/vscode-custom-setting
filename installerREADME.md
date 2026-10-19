# After running the installer.sh there are Two manual steps remain:

- Open VS Code, press Ctrl+Shift+P and run: Enable Custom CSS and JS
- Restart VS Code when it asks.
  After each VS Code update, run "Reload Custom CSS and JS" once from the command palette.

---

## NOTE: Every update you have to also change ownership with this command

```bash
sudo chown -R $(whoami) "$(which code)"
sudo chown -R $(whoami) /usr/share/code
```

---
