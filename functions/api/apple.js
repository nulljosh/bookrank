// Proof that a request comes from a bought copy of the app: StoreKit's AppTransaction, a JWS that
// Apple signs. The apps send AppTransaction.shared's jwsRepresentation as X-Kernel-Receipt.
// Checked here without any Apple API call: the x5c chain must end at Apple Root CA - G3 (pinned by
// fingerprint), each certificate must be signed by the next and in date, the leaf and intermediate
// must carry Apple's App Store receipt markers, the JWS must verify with the leaf key, and the
// payload must name our bundle.
// ponytail: a buyer could copy their own JWS onto the web; they paid, so that is accepted.

export const APPLE_ROOT_G3 = "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179";
const LEAF_OID = hex("060a2a864886f76364060b01");    // 1.2.840.113635.100.6.11.1
const MID_OID = hex("060a2a864886f76364060201");     // 1.2.840.113635.100.6.2.1
const P256 = hex("06082a8648ce3d030107"), P384 = hex("06052b81040022");
const SHA384_SIG = hex("06082a8648ce3d040303");

export async function appProof(jws, { bundleId, root = APPLE_ROOT_G3, now = Date.now() } = {}) {
  try {
    const [h, p, s] = String(jws).split(".");
    const head = JSON.parse(text(b64u(h)));
    if (head.alg !== "ES256" || !Array.isArray(head.x5c) || head.x5c.length !== 3) return null;
    const certs = head.x5c.map(c => cert(b64(c)));
    if (await sha256hex(certs[2].raw) !== root) return null;
    if (!has(certs[0].tbs, LEAF_OID) || !has(certs[1].tbs, MID_OID)) return null;
    for (let i = 0; i < 3; i++) {
      const c = certs[i], issuer = certs[Math.min(i + 1, 2)];
      if (now < c.from || now > c.to) return null;
      const key = await importKey(issuer.spki);
      const hash = has(c.sigAlg, SHA384_SIG) ? "SHA-384" : "SHA-256";
      if (!(await crypto.subtle.verify({ name: "ECDSA", hash }, key, raw(c.sig, key.size), c.tbs))) return null;
    }
    const leaf = await importKey(certs[0].spki);
    if (!(await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, leaf, b64u(s), new TextEncoder().encode(`${h}.${p}`)))) return null;
    const body = JSON.parse(text(b64u(p)));
    return body.bundleId === bundleId ? body : null;
  } catch { return null; }
}

// ---- just enough DER to read a certificate ----

function node(b, at) {
  let len = b[at + 1], start = at + 2;
  if (len & 0x80) { const n = len & 0x7f; len = 0; for (let i = 0; i < n; i++) len = len * 256 + b[start + i]; start += n; }
  return { tag: b[at], start, end: start + len, at };
}
function kids(b, n) {
  const out = [];
  for (let at = n.start; at < n.end;) { const k = node(b, at); out.push(k); at = k.end; }
  return out;
}
function cert(b) {
  const [tbsN, algN, sigN] = kids(b, node(b, 0));
  const t = kids(b, tbsN), o = t[0].tag === 0xa0 ? 1 : 0;   // optional [0] version
  const [nb, na] = kids(b, t[3 + o]);
  return {
    raw: b, tbs: b.slice(tbsN.at, tbsN.end), sigAlg: b.slice(algN.at, algN.end),
    sig: b.slice(sigN.start + 1, sigN.end),                     // BIT STRING, skip the unused-bits byte
    spki: b.slice(t[5 + o].at, t[5 + o].end),
    from: time(b.slice(nb.start, nb.end), nb.tag), to: time(b.slice(na.start, na.end), na.tag),
  };
}
function time(b, tag) {
  const s = text(b), y = tag === 0x17 ? (+s.slice(0, 2) < 50 ? 2000 : 1900) + +s.slice(0, 2) : +s.slice(0, 4), r = tag === 0x17 ? s.slice(2) : s.slice(4);
  return Date.UTC(y, +r.slice(0, 2) - 1, +r.slice(2, 4), +r.slice(4, 6), +r.slice(6, 8), +r.slice(8, 10));
}
async function importKey(spki) {
  const size = has(spki, P384) ? 48 : has(spki, P256) ? 32 : 0;
  if (!size) throw new Error("curve");
  const key = await crypto.subtle.importKey("spki", spki, { name: "ECDSA", namedCurve: size === 48 ? "P-384" : "P-256" }, false, ["verify"]);
  key.size = size;
  return key;
}
// X.509 signatures are DER SEQUENCE { r, s }; WebCrypto wants r || s at the curve's width.
function raw(der, size) {
  const [r, s] = kids(der, node(der, 0)).map(k => der.slice(k.start, k.end));
  const fit = i => { const v = i[0] === 0 ? i.slice(1) : i, o = new Uint8Array(size); o.set(v, size - v.length); return o; };
  const out = new Uint8Array(size * 2); out.set(fit(r)); out.set(fit(s), size);
  return out;
}

function has(b, needle) {
  outer: for (let i = 0; i <= b.length - needle.length; i++) { for (let j = 0; j < needle.length; j++) if (b[i + j] !== needle[j]) continue outer; return true; }
  return false;
}
function hex(s) { return Uint8Array.from(s.match(/../g), x => parseInt(x, 16)); }
function b64(s) { return Uint8Array.from(atob(s), c => c.charCodeAt(0)); }
function b64u(s) { return b64(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "=")); }
function text(b) { return new TextDecoder().decode(b); }
async function sha256hex(b) { return [...new Uint8Array(await crypto.subtle.digest("SHA-256", b))].map(x => x.toString(16).padStart(2, "0")).join(""); }
