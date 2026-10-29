import assert from 'node:assert/strict';
import { topLine } from './reading.js';
const r = (top, h) => ({ top, bottom: top + h });
assert.equal(topLine([r(-38, 76), r(38, 76), r(114, 170)], 844), 1);   // the half-hidden first line does not count
assert.equal(topLine([r(-900, 1600), r(700, 80)], 844), 0);            // a tall paragraph still filling the top third does
assert.equal(topLine([r(-900, 1000), r(100, 80)], 844), 1);
assert.equal(topLine([r(-200, 100)], 844), -1);                        // nothing on screen
console.log('reading ok');
