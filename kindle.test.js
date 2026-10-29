// node --test: My Clippings.txt becomes books with their highlights; notes, bookmarks and repeats drop out.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseClippings, kindleChapter } from './kindle.js';

const file = '﻿Deep Work (Cal Newport)\r\n- Your Highlight on page 12 | Location 180-182 | Added on Monday, March 3, 2025 10:00:00 AM\r\n\r\nClarity about what matters provides clarity about what does not.\r\n==========\r\n' +
  'Deep Work (Cal Newport)\n- Your Note on page 12 | Location 182 | Added on Monday, March 3, 2025 10:01:00 AM\n\nmy own note\n==========\n' +
  'Deep Work (Cal Newport)\n- Your Bookmark on page 40 | Location 600 | Added on Monday, March 3, 2025\n\n\n==========\n' +
  'Deep Work (Cal Newport)\n- Your Highlight on page 12 | Location 180-182 | Added on Monday, March 3, 2025 10:00:00 AM\n\nClarity about what matters provides clarity about what does not.\n==========\n' +
  'Sapiens: A Brief History of Humankind (Harari, Yuval Noah)\n- Your Highlight on Location 900-901 | Added on Friday, May 2, 2025\n\nHistory began when humans invented gods.\n==========\n';

test('parseClippings keeps highlights only, once each, per book', () => {
  assert.deepEqual(parseClippings(file), [
    { title: 'Deep Work', author: 'Cal Newport', lines: ['Clarity about what matters provides clarity about what does not.'] },
    { title: 'Sapiens: A Brief History of Humankind', author: 'Harari, Yuval Noah', lines: ['History began when humans invented gods.'] },
  ]);
});

test('kindleChapter adds only what the summary does not have', () => {
  assert.equal(kindleChapter('# A\n\n- old line', ['old line', 'new line']), '- new line');
  assert.equal(kindleChapter('old line', ['old line']), '');
});

test('parseReadwise reads the CSV export into books, and is null for other files', async () => {
  const { parseReadwise } = await import('./kindle.js');
  const file = 'Highlight,Book Title,Book Author,Amazon Book ID,Note\n"Small habits, compounded, win.",Atomic Habits,James Clear,,\n"You do not rise to your goals.\nYou fall to your systems.",Atomic Habits,James Clear,,\n';
  assert.deepEqual(parseReadwise(file), [{ title: 'Atomic Habits', author: 'James Clear', lines: ['Small habits, compounded, win.', 'You do not rise to your goals. You fall to your systems.'] }]);
  assert.equal(parseReadwise('Book Id,Title\n1,x'), null);
});
