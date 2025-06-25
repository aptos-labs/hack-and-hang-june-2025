if (!self.define) {
  let e,
    s = {};
  const a = (a, n) => (
    (a = new URL(a + ".js", n).href),
    s[a] ||
      new Promise((s) => {
        if ("document" in self) {
          const e = document.createElement("script");
          (e.src = a), (e.onload = s), document.head.appendChild(e);
        } else (e = a), importScripts(a), s();
      }).then(() => {
        let e = s[a];
        if (!e) throw new Error(`Module ${a} didn’t register its module`);
        return e;
      })
  );
  self.define = (n, i) => {
    const t = e || ("document" in self ? document.currentScript.src : "") || location.href;
    if (s[t]) return;
    let c = {};
    const r = (e) => a(e, t),
      o = { module: { uri: t }, exports: c, require: r };
    s[t] = Promise.all(n.map((e) => o[e] || r(e))).then((e) => (i(...e), c));
  };
}
define(["./workbox-3c9d0171"], function (e) {
  "use strict";
  importScripts(),
    self.skipWaiting(),
    e.clientsClaim(),
    e.precacheAndRoute(
      [
        { url: "/_next/static/chunks/10-2f1a368647f90e2f.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/2267893a-9fa9564dcac2756a.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/265-8401f7af8516306b.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/510-89ee8e2500efca0a.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/640.4da2627e460663ef.js", revision: "4da2627e460663ef" },
        { url: "/_next/static/chunks/782-c6517c5837842cb9.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/app/_not-found/page-65bd21e1b7c6db12.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/app/layout-dd78460ed57d0cfb.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/app/page-76505af69250915b.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/b145b63a-aea33fdc1d2d030c.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/framework-6e06c675866dc992.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/main-app-015dc9581d6b09f7.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/main-d549b6d8041a1d88.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/pages/_app-3fcac1a2c632f1ef.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/pages/_error-d3fe151bf402c134.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/chunks/polyfills-42372ed130431b0a.js", revision: "846118c33b2c0e922d7b3a7676f81f6f" },
        { url: "/_next/static/chunks/webpack-47ed2e71e87658e2.js", revision: "gr2KakG4bZLG9qsLpTMIv" },
        { url: "/_next/static/css/62304d8361ed8b5f.css", revision: "62304d8361ed8b5f" },
        { url: "/_next/static/gr2KakG4bZLG9qsLpTMIv/_buildManifest.js", revision: "85aecd8a55db42fc901f52386fd2a680" },
        { url: "/_next/static/gr2KakG4bZLG9qsLpTMIv/_ssgManifest.js", revision: "b6652df95db52feb4daf4eca35380933" },
        { url: "/aptos.png", revision: "a98d27fd2ad859671bd172999f95b47c" },
        { url: "/favicon.ico", revision: "ca3a9bcb89b0f4492cc2167efabd821b" },
        { url: "/favicon.png", revision: "ca3a9bcb89b0f4492cc2167efabd821b" },
        { url: "/favicon.svg", revision: "9a97cb7a2f9d299c52a67503caea110e" },
        { url: "/icons/icon-192x192.png", revision: "0350c81b3b6805c7d7f45bfadf258af2" },
        { url: "/icons/icon-384x384.png", revision: "89b0d4e4292ee962f3b2d7f5d5d7f54f" },
        { url: "/icons/icon-512x512.png", revision: "c3dfddb9ec42df70fa0a712e1f4433ba" },
      ],
      { ignoreURLParametersMatching: [/^utm_/, /^fbclid$/] },
    ),
    e.cleanupOutdatedCaches(),
    e.registerRoute(
      "/",
      new e.NetworkFirst({
        cacheName: "start-url",
        plugins: [
          {
            cacheWillUpdate: async ({ response: e }) =>
              e && "opaqueredirect" === e.type
                ? new Response(e.body, { status: 200, statusText: "OK", headers: e.headers })
                : e,
          },
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /^https:\/\/fonts\.(?:gstatic)\.com\/.*/i,
      new e.CacheFirst({
        cacheName: "google-fonts-webfonts",
        plugins: [new e.ExpirationPlugin({ maxEntries: 4, maxAgeSeconds: 31536e3 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /^https:\/\/fonts\.(?:googleapis)\.com\/.*/i,
      new e.StaleWhileRevalidate({
        cacheName: "google-fonts-stylesheets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 4, maxAgeSeconds: 604800 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:eot|otf|ttc|ttf|woff|woff2|font.css)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-font-assets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 4, maxAgeSeconds: 604800 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:jpg|jpeg|gif|png|svg|ico|webp)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-image-assets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 64, maxAgeSeconds: 2592e3 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\/_next\/static.+\.js$/i,
      new e.CacheFirst({
        cacheName: "next-static-js-assets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 64, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\/_next\/image\?url=.+$/i,
      new e.StaleWhileRevalidate({
        cacheName: "next-image",
        plugins: [new e.ExpirationPlugin({ maxEntries: 64, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:mp3|wav|ogg)$/i,
      new e.CacheFirst({
        cacheName: "static-audio-assets",
        plugins: [new e.RangeRequestsPlugin(), new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:mp4|webm)$/i,
      new e.CacheFirst({
        cacheName: "static-video-assets",
        plugins: [new e.RangeRequestsPlugin(), new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:js)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-js-assets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 48, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:css|less)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-style-assets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\/_next\/data\/.+\/.+\.json$/i,
      new e.StaleWhileRevalidate({
        cacheName: "next-data",
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:json|xml|csv)$/i,
      new e.NetworkFirst({
        cacheName: "static-data-assets",
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ sameOrigin: e, url: { pathname: s } }) =>
        !(!e || s.startsWith("/api/auth/callback") || !s.startsWith("/api/")),
      new e.NetworkFirst({
        cacheName: "apis",
        networkTimeoutSeconds: 10,
        plugins: [new e.ExpirationPlugin({ maxEntries: 16, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ request: e, url: { pathname: s }, sameOrigin: a }) =>
        "1" === e.headers.get("RSC") && "1" === e.headers.get("Next-Router-Prefetch") && a && !s.startsWith("/api/"),
      new e.NetworkFirst({
        cacheName: "pages-rsc-prefetch",
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ request: e, url: { pathname: s }, sameOrigin: a }) =>
        "1" === e.headers.get("RSC") && a && !s.startsWith("/api/"),
      new e.NetworkFirst({
        cacheName: "pages-rsc",
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ url: { pathname: e }, sameOrigin: s }) => s && !e.startsWith("/api/"),
      new e.NetworkFirst({
        cacheName: "pages",
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 })],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ sameOrigin: e }) => !e,
      new e.NetworkFirst({
        cacheName: "cross-origin",
        networkTimeoutSeconds: 10,
        plugins: [new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 3600 })],
      }),
      "GET",
    );
});
