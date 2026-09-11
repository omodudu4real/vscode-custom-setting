const http = require('http');

const DEBUG_PORT = 9223;

/*
 * Normal monitoring.
 *
 * The injector checks slowly when nothing is happening,
 * keeping CPU and battery usage very low.
 */
const CHECK_INTERVAL = 1000;

/*
 * When a new webview appears, we check for active-frame
 * more frequently so styling happens quickly.
 */
const FRAME_CHECK_INTERVAL = 50;

/*
 * Maximum time to wait for VS Code to finish creating
 * the active-frame.
 */
const FRAME_WAIT_TIMEOUT = 5000;

/*
 * ------------------------------------------------------------
 * WEBVIEW CSS
 * ------------------------------------------------------------
 *
 * This is intentionally generic.
 *
 * Anything inside the VS Code webview's active-frame can
 * eventually be styled here.
 *
 * The red/lime video rule is ONLY a temporary test to prove
 * that CSS injection is working.
 *
 * Replace this CSS with your actual webview styling later.
 * ------------------------------------------------------------
 */

const WEBVIEW_CSS = `
  video {
    border: 5px solid lime !important;
  }
`;

/*
 * ------------------------------------------------------------
 * State
 * ------------------------------------------------------------
 */

let nextCommandId = 1;

let currentWebviewId = null;

let socket = null;

/*
 * ------------------------------------------------------------
 * Get Chrome / VS Code debugging targets
 * ------------------------------------------------------------
 */

function getTargets() {
  return new Promise((resolve, reject) => {
    const request = http.get(`http://127.0.0.1:${DEBUG_PORT}/json`, res => {
      let data = '';

      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (error) {
          reject(error);
        }
      });
    });

    request.on('error', reject);
  });
}

/*
 * ------------------------------------------------------------
 * Find a VS Code webview
 * ------------------------------------------------------------
 */

async function findWebview() {
  const targets = await getTargets();

  return targets.find(
    target =>
      target.type === 'iframe' && target.url.startsWith('vscode-webview://')
  );
}

/*
 * ------------------------------------------------------------
 * Send a CDP command
 * ------------------------------------------------------------
 */

function sendCommand(socket, method, params = {}) {
  const id = nextCommandId++;

  return new Promise((resolve, reject) => {
    const message = JSON.stringify({
      id,
      method,
      params
    });

    const handleMessage = event => {
      let response;

      try {
        response = JSON.parse(event.data);
      } catch {
        return;
      }

      if (response.id !== id) {
        return;
      }

      socket.removeEventListener('message', handleMessage);

      if (response.error) {
        reject(response.error);
      } else {
        resolve(response.result);
      }
    };

    socket.addEventListener('message', handleMessage);

    socket.send(message);
  });
}

/*
 * ------------------------------------------------------------
 * Close current CDP connection
 * ------------------------------------------------------------
 */

async function closeConnection() {
  if (socket) {
    try {
      socket.close();
    } catch {
      // Socket may already be closed.
    }

    socket = null;
  }

  currentWebviewId = null;
}

/*
 * ------------------------------------------------------------
 * Connect to the VS Code webview
 * ------------------------------------------------------------
 */

async function connectToWebview(webview) {
  console.log('VS Code webview appeared.');

  const newSocket = new WebSocket(webview.webSocketDebuggerUrl);

  await new Promise((resolve, reject) => {
    const handleOpen = () => {
      newSocket.removeEventListener('open', handleOpen);

      newSocket.removeEventListener('error', handleError);

      resolve();
    };

    const handleError = error => {
      newSocket.removeEventListener('open', handleOpen);

      newSocket.removeEventListener('error', handleError);

      reject(error);
    };

    newSocket.addEventListener('open', handleOpen);

    newSocket.addEventListener('error', handleError);
  });

  socket = newSocket;

  console.log('Connected to CDP.');
}

/*
 * ------------------------------------------------------------
 * Find active-frame
 * ------------------------------------------------------------
 */

