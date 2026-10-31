import assert from 'node:assert/strict';
import { topicsOf, shelfTopics } from './topics.js';

assert.deepEqual(topicsOf('AI Investing for Dummies'), ['AI and tech', 'Money']);
assert.deepEqual(topicsOf('Calculus For Dummies'), ['Science and math']);
assert.deepEqual(topicsOf('Apple: The First 50 Years'), ['AI and tech', 'Lives and history']);
assert.deepEqual(topicsOf('Fiend'), []);
assert.deepEqual(topicsOf('Said Daily'), []);                       // "ai" only as a whole word
assert.deepEqual(shelfTopics(['How AI Thinks', 'AI in Business', 'Fiend', 'Calculus For Dummies']), ['AI and tech']);
console.log('topics ok');
