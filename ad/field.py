"""Kernel 20, the wordless cut: field lines, chapter bars and the number 20, ending on the name.

The grammar of a wordless model teaser (diagrams, geometry and field lines built around one number, the name
only at the end), in Kernel's own palette, type and mark. Frames stream to ffmpeg; the score is generated here.
    uv run -q --with pillow --with numpy python field.py
"""
import math, subprocess, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H, FPS, SECS, SS = 1920, 1080, 30, 20.0, 2          # SS: drawn at 2x, scaled down, for clean lines
INK, PAPER, GOLD, LIGHT = (20, 19, 17), (250, 248, 244), (165, 98, 0), (245, 184, 61)
BOLD = "../fonts/KernelSans-Bold.otf"
OUT, WAV = "v20/kernel-20-field.mp4", "v20/field.wav"
CX, CY = W * SS // 2, H * SS // 2
ease = lambda x: 0.5 - 0.5 * math.cos(math.pi * min(1, max(0, x)))
mix = lambda a, b, k: tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))

# Scenes (start, end): seed, field, chapters, burst, twenty, name.
S = [(0, 3), (3, 7), (7, 11), (11, 15), (15, 17.5), (17.5, 20)]
CHAPTER_W = [0.82, 0.64, 0.9, 0.55, 0.76, 0.68, 0.88, 0.5, 0.72, 0.6, 0.84, 0.58, 0.79, 0.66, 0.92, 0.53, 0.7, 0.62, 0.86, 0.45]

def field(d, t, k, color):
    """Dipole field lines around the seed, drawn in as k goes 0 to 1, turning slowly."""
    for i in range(1, 13):
        r = 140 * SS * i ** 0.85
        pts = []
        for j in range(int(181 * k)):
            th = math.radians(j * 2 - 180)
            rr = r * math.sin(th) ** 2                      # r = L sin^2(theta): a dipole line
            x, y = rr * math.sin(th) * 1.6, rr * math.cos(th)
            rot = t * 0.08                                  # the whole field turns, slowly
            pts += [(CX + x * math.cos(rot) - y * math.sin(rot), CY + x * math.sin(rot) + y * math.cos(rot))]
        if len(pts) > 1:
            d.line(pts, fill=mix(INK, color, 0.35 + 0.05 * (12 - i)), width=2 * SS)

def seed(d, r, color=GOLD):
    d.ellipse([CX - r, CY - r, CX + r, CY + r], fill=color)

