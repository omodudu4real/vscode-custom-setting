/*  __     __   ______    ______    ______   _______   ________         ______   __    __   ______   ________  ______   __       __  ______  ________   ______   ________  ______   ______   __    __
/  |   /  | /      \  /      \  /      \ /       \ /        |       /      \ /  |  /  | /      \ /        |/      \ /  \     /  |/      |/        | /      \ /        |/      | /      \ /  \  /  |
$$ |   $$ |/$$$$$$  |/$$$$$$  |/$$$$$$  |$$$$$$$  |$$$$$$$$/       /$$$$$$  |$$ |  $$ |/$$$$$$  |$$$$$$$$//$$$$$$  |$$  \   /$$ |$$$$$$/ $$$$$$$$/ /$$$$$$  |$$$$$$$$/ $$$$$$/ /$$$$$$  |$$  \ $$ |
$$ |   $$ |$$ \__$$/ $$ |  $$/ $$ |  $$ |$$ |  $$ |$$ |__          $$ |  $$/ $$ |  $$ |$$ \__$$/    $$ |  $$ |  $$ |$$$  \ /$$$ |  $$ |      /$$/  $$ |__$$ |   $$ |     $$ |  $$ |  $$ |$$$  \$$ |
$$  \ /$$/ $$      \ $$ |      $$ |  $$ |$$ |  $$ |$$    |         $$ |      $$ |  $$ |$$      \    $$ |  $$ |  $$ |$$$$  /$$$$ |  $$ |     /$$/   $$    $$ |   $$ |     $$ |  $$ |  $$ |$$$$  $$ |
 $$  /$$/   $$$$$$  |$$ |   __ $$ |  $$ |$$ |  $$ |$$$$$/          $$ |   __ $$ |  $$ | $$$$$$  |   $$ |  $$ |  $$ |$$ $$ $$/$$ |  $$ |    /$$/    $$$$$$$$ |   $$ |     $$ |  $$ |  $$ |$$ $$ $$ |
  $$ $$/   /  \__$$ |$$ \__/  |$$ \__$$ |$$ |__$$ |$$ |_____       $$ \__/  |$$ \__$$ |/  \__$$ |   $$ |  $$ \__$$ |$$ |$$$/ $$ | _$$ |_  /$$/____ $$ |  $$ |   $$ |    _$$ |_ $$ \__$$ |$$ |$$$$ |
   $$$/    $$    $$/ $$    $$/ $$    $$/ $$    $$/ $$       |______$$    $$/ $$    $$/ $$    $$/    $$ |  $$    $$/ $$ | $/  $$ |/ $$   |/$$      |$$ |  $$ |   $$ |   / $$   |$$    $$/ $$ | $$$ |
    $/      $$$$$$/   $$$$$$/   $$$$$$/  $$$$$$$/  $$$$$$$$//      |$$$$$$/   $$$$$$/   $$$$$$/     $$/    $$$$$$/  $$/      $$/ $$$$$$/ $$$$$$$$/ $$/   $$/    $$/    $$$$$$/  $$$$$$/  $$/   $$/
                                                            $$$$$$/


                                                                                     _______   __      __
                                                                                    /       \ /  \    /  |
                                                                                    $$$$$$$  |$$  \  /$$/__
                                                                                    $$ |__$$ | $$  \/$$//  |
                                                                                    $$    $$<   $$  $$/ $$/
                                                                                    $$$$$$$  |   $$$$/   __
                                                                                    $$ |__$$ |    $$ |  /  |
                                                                                    $$    $$/     $$ |  $$/
                                                                                    $$$$$$$/      $$/



                                                              ______   __       __   ______   _______   __    __  _______   __    __
                                                             /      \ /  \     /  | /      \ /       \ /  |  /  |/       \ /  |  /  |
                                                            /$$$$$$  |$$  \   /$$ |/$$$$$$  |$$$$$$$  |$$ |  $$ |$$$$$$$  |$$ |  $$ |
                                                            $$ |  $$ |$$$  \ /$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
                                                            $$ |  $$ |$$$$  /$$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
                                                            $$ |  $$ |$$ $$ $$/$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
                                                            $$ \__$$ |$$ |$$$/ $$ |$$ \__$$ |$$ |__$$ |$$ \__$$ |$$ |__$$ |$$ \__$$ |
                                                            $$    $$/ $$ | $/  $$ |$$    $$/ $$    $$/ $$    $$/ $$    $$/ $$    $$/
                                                             $$$$$$/  $$/      $$/  $$$$$$/  $$$$$$$/   $$$$$$/  $$$$$$$/   $$$$$$/


                                                                                                                                                                                                         */

// This code checks for annoying "Code Installation Corrupt" notifications and prevents them from showing

window.addEventListener('DOMContentLoaded', () => {
  const myObservation = new MutationObserver(() => {
    document
      .querySelectorAll('.notification-toast-container')
      .forEach((element) => {
        const ports = [];
        if (
          element.textContent.includes(
            'Your Code installation appears to be corrupt. Please reinstall.'
          )
        ) {
          element.style.display = 'none'; // Hide the corrupt install notification
        }

        // VSCode Command Server started on port 3000 but you can have as many port as possible
        if (
          /VSCode Command Server started on port \d+\.?/.test(
            element.textContent
          )
        ) {
          element.style.display = 'none'; // Hide the corrupt install notification
        }
      });
  });

  // Start observing the body for new notifications
  myObservation.observe(document.body, { childList: true, subtree: true });
});

