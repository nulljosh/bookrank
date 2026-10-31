import assert from 'node:assert/strict';
import { takeaways, keyIdeas, recap, quiz } from './study.js';
const book = `# One\n\nHabits are the **compound interest** of self-improvement, small changes adding up over the years.\n\n## Key takeaways\n- Small habits compound into remarkable results over time.\n- Focus on systems rather than goals for lasting change.\n\n# Two\n\nThe **habit loop** has four parts: cue, craving, response and reward, and each can be designed.\n\nEnvironment shapes behavior more than motivation does, so design the space around you.\n\n# Three\n\nMake good habits obvious with an **implementation intention** that names a time and place for the action.`;
assert.deepEqual(takeaways(book.split('# Two')[0]), ['Small habits compound into remarkable results over time.', 'Focus on systems rather than goals for lasting change.']);
const ideas = keyIdeas(book);
assert.equal(ideas[0], 'Small habits compound into remarkable results over time.');      // a takeaway first
assert.ok(ideas[1].startsWith('The habit loop has four parts'));                            // else the opening sentence, bold stripped
assert.equal(ideas.length, 3);
assert.deepEqual(recap('# Two\n\nThe habit loop has four parts, and each one can be designed on purpose.\n\nEnvironment shapes behavior more than motivation does. Design the space around you and the habit follows.'), ['Environment shapes behavior more than motivation does.', 'Design the space around you and the habit follows.']);
const qs = quiz(book, book);
assert.equal(qs.length, 3);
assert.ok(qs[0].question.includes('_____') && !qs[0].question.includes('compound interest'));
assert.ok(qs.every(q => q.choices.length === 3 && q.choices.includes(q.answer)));
assert.deepEqual(quiz(book, book), qs);                                                      // the same quiz every time
assert.deepEqual(quiz('# One\n\nNo bold terms here at all, just plain prose that is long enough.'), []);
console.log('study ok');
const labels = '# L\n\n- **Practical application**: readers learn not just what to do but also why behind the advice given here.\n\n**Good Fengshui** is designed to introduce readers to practical principles. The core philosophy emphasizes:\n\nA **flying star** chart maps how energy moves through a home across the years and the seasons alike.';
assert.deepEqual(quiz(labels, labels + '\n**One** **Two**').map(q => q.answer), ['Practical application', 'flying star']); // no question that stops on a colon
assert.deepEqual(recap('# C\n\nSome text first that runs long enough to count here.\n\n*(Covered: Part 1 and Part 2 of the book so far.)*'), ['(Covered: Part 1 and Part 2 of the book so far.)']); // no stray italics marks
