# Instructions

**NOTE:** Please take time to read the short documentation of **"Custom CSS and JS Loader"** for some useful tips for various operating systems to avoid issues regarding the changes not taking effect.

1. Install "Custom CSS and JS Loader" VS Code Extension.
2. Copy the contents of settings.json to your VS Code's settings.json (warning: it will overwrite your settings).
3. Add `vscode_custom_css.imports` array to your settings.json file:
```
"vscode_custom_css.imports": [
    // Absolute file paths for your css/js files
    // For Mac or Linux
    // "file:///home/your-user-name/file-name.extension(.css)",
    // "file:///Users/your-user-name/file-name.extension(.js)"

    // For Windows
    // "file:///C:/path-of-custom-css/custom-vscode.css",
    // "file:///C:/path-of-custom-css/custom-vscode-script.js"
],
```
4. You might need to take ownership of the CSS/JS files you made or run VS Code with admin privileges on certain operating system:
```
Mac and Linux users
The extension would NOT work if Visual Studio Code cannot modify itself. The cases include:

Code files being read-only, like on a read-only file system or,
Code is not started with the permissions to modify itself.
You need to claim ownership on Visual Studio Code's installation directory, by running this command:

To Fix this just type this in your Linux or MacOs
sudo chown -R $(whoami) "$(which code)"
sudo chown -R $(whoami) /usr/share/code


Note: Replace /usr/share/code where your VS Code is installed.
sudo chown -R your-user-name /usr/share/code
```
5. Enable "Custom CSS and JS Loader" from VS Code's command dialog.
6. Customize the css or js from this repo to make it look the way you want to, or even better, explore areas of VS Code that you want to customize.
7. After making some changes, reload the extension (Reload Custom CSS and JS) from VS Code's command dialog.

```
Installed Extension:
1.  Easy Icon Theme
2.  React Dev Theme (dark)
3.  Prettier Code Formater
4.  ESLint
5.  Emmet
6.  Custom CSS and JS Loader
7.  HTML CSS Support
8.  HTML/CSS/JavaScript Snippets
9.  Intellisense for CSS class names in HTML
10. Live Server
11. Material Icon Theme
12. vscode-styled components
13. Tailwind CSS intellisense
14. lit-html
15. es6-string-html
16. es6-string-javascipt
17. es6-string-css

Installed Fonts
1.  Fira Code iScript (developer font)
2.  Fira Code (developer font)
3.  Cascadia Code (developer font)
4.  Akaya Kanadaka (google font)
5.  Merienda (google font)
```
