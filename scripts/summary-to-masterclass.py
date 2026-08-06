#!/usr/bin/env python3
"""
Convert uprighty markdown summaries to lexly masterclass JSON.

Usage:
  python3 summary-to-masterclass.py

Outputs 15 masterclass JSONs to ~/Documents/Code/lexly/content/notes/
"""

import os
import json
import re
import sys
from pathlib import Path

UPRIGHTY_SUMMARIES = Path.home() / "Documents/Code/uprighty/summaries"
LEXLY_OUTPUT = Path.home() / "Documents/Code/lexly/content/notes"

def slugify(text):
    """Convert text to URL-safe slug."""
    slug = text.lower().strip()
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[-\s]+', '-', slug)
    return slug.strip('-')

def extract_unit_tag(title):
    """Extract 'Chapter N' or 'Introduction' from title."""
    match = re.match(r'(Chapter \d+|Introduction)', title, re.IGNORECASE)
    if match:
        return match.group(1)
    return "Section"

def convert_summary(filepath):
    """Convert one uprighty summary to masterclass JSON."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract book name from # Title line
    lines = content.split('\n')
    book_name = filepath.stem.replace('-', ' ').title()

    for line in lines[:5]:
        if line.startswith('# '):
            book_name = line[2:].strip()
            break

    sections = []
    current_section = None
    i = 0

    while i < len(lines):
        line = lines[i]

        # Chapter heading (but not the first # which is the title)
        if line.startswith('# ') and i > 0 and current_section is None:
            i += 1
            continue

        if line.startswith('# ') and i > 0:
            if current_section and current_section.get('blocks'):
                sections.append(current_section)

            title = line[2:].strip()
            current_section = {
                'id': slugify(title),
                'title': title,
                'unitTag': extract_unit_tag(title),
                'blocks': []
            }
            i += 1
            continue

        if current_section is None:
            i += 1
            continue

        # Empty line or separator
        if not line.strip() or line.strip() == '---':
            i += 1
            continue

        # Subheading
        if line.startswith('## '):
            current_section['blocks'].append({
                'type': 'heading',
                'text': line[3:].strip()
            })
            i += 1
            continue

        # Bullet list or flashcards
        if line.startswith('- '):
            items = []
            cards = []
            is_flashcard = False

            while i < len(lines) and lines[i].startswith('- '):
                item_line = lines[i][2:].strip()

                # Check if it's a flashcard (**term**: answer)
                fc_match = re.match(r'\*\*([^*]+)\*\*:\s*(.*)', item_line)
                if fc_match:
                    is_flashcard = True
                    cards.append({'q': fc_match.group(1), 'a': fc_match.group(2)})
                else:
                    items.append(item_line)

                i += 1

            if cards and not items:
                current_section['blocks'].append({'type': 'flashcards', 'cards': cards})
            elif items:
                current_section['blocks'].append({'type': 'list', 'items': items})
            continue

        # Paragraph
        para_lines = []
        while i < len(lines):
            l = lines[i]
            if not l.strip() or l.startswith('#') or l.startswith('- ') or l.strip() == '---':
                break
            para_lines.append(l.rstrip())
            i += 1

        if para_lines:
            text = '\n'.join(para_lines).strip()
            if text:
                current_section['blocks'].append({'type': 'p', 'text': text})

    if current_section and current_section.get('blocks'):
        sections.append(current_section)

    masterclass = {
        'id': filepath.stem + '_masterclass',
        'name': book_name + ' Masterclass',
        'sections': sections
    }

    return masterclass

def main():
    """Convert all summaries."""
    LEXLY_OUTPUT.mkdir(parents=True, exist_ok=True)

    summaries = sorted(UPRIGHTY_SUMMARIES.glob('*.md'))
    if not summaries:
        print(f"No summaries found in {UPRIGHTY_SUMMARIES}")
        sys.exit(1)

    print(f"Converting {len(summaries)} summaries...")

    for summary_file in summaries:
        try:
            masterclass = convert_summary(summary_file)
            output_file = LEXLY_OUTPUT / f"{summary_file.stem}-masterclass.json"

            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(masterclass, f, indent=2, ensure_ascii=False)

            print(f"  ✓ {summary_file.stem}")
        except Exception as e:
            print(f"  ✗ {summary_file.stem}: {e}", file=sys.stderr)
            sys.exit(1)

    print(f"\nDone. {len(summaries)} masterclass JSONs generated.")

if __name__ == '__main__':
    main()