async function findActiveFrame() {
  const result = await sendCommand(socket, 'Page.getFrameTree');

  const frameTree = result.frameTree;

  return frameTree.childFrames?.find(
    frame => frame.frame.name === 'active-frame'
  );
}

/*
 * ------------------------------------------------------------
 * Wait for active-frame
 * ------------------------------------------------------------
 */

async function waitForActiveFrame() {
  const startTime = Date.now();

  while (Date.now() - startTime < FRAME_WAIT_TIMEOUT) {
    const activeFrame = await findActiveFrame();

    if (activeFrame) {
      return activeFrame;
    }

    await new Promise(resolve => setTimeout(resolve, FRAME_CHECK_INTERVAL));
  }

  return null;
}

/*
 * ------------------------------------------------------------
 * Inject CSS into active-frame
 * ------------------------------------------------------------
 */

async function injectWebviewStyles(contextId) {
  const result = await sendCommand(socket, 'Runtime.evaluate', {
    expression: `
        (() => {
          const STYLE_ID = 'vscode-webview-custom-style';

          let style =
            document.getElementById(STYLE_ID);

          if (!style) {
            style = document.createElement('style');

            style.id = STYLE_ID;

            document.head.appendChild(style);
          }

          style.textContent =
            ${JSON.stringify(WEBVIEW_CSS)};

          return 'WEBVIEW STYLES INJECTED';
        })()
      `,

    contextId,

    returnByValue: true
  });

  console.log(result.result?.value ?? 'Webview styles injected.');
}

/*
 * ------------------------------------------------------------
 * Prepare the webview for styling
 * ------------------------------------------------------------
 */

async function prepareWebview(webview) {
  await connectToWebview(webview);

  const activeFrame = await waitForActiveFrame();

  if (!activeFrame) {
    console.log('active-frame did not appear.');

    return false;
  }

  const activeFrameId = activeFrame.frame.id;

  console.log(`Found active-frame: ${activeFrameId}`);

  /*
   * Create an isolated JavaScript world
   * inside the active-frame.
   */

  const world = await sendCommand(socket, 'Page.createIsolatedWorld', {
    frameId: activeFrameId,

    worldName: 'VSCodeWebviewStyler',

    grantUniveralAccess: true
  });

  const contextId = world.executionContextId;

  console.log(`Webview styling context ready: ${contextId}`);

  /*
   * Inject the actual CSS.
   */

  await injectWebviewStyles(contextId);

  return true;
}

/*
 * ------------------------------------------------------------
 * Check for webview changes
 * ------------------------------------------------------------
 */

async function checkWebview() {
  try {
    const webview = await findWebview();

    /*
     * No webview currently exists.
     */

    if (!webview) {
      if (currentWebviewId !== null) {
        console.log('VS Code webview disappeared.');

        await closeConnection();
      }

      return;
    }

    /*
     * Same webview.
     *
     * Nothing needs to happen.
     */

    if (currentWebviewId === webview.id) {
      return;
    }

    /*
     * A new webview appeared.
     */

    await closeConnection();

    currentWebviewId = webview.id;

    try {
      const ready = await prepareWebview(webview);

      if (!ready) {
        /*
         * The webview exists but its
         * active-frame did not appear.
         *
         * Keep watching it rather than
         * repeatedly creating connections.
         */

        return;
      }
    } catch (error) {
      console.error('Failed to prepare VS Code webview:', error.message);

      await closeConnection();
    }
  } catch (error) {
    console.error('Webview check failed:', error.message);
  }
}

/*
 * ------------------------------------------------------------
 * Main watcher
 * ------------------------------------------------------------
 */

async function main() {
  console.log('VS Code webview injector started.');

  console.log(`Normal check interval: ${CHECK_INTERVAL} ms.`);

  /*
   * Use a loop instead of setInterval().
   *
   * This guarantees that another check cannot
   * start while the previous asynchronous check
   * is still running.
   */

  while (true) {
    await checkWebview();

    await new Promise(resolve => setTimeout(resolve, CHECK_INTERVAL));
  }
}

main().catch(console.error);
