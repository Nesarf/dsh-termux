// A one-purpose HTTP bridge for Android browsers.
//
// dsh web prints a token URL on startup. Handing that URL straight to
// termux-open-url / am loses the query string in some environments, so the
// browser lands on ?token=... without the token and only shows
// "authentication required". A 302 Location is built on the server side and
// keeps the query intact, so the browser is opened on a bare localhost
// address and follows the redirect.
//
// Listens on 127.0.0.1:3081 and redirects to the newest token URL found in
// the dsh web log. Without a token it answers 503 so the page says what is
// missing instead of a blank failure.

const http = require('node:http');
const fs = require('node:fs');

const LOG = process.env.DSH_WEB_LOG || '/data/data/com.termux/files/home/dsh-web.log';
const PORT = Number(process.env.DSH_OPEN_PORT || 3081);
const TARGET = process.env.DSH_WEB_BASE || 'http://127.0.0.1:3080';
const TOKEN_RE = /http:\/\/127\.0\.0\.1:3080\/\?token=[^\s]+/;

http
  .createServer((req, res) => {
    let url = '';
    try {
      const m = fs.readFileSync(LOG, 'utf8').match(TOKEN_RE);
      if (m) url = m[0];
    } catch {
      // log missing or unreadable: fall through to the 503 branch
    }
    if (url) {
      res.writeHead(302, { Location: url });
      res.end();
    } else {
      res.writeHead(503, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('dsh web is not ready yet; see ' + LOG + '\n');
    }
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log('dsh open bridge: http://127.0.0.1:' + PORT + '/ -> ' + TARGET);
  });
