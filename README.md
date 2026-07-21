# VS Code UI Redesign

A modern Visual Studio Code interface redesign built with **CSS** and **JavaScript** using the **Custom CSS and JS Loader** extension.

This project enhances the default VS Code experience with improved layouts, refined animations, cleaner spacing, and a more polished user interface while maintaining the familiar workflow developers love.

> ⚠️ This project is **not** a VS Code extension. It customizes the VS Code interface using injected CSS and JavaScript.

---

# Preview

> **Screenshots and GIFs coming soon**

## Explorer

![Explorer](images/explorer.png)

## Extensions

![Extensions](images/extensions.png)

## Notifications

![Notifications](images/notifications.gif)

---

# Features

- Modern VS Code interface redesign
- Beautiful notification animations
- Redesigned Extension Details panel
- Improved hover effects
- Cleaner spacing and alignment
- Better typography
- Custom UI components
- Lightweight visual effects
- Performance-conscious animations
- Easy to customize

---

# Performance

Performance was one of the goals while developing this project.

Instead of allowing animations to run continuously in the background, UI elements are designed so animations only run when they are actually visible.

Some optimizations include:

- Dynamic UI injection using JavaScript
- MutationObserver for detecting newly created VS Code elements
- Animations that activate only when required
- Reduced unnecessary rendering work
- Battery-friendly animation behavior

---

# Requirements

Install the following VS Code extension:

- **Custom CSS and JS Loader**

---

# Installation

## 1. Install Custom CSS and JS Loader

Install the extension from the Visual Studio Code Marketplace.

---

## 2. Clone this repository

```bash
git clone https://github.com/your-username/your-repository.git
```

---

## 3. Copy the project files

Place the CSS and JavaScript files somewhere on your computer.

Example:

```
C:\VSCode-Custom\
```

or

```
~/VSCode-Custom/
```

---

## 4. Update your settings.json

Add:

```json
"vscode_custom_css.imports": [
    "file:///absolute/path/custom-vscode.css",
    "file:///absolute/path/custom-vscode.js"
]
```

Examples:

Linux

```json
"file:///home/username/custom-vscode.css"
```

Windows

```json
"file:///C:/VSCode-Custom/custom-vscode.css"
```

---

## 5. Enable Custom CSS

Open the Command Palette.

Run:

```
Enable Custom CSS and JS
```

Restart VS Code.

---

## 6. Reload after making changes

Whenever you modify the CSS or JavaScript files, run:

```
Reload Custom CSS and JS
```

---

# Linux & macOS

If VS Code cannot modify itself, change the ownership of the installation directory.

```bash
sudo chown -R $(whoami) "$(which code)"
sudo chown -R $(whoami) /usr/share/code
```

If your installation directory is different, replace:

```
/usr/share/code
```

with the correct location.

---

# Customization

Feel free to customize:

- Colors
- Fonts
- Icons
- Animations
- Borders
- Shadows
- Layouts
- JavaScript behavior

Make it your own.

---

# Recommended Fonts

- Fira Code
- Cascadia Code
- JetBrains Mono

---

# Recommended Extensions

- Custom CSS and JS Loader
- Material Icon Theme
- Fluent Icons
- Prettier
- ESLint

---

# Roadmap

- [x] Notification redesign
- [x] Extension panel redesign
- [x] Custom animations
- [x] JavaScript enhancements
- [ ] Activity Bar redesign
- [ ] Search panel redesign
- [ ] Settings redesign
- [ ] Command Palette redesign

---

# Contributing

Suggestions, bug reports, and pull requests are welcome.

If you have ideas for improving the interface or performance, feel free to open an issue.

---

# License

This project is licensed under the MIT License.

---

# Acknowledgements

- Microsoft Visual Studio Code
- Custom CSS and JS Loader
- The VS Code community
