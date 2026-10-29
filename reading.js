// Reading without audio still saves your place: the first line that starts on screen (or a paragraph taller
// than the screen that still fills its top third), two seconds after you stop scrolling. Only past the first
// line, so opening a chapter never overwrites a place further in. Same rule as Speaker.seen in the apps.
export function topLine(rects, height) {
  return rects.findIndex(r => r.top >= 0 || r.bottom > height / 3);
}

export function trackReading(text, onPlace, wait = 2000) {
  let t;
  addEventListener('scroll', () => {
    clearTimeout(t);
    t = setTimeout(() => {
      if (!text.isConnected || !text.offsetParent) return;
      const i = topLine([...text.children].map(el => el.getBoundingClientRect()), innerHeight);
      if (i > 0) onPlace(i);
    }, wait);
  }, { capture: true, passive: true });
}
