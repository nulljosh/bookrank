# Kernel brand kit and design system

a summary that ends on a seed: the kernel of a book

## The mark
Three lines of a page, the last one short, ending on a seed: a summary that keeps the kernel of a book. The seed is the same outline as the full stop in Kernel Sans, so the icon, the wordmark ("Kernel.") and every sentence end on one mark.

- `../Kernel.icon` is the source of truth (Icon Composer). Light and dark fills are set in it.
- `../icon.svg` is the flat copy for READMEs (shown at 80 px). `icon-1024.png` is the App Store icon, no alpha.
- `mark.svg` is the glyph alone in `currentColor` for your own background.
- Clear space equal to the width of the glyph's thickest stroke. Smallest size 16 px.

## Colour
| Role | Value |
|---|---|
| Accent, actions and links on light | `#a56200` (4.9:1 on white) |
| Accent on dark | `#f5b83d` |
| Icon gradient | `#f5b83d` to `#c97a00` |
| Text | `#1d1d1f` light, `#f5f5f7` dark |
| Background | `#ffffff` light, `#000000` dark |
| Surface | `#f5f5f7` light, `#1c1c1e` dark |

Kernel gold is for actions, links and the icon, one gold control per screen. Never brown, beige, purple or teal.

## Type
**Kernel Sans**, our own face (Joshua asked for one, 2026-10-28): Geist (OFL) renamed, proportional letters and figures, sitting between San Francisco and Helvetica, with the full stop redrawn as the seed. `scripts/gen_font.py` builds it into `fonts/` (OTF for the apps, WOFF2 for the web) and `--check` proves the name, license, proportional spacing and the seed. Fallback stack: `-apple-system, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif`. Scale 34/41 bold, 22/28, 17/24, 15/20, 13/18. Headlines tight (-0.03em), body at 0.

## Space and shape
- Space on the 8 point grid: 4, 8, 12, 16, 24, 32, 48. Side margin 20. Reading column 680.
- Radii: cards 28, grouped lists 20, controls fully round, icon 22 percent.
- Controls are 48 points tall capsules, one height in a row. Focus is a 4 point ring at 30 percent accent.
- Motion is 0.2 s ease and honours reduced motion.

`tokens.css` holds the app's accent. Everything else comes from the shared token file.
