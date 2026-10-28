// AppTransaction check against a throwaway chain built like Apple's (P-384 root and intermediate, P-256
// leaf, the App Store receipt markers), pinned by its own fingerprint instead of Apple Root CA - G3.
import { appProof, APPLE_ROOT_G3 } from './functions/api/apple.js';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const fx = n => readFileSync(new URL(`./test/fixtures/apple/${n}`, import.meta.url), 'utf8').trim();
const [leaf, mid, root] = ['leaf.b64', 'mid.b64', 'root.b64'].map(fx);
const der = s => Uint8Array.from(atob(s), c => c.charCodeAt(0));
const hex = b => [...new Uint8Array(b)].map(x => x.toString(16).padStart(2, '0')).join('');
const pinned = hex(await crypto.subtle.digest('SHA-256', der(root)));
const pem = fx('leaf.p8').replace(/-----[^-]+-----|\s/g, '');
const key = await crypto.subtle.importKey('pkcs8', der(pem), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
const u = o => Buffer.from(typeof o === 'string' ? o : JSON.stringify(o)).toString('base64url');
async function jws(payload, x5c = [leaf, mid, root]) {
  const h = u({ alg: 'ES256', x5c }), p = u(payload);
  const s = Buffer.from(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(`${h}.${p}`))).toString('base64url');
  return `${h}.${p}.${s}`;
}
const opts = { bundleId: 'com.heyitsmejosh.spine', root: pinned };
const good = await jws({ bundleId: 'com.heyitsmejosh.spine', receiptType: 'Production' });
assert.equal((await appProof(good, opts))?.receiptType, 'Production');               // a real copy
assert.equal(await appProof(good, { ...opts, bundleId: 'com.other' }), null);        // another app's proof
assert.equal(await appProof(good, { ...opts, root: APPLE_ROOT_G3 }), null);          // not Apple's root
assert.equal(await appProof(good.slice(0, -4) + 'AAAA', opts), null);                // signature tampered
const [h, , s] = good.split('.');
assert.equal(await appProof(`${h}.${u({ bundleId: 'com.heyitsmejosh.spine', x: 1 })}.${s}`, opts), null); // payload swapped
assert.equal(await appProof(await jws({ bundleId: 'com.heyitsmejosh.spine' }, [mid, mid, root]), opts), null); // leaf marker missing
assert.equal(await appProof(good, { ...opts, now: Date.UTC(2040, 0, 1) }), null);    // expired chain
assert.equal(await appProof('junk', opts), null);
assert.equal(await appProof('', opts), null);
console.log('apple ok');
