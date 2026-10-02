# Bookrank's own bed, Tchaikovsky-inspired: a waltz in D major in the spirit of the Sleeping Beauty and
# Flowers waltzes. Pizzicato bass on one, soft plucked chords on two and three, a harp rolling underneath,
# a string pad that swells under it, a celesta carrying the tune. 3/4 at 132 BPM. numpy only.
import numpy as np, wave
SR, BPM, DUR = 44100, 132, 37.0
B = 60 / BPM; BAR = 3 * B
N = int(SR * DUR); mix = np.zeros(N)
DROP = 3.1   # the waltz steps in on the first screen
END = 30.9   # end card: the pulse drops out and the last chord rings
def hz(n): return 440 * 2 ** ((n - 69) / 12)
def add(start, sig, gain):
    i = int(round(start * SR))
    if i < 0: sig, i = sig[-i:], 0
    j = min(N, i + len(sig))
    if i < N and j > i: mix[i:j] += gain * sig[:j - i]
def tt(d): return np.arange(int(d * SR)) / SR
def harp(n, d=1.4):
    t = tt(d); f = hz(n)
    return (np.sin(2 * np.pi * f * t) + 0.32 * np.sin(4 * np.pi * f * t) * np.exp(-t * 6) + 0.1 * np.sin(6 * np.pi * f * t) * np.exp(-t * 9)) * np.exp(-t * 3.2) * np.minimum(1, t / 0.003)
def celesta(n, d=1.2):
    t = tt(d); f = hz(n)
    return (np.sin(2 * np.pi * f * t) + 0.45 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 10) + 0.18 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 14)) * np.exp(-t * 3.6) * np.minimum(1, t / 0.002)
def pizz(n, d=0.5):
    t = tt(d); f = hz(n)
    return (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(4 * np.pi * f * t) * np.exp(-t * 14)) * np.exp(-t * 8) * np.minimum(1, t / 0.002)
def pad(notes, d):
    t = tt(d)
    env = np.minimum(1, t / 0.9) * np.minimum(1, np.maximum(0, d - t) / 1.1)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t)
    s = sum(np.sin(2 * np.pi * hz(n) * vib * t + p) + 0.5 * np.sin(2 * np.pi * hz(n) * 2 * vib * t) * 0.3
            for n in notes for p in (0.0, 1.7, 3.1)) / (3 * len(notes))
    return s * env
# one 8-bar round of the waltz: chord (voicing), bass root, three melody notes
D, A, Bm, G = [62, 66, 69], [61, 64, 69], [62, 66, 71], [59, 62, 67]
ROUND = [
    (D, 50, [78, 76, 74]), (A, 45, [73, 76, 81]), (Bm, 47, [79, 78, 74]), (G, 43, [71, 74, 79]),
    (D, 50, [78, 76, 74]), (A, 45, [81, 78, 76]), (Bm, 47, [74, 78, 83]), (A, 45, [81, 79, 76]),
]
OFF = DROP % BAR - BAR
bars = int((DUR - OFF) / BAR) + 1
for b in range(bars):
    t0 = OFF + b * BAR
    chord, root, mel = ROUND[b % len(ROUND)]
    groove = DROP - 0.01 <= t0 < END - 0.3
    ringing = t0 >= END - 0.3
    add(t0, pad([root + 12] + chord, BAR + 0.5), 0.16 if groove or ringing else 0.10)   # the strings underneath, always
    if ringing:
        if t0 < END + 0.01:
            for k, n in enumerate([50, 57, 62, 66, 69, 74]): add(t0 + k * 0.09, harp(n, 3.0), 0.22)   # one last rolled D chord
        continue
    for beat in range(3):
        tb = t0 + beat * B
        arp = [n - 12 for n in chord] + [chord[0], chord[1] + 0.0]
        add(tb, harp(arp[beat] + 12 * (beat == 2), 1.4), 0.20 if groove else 0.14)         # the harp rolls up the chord
        if groove:
            if beat == 0: add(tb, pizz(root), 0.42)                                        # pizzicato bass on one
            else:
                for n in chord: add(tb, pizz(n - 12, 0.4), 0.10)                           # soft off-beat chord on two and three
            add(tb, celesta(mel[beat], 1.2), 0.20)                                         # the tune
peak = np.abs(mix).max()
mix = mix / peak * 0.8
fade = int(SR * 0.4)
mix[:fade] *= np.linspace(0, 1, fade)
with wave.open("music2.wav", "w") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((mix * 32767).astype("<i2").tobytes())
print("MUSIC2", DUR, "bars", bars)
