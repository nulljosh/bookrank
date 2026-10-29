// node --test: the Goodreads export file becomes the three shelves, quotes, ISBN wrappers and dates handled.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { csv, parseExport } from './goodreads-export.js';

const file = '﻿Book Id,Title,Author,ISBN,ISBN13,My Rating,Number of Pages,Date Read,Exclusive Shelf\n' +
  '1,"Sapiens: A Brief History of Humankind",Yuval Noah Harari,"=""0062316095""","=""9780062316097""",4,443,2025/09/08,read\n' +
  '2,"Deep Work",Cal Newport,"","",0,296,,currently-reading\r\n' +
  '3,"The ""Quoted"" Book, Part 2",Someone,,,0,,,to-read\n';

test('csv keeps quoted commas, doubled quotes and newlines', () => {
  assert.deepEqual(csv('a,"b, c","d ""e"""\n"x\ny",z'), [['a', 'b, c', 'd "e"'], ['x\ny', 'z']]);
});

test('parseExport sorts books onto the three shelves', () => {
  const { reading, read, toRead } = parseExport(file);
  assert.deepEqual(read[0], { title: 'Sapiens: A Brief History of Humankind', author: 'Yuval Noah Harari', isbn: '9780062316097', rating: 4, pages: 443,
    cover: 'https://covers.openlibrary.org/b/isbn/9780062316097-M.jpg', readAt: '2025-09-08', url: 'https://www.goodreads.com/book/show/1' });
  assert.equal(reading[0].title, 'Deep Work'); assert.equal(reading[0].rating, null); assert.equal(reading[0].cover, null);
  assert.equal(toRead[0].title, 'The "Quoted" Book, Part 2');
  assert.throws(() => parseExport('a,b\n1,2'), /not a Goodreads export/);
});