def chapters(d, k, y0=None, color=PAPER):
    """Twenty chapter bars, drawn left to right one after another, the last ending on the gold seed."""
    gap, h = 46 * SS, 14 * SS
    y0 = y0 if y0 is not None else CY - gap * 9.5
    x0, full = CX - 520 * SS, 1040 * SS
    for i, w in enumerate(CHAPTER_W):
        p = min(1, max(0, k * 20 - i))
        if p <= 0: break
        y = y0 + i * gap
        d.rounded_rectangle([x0, y, x0 + full * w * ease(p), y + h], radius=h // 2, fill=color)
        if i == 19 and p >= 1:
            sx = x0 + full * w + 26 * SS
            d.ellipse([sx - 11 * SS, y - 4 * SS, sx + 11 * SS, y + h + 4 * SS], fill=LIGHT)

def frame(t):
    img = Image.new("RGB", (W * SS, H * SS), INK)
    d = ImageDraw.Draw(img)
    if t < S[0][1]:                                           # a seed, and one orbit
        k = ease(t / 2.2)
        seed(d, int(36 * SS * k))
        a = t * 2.4
        d.arc([CX - 260 * SS, CY - 160 * SS, CX + 260 * SS, CY + 160 * SS], math.degrees(a), math.degrees(a) + 120 * k, fill=LIGHT, width=3 * SS)
    elif t < S[1][1]:                                         # the field opens around it
        k = ease((t - 3) / 3.2)
        field(d, t, k, LIGHT); seed(d, 36 * SS)
    elif t < S[2][1]:                                         # the field gives way to twenty chapters
        k = (t - 7) / 3.6
        if k < 0.25: field(d, t, 1 - k * 4, LIGHT)
        chapters(d, max(0, k - 0.05) * 1.05)
    elif t < S[3][1]:                                         # the chapters swing into a burst of twenty rays
        k = ease((t - 11) / 2.4)
        for i, w in enumerate(CHAPTER_W):
            a = -math.pi / 2 + k * (i / 20) * 2 * math.pi + (1 - k) * 0
            r0, r1 = 90 * SS, (90 + 520 * w) * SS
            if k < 1e-3: continue
            p0 = (CX + r0 * math.cos(a) * k + (1 - k) * (CX - 520 * SS - CX), CY + r0 * math.sin(a) * k + (1 - k) * ((i - 9.5) * 46 * SS))
            p1 = (CX + r1 * math.cos(a) * k + (1 - k) * (CX - 520 * SS + 1040 * SS * w - CX), CY + r1 * math.sin(a) * k + (1 - k) * ((i - 9.5) * 46 * SS))
            d.line([p0, p1], fill=mix(PAPER, LIGHT, k * (i % 2)), width=int(14 * SS * (1 - 0.6 * k)))
        seed(d, int(36 * SS * k))
        if t > 13.6:                                          # rings, one per four chapters
            for i in range(5):
                r = (120 + 110 * i) * SS * ease((t - 13.6) / 1.2)
                d.ellipse([CX - r, CY - r, CX + r, CY + r], outline=mix(INK, GOLD, 0.8), width=2 * SS)
    elif t < S[4][1]:                                         # 20, outlined then filled
        k = (t - 15) / 2.5
        f = ImageFont.truetype(BOLD, 620 * SS)
        field(d, t, 1, GOLD)
        box = d.textbbox((0, 0), "20", font=f)
        x, y = CX - (box[2] - box[0]) // 2 - box[0], CY - (box[3] - box[1]) // 2 - box[1]
        d.text((x, y), "20", font=f, fill=INK, stroke_width=4 * SS, stroke_fill=LIGHT)
        if k > 0.35:
            d.text((x, y), "20", font=f, fill=mix(INK, LIGHT, ease((k - 0.35) / 0.4)))
    else:                                                     # the mark and the name
        k = ease((t - 17.5) / 0.8)
        mark = Image.open("v20/mark.png").convert("RGBA")
        m = int(180 * SS); mark = mark.resize((m, m), Image.LANCZOS)
        f = ImageFont.truetype(BOLD, 120 * SS)
        gap = 28 * SS
        widths = [d.textlength(c, font=f) for c in "KERNEL"]
        total = m + 60 * SS + sum(widths) + gap * 5
        x = CX - total // 2
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        layer.paste(mark, (int(x), CY - m // 2), mark)
        ld = ImageDraw.Draw(layer)
        cx = x + m + 60 * SS
        for c, cw in zip("KERNEL", widths):
            ld.text((cx, CY), c, font=f, fill=PAPER + (255,), anchor="lm"); cx += cw + gap
        a = layer.getchannel("A").point(lambda v: int(v * k))
        layer.putalpha(a)
        img.paste(layer, (0, 0), layer)
        if t > 19.3:
            fade = ease((t - 19.3) / 0.7)
            img = Image.blend(img, Image.new("RGB", img.size, INK), fade)
    return img.resize((W, H), Image.LANCZOS)

def score():
    """A low D drone that swells scene by scene, a tick on each scene change, a bell on 20 and a boom on the name."""
    sr = 48000; n = int(sr * SECS); t = np.arange(n) / sr
    swell = np.clip(t / 15, 0, 1) ** 1.5 * (t < 17.5) + (t >= 17.5) * np.clip(1 - (t - 17.5) / 2.5, 0, 1) * 0.6
    drone = sum(np.sin(2 * np.pi * f * t + p) * a for f, a, p in [(73.42, 0.5, 0), (110.0, 0.25, 1), (146.83, 0.18, 2), (73.9, 0.3, 0.5)])
    out = drone * (0.15 + 0.6 * swell)
    for s, _ in S[1:]:
        i = int(s * sr); e = np.exp(-np.arange(int(0.3 * sr)) / (0.04 * sr))
        out[i:i + len(e)] += 0.5 * e * np.sin(2 * np.pi * 880 * np.arange(len(e)) / sr)
    for at, f, amp, dec in [(15.0, 587.33, 0.45, 0.9), (15.0, 880.0, 0.25, 0.7), (17.5, 41.2, 0.9, 0.6)]:
        i = int(at * sr); m = n - i; e = np.exp(-np.arange(m) / (dec * sr))
        out[i:] += amp * e * np.sin(2 * np.pi * f * np.arange(m) / sr)
    out[:int(0.05 * sr)] *= np.linspace(0, 1, int(0.05 * sr)); out[-int(0.5 * sr):] *= np.linspace(1, 0, int(0.5 * sr))
    out = out / np.max(np.abs(out)) * 0.85
    st = np.stack([out, np.roll(out, 240)], 1)
    with wave.open(WAV, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(sr); w.writeframes((st * 32767).astype("<i2").tobytes())

if __name__ == "__main__":
    score()
    ff = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                           "-i", WAV, "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-shortest", OUT], stdin=subprocess.PIPE)
    for i in range(int(SECS * FPS)):
        ff.stdin.write(frame(i / FPS).tobytes())
    ff.stdin.close(); ff.wait()
    print("wrote", OUT)
