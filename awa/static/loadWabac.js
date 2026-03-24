// NLA tweaks to reset state
const WABAC_VERSION_KEY = "wabac_version";
const WABAC_VERSION = "2026-03-24-1";

async function resetWabacStateIfNeeded(swScope) {
  if (localStorage.getItem(WABAC_VERSION_KEY) === WABAC_VERSION) {
    return;
  }

  try {
    await new Promise((resolve) => {
      const req = indexedDB.deleteDatabase("collDB");
      req.onsuccess = req.onerror = req.onblocked = () => resolve();
    });
  } catch (e) {}

  try {
    const reg = await navigator.serviceWorker.getRegistration(swScope);
    if (reg) {
      await reg.unregister();
    }
  } catch (e) {}

  localStorage.setItem(WABAC_VERSION_KEY, WABAC_VERSION);
}
// End NLA tweaks

class WabacReplay
{
  constructor(prefix, url, ts, staticPrefix, coll, swScopePrefix, injectScripts) {
    this.prefix = prefix;
    this.url = url;
    this.ts = ts;
    this.staticPrefix = staticPrefix;
    this.collName = coll;
    this.isRoot = coll === "$root";
    this.swScope = swScopePrefix;
    this.injectScripts = injectScripts;
    this.adblockUrl = undefined;

    this.queryParams = {"replayPrefix": ""};
    if (this.isRoot) {
      this.queryParams["root"] = "$root";
    }
  }

  async init() {
    // NLA tweaks
    await resetWabacStateIfNeeded(this.swScope);
    // End NLA tweaks

    const scope = this.swScope + "/";

    await navigator.serviceWorker.register(
      `${this.staticPrefix}/sw.js?` + new URLSearchParams(this.queryParams).toString(),
      { scope },
    );

    let initedResolve = null;

    const inited = new Promise((resolve) => initedResolve = resolve);

    navigator.serviceWorker.addEventListener("message", (event) => {
      if (event.data.msg_type === "collAdded") {
        // the replay is ready to be loaded when this message is received
        initedResolve();
      }
    });

    const proxyPrefix = "";

    const msg = {
      msg_type: "addColl",
      name: this.collName,
      type: "live",
      root: this.isRoot,
      file: {"sourceUrl": `proxy:${proxyPrefix}`},
      skipExisting: true,
      extraConfig: {
        prefix: proxyPrefix,
        isLive: false,
        baseUrl: this.prefix,
        baseUrlAppendReplay: true,
        noPostToGet: false,
        archivePrefix: this.prefix,
        archiveMod: "ir_",
        adblockUrl: this.adblockUrl,
        noPostToGet: true,
        injectScripts: this.injectScripts.map(src => "../" + src),
      },
    };

    if (!navigator.serviceWorker.controller) {
      navigator.serviceWorker.addEventListener("controllerchange", () => {
        navigator.serviceWorker.controller.postMessage(msg);
      });
    } else {
      navigator.serviceWorker.controller.postMessage(msg);
    }

    window.addEventListener("message", event => {
      let data = event.data;
      if (window.WBBanner) {
        window.WBBanner.onMessage(event);
      }
      if (data.wb_type === "load" || data.wb_type === "replace-url") {
        history.replaceState({}, data.title, this.prefix + data.ts + '/' + data.url);
      }
    });

    if (inited) {
      await inited;
    }

    this.load_url(this.url, this.ts);
  }

  // called by the Vue banner when the timeline is clicked
  load_url(url, ts) {
    const iframe = document.querySelector('#replay_iframe');
    iframe.src = `${this.prefix}${ts}mp_/${url}`;
  }
}
