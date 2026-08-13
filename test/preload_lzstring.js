// Tests exercise lib/lzstringjs.ml, which looks up a bare global `LZString`
// (via Js.Unsafe.pure_js_expr), exactly like the browser <script> tag does.
// lz-string.js only exposes itself through `module.exports` under Node's
// CommonJS wrapper, so we lift it onto the global object ourselves before
// the compiled test runs.
global.LZString = require("../statics/scripts/lz-string.js");