document.addEventListener('DOMContentLoaded', function () {
  // ✅ Use a counter to avoid endless retries
  let retryCount = 0;
  const maxRetries = 20; // ~10 seconds (20 * 500ms)

  const checkElement = setInterval(() => {
    const commandDialog = document.querySelector('.quick-input-widget');
    if (commandDialog) {
      setupObserver(commandDialog);
      clearInterval(checkElement); // ✅ Stop interval once found
    } else {
      retryCount++;
      if (retryCount >= maxRetries) {
        clearInterval(checkElement); // ✅ Prevent infinite console spam
        console.warn(
          'Command dialog not found after max retries. Waiting for DOM changes...'
        );

        // ✅ Fallback: watch for late creation of .quick-input-widget
        const fallbackObserver = new MutationObserver(() => {
          const lateDialog = document.querySelector('.quick-input-widget');
          if (lateDialog) {
            setupObserver(lateDialog);
            fallbackObserver.disconnect(); // Stop watching once found
          }
        });
        fallbackObserver.observe(document.body, {
          childList: true,
          subtree: true
        });
      } else {
        console.log('Command dialog not found yet. Retrying...');
      }
    }
  }, 500);

  // Function: attach observer to watch show/hide state
  function setupObserver(commandDialog) {
    // Apply blur immediately if dialog is already visible
    if (commandDialog.style.display !== 'none') {
      runMyScript();
    }

    // Watch for open/close changes via style attribute
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (
          mutation.type === 'attributes' &&
          mutation.attributeName === 'style'
        ) {
          if (commandDialog.style.display === 'none') {
            handleEscape();
          } else {
            runMyScript();
          }
        }
      });
    });

    observer.observe(commandDialog, { attributes: true });
    console.log('✅ Command dialog observer attached.');
  }

  // Key listener: Ctrl+P / Cmd+P opens palette → run blur
  document.addEventListener('keydown', function (event) {
    if ((event.metaKey || event.ctrlKey) && event.key === 'p') {
      event.preventDefault();
      runMyScript();
    } else if (event.key === 'Escape' || event.key === 'Esc') {
      event.preventDefault();
      handleEscape();
    }
  });

  // Global Escape listener (capture phase, catches all Esc presses)
  document.addEventListener(
    'keydown',
    function (event) {
      if (event.key === 'Escape' || event.key === 'Esc') {
        handleEscape();
      }
    },
    true
  );

  // Function: adds blur overlay and hides widgets
  function runMyScript() {
    const targetDiv = document.querySelector('.monaco-workbench');
    if (!targetDiv) return;

    // Remove existing blur overlay
    const existingElement = document.getElementById('command-blur');
    existingElement && existingElement.remove();

    // Create new blur overlay
    const newElement = document.createElement('div');
    newElement.setAttribute('id', 'command-blur');
    newElement.addEventListener('click', function () {
      newElement.remove();
    });

    // Add overlay to workbench
    targetDiv.appendChild(newElement);

    // Hide sticky widgets
    const widgets = document.querySelectorAll('.sticky-widget');
    widgets.forEach((widget) => {
      widget.style.opacity = 0;
    });

    const treeWidget = document.querySelector('.monaco-tree-sticky-container');
    treeWidget && (treeWidget.style.opacity = 0);
  }

  // Function: removes blur overlay and restores widgets
  function handleEscape() {
    const element = document.getElementById('command-blur');
    element && element.click();

    // Restore sticky widgets
    const widgets = document.querySelectorAll('.sticky-widget');
    widgets.forEach((widget) => {
      widget.style.opacity = 1;
    });

    const treeWidget = document.querySelector('.monaco-tree-sticky-container');
    treeWidget && (treeWidget.style.opacity = 1);
  }
});

/* FOR DEBUGGING ALT + , */

document.addEventListener('keydown', (e) => {
  if (e.altKey && e.code === 'Comma') {
    e.preventDefault();

    const accountIcon = document.querySelector(
      '.action-label.codicon.codicon-accounts-view-bar-icon[aria-label="Accounts"]'
    );
    if (accountIcon) {
      accountIcon.click();

      setTimeout(() => {
        debugger;
      }, 150);
    }
  }
});

/* Styling the RightClick and other popups
this is done here because it's a lifecycle
element so it get destroyed and re-born. */

window.addEventListener('DOMContentLoaded', () => {
  const rootObserver = new MutationObserver(() => {
    const host = document.querySelector('.shadow-root-host');
    if (!host || !host.shadowRoot) return;

    const shadow = host.shadowRoot;

    if (!shadow.querySelector('#custom-menu-style')) {
      const style = document.createElement('style');
      style.id = 'custom-menu-style';
      style.textContent = `
      .monaco-menu {
        box-shadow: 0px 8px 32px rgba(0, 0, 0, 0.45) !important;
        background-image: linear-gradient(#3c3c50 0%, #2a2b38 100%) !important;
        border-radius: 16px !important;
        border: 1px solid var(--primary) !important;
        outline: 1px !important;
        padding-bottom: 0px !important;
        color: var(--primary) !important;
        overflow: hidden !important;
      }

      /* This ensures the text inside actually uses your variable */
      .monaco-menu .action-label,
      .monaco-menu .keybinding,
      .monaco-menu .action-menu-item {
        color: var(--primary) !important;
      }
    `;
      shadow.appendChild(style);
    }
  });

  rootObserver.observe(document.body, {
    childList: true,
    subtree: true
  });
  ``;
});
