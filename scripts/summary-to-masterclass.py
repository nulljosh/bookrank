#!/usr/bin/env python3
"""Convert uprighty markdown summaries to lexly masterclass JSON."""

import json
import re
from pathlib import Path

UPRIGHTY_SUMMARIES = Path.home() / "Documents/Code/uprighty/summaries"
LEXLY_OUTPUT = Path.home() / "Documents/Code/lexly/content/notes"

def slugify(text):
    """URL-safe slug."""
    slug = text.lower().strip()
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[-\s]+', '-', slug)
    return slug.strip('-')

def extract_unit_tag(title):
    """Extract 'Chapter N' or 'Introduction' from title."""
    match = re.match(r'(Chapter \d+|Introduction)', title, re.IGNORECASE)
    return match.group(1) if match else "Section"

def convert_summary(filepath):
    """Convert one uprighty summary to masterclass JSON."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Extract book name (first # line)
    book_name = filepath.stem.replace('-', ' ').title()
    for line in lines:
        if line.startswith('# '):
            book_name = line[2:].strip()
            break

    # Find all chapter positions (# Chapter or # Introduction)
    chapters = []
    for i, line in enumerate(lines):
        if line.startswith('# ') and i > 0:  # skip title at i=0
            chapters.append(i)

    sections = []
    for ch_idx, ch_start in enumerate(chapters):
        ch_end = chapters[ch_idx + 1] if ch_idx + 1 < len(chapters) else len(lines)

        title = lines[ch_start][2:].strip()
        section = {
            'id': slugify(title),
            'title': title,
            'unitTag': extract_unit_tag(title),
            'blocks': []
        }

        # Parse chapter blocks (lines between chapters)
        parse_blocks(lines[ch_start + 1:ch_end], section)

        if section['blocks']:
            sections.append(section)

    return {
        'id': filepath.stem + '_masterclass',
        'name': book_name + ' Masterclass',
        'sections': sections
    }

def parse_blocks(lines, section):
    """Parse blocks within a chapter."""
    i = 0
    while i < len(lines):
        line = lines[i]

        # Skip empty and separator lines
        if not line.strip() or line.strip() == '---':
            i += 1
            continue

        # Subheading → heading block
        if line.startswith('## '):
            section['blocks'].append({
                'type': 'heading',
                'text': line[3:].strip()
            })
            i += 1
            continue

        # Bullet list (check for flashcard pattern **term**: answer)
        if line.startswith('- '):
            cards = []
            items = []

            while i < len(lines) and lines[i].startswith('- '):
                item = lines[i][2:].strip()
                match = re.match(r'\*\*([^*]+)\*\*:\s*(.*)', item)
                if match:
                    cards.append({'q': match.group(1), 'a': match.group(2)})
                else:
                    items.append(item)
                i += 1

            # Add blocks (cards take precedence over items)
            if cards:
                section['blocks'].append({'type': 'flashcards', 'cards': cards})
            if items:
                section['blocks'].append({'type': 'list', 'items': items})
            continue

        # Paragraph (consecutive non-empty, non-special lines)
        para = []
        while i < len(lines):
            l = lines[i].rstrip()
            if not l.strip() or l.startswith('#') or l.startswith('- ') or l.strip() == '---':
                break
            para.append(l)
            i += 1

        if para:
            text = '\n'.join(para).strip()
            if text:
                section['blocks'].append({'type': 'p', 'text': text})

def main():
    """Convert all summaries."""
    LEXLY_OUTPUT.mkdir(parents=True, exist_ok=True)

    summaries = sorted(UPRIGHTY_SUMMARIES.glob('*.md'))
    if not summaries:
        print(f"No summaries found in {UPRIGHTY_SUMMARIES}")
        return

    print(f"Converting {len(summaries)} summaries...", flush=True)

    for i, summary_file in enumerate(summaries):
        try:
            print(f"  [{i+1}/{len(summaries)}] {summary_file.stem}...", flush=True)
            masterclass = convert_summary(summary_file)
            output_file = LEXLY_OUTPUT / f"{summary_file.stem}-masterclass.json"

            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(masterclass, f, indent=2, ensure_ascii=False)

            section_count = len(masterclass['sections'])
            print(f"       ✓ {section_count} sections", flush=True)
        except Exception as e:
            print(f"       ✗ {e}", flush=True)

    print(f"Done.", flush=True)

if __name__ == '__main__':
    main()
