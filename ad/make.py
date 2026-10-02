# The Bookrank ad. Same shape as Joshua Tree's: a voice reads ad.txt, every cut lands on a
# sentence, real app screenshots sit in a rounded frame on the house paper, type cards hold
# the few words, and it ends on the mark. No version number, ever. Run: python3 make.py
import base64, json, os, re, subprocess, urllib.request
os.chdir(os.path.dirname(os.path.abspath(__file__)))
FONT = '' or "/System/Library/Fonts/SFNS.ttf"  # Bookrank sets type in Geist, like the app and the landing
BG, INK, SOFT = "0x0A0A0A", "0xFAFAFA", "0x8A8A8A"
FPS, W, H = 24, 1920, 1080
VO_AT = 0.8      # the picture starts, the voice comes in after a breath
VOICE = "Xb7hH8MSUJpSbSDYk0k2"  # Alice, host A in the app
TAIL = 4.6       # end card holds after the last word

def run(a): subprocess.run(["ffmpeg", "-v", "error", "-y", *a], check=True)
def text_png(text, size, color, out):
    subprocess.run(["magick", "-background", "none", "-fill", "#" + color[2:], "-font", FONT, "-pointsize", str(size), f"label:{text}", out], check=True)
    return out
os.makedirs("cut", exist_ok=True)

# 1. Voice, with the time every character is spoken, so the edit can follow the sentences.
script = open("ad.txt").read().strip()
if not os.path.exists("ad.mp3") or not os.path.exists("align.json"):
    key = re.search(r"ELEVENLABS_API_KEY ['\"]?([^'\"\s]+)", open(os.path.expanduser("~/.config/fish/secrets.fish")).read()).group(1)
    req = urllib.request.Request(f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE}/with-timestamps?output_format=mp3_44100_128",
                                 data=json.dumps({"text": script, "model_id": "eleven_flash_v2_5", "voice_settings": {"stability": 0.55, "similarity_boost": 0.8, "speed": 0.95}}).encode(),
                                 headers={"xi-api-key": key, "Content-Type": "application/json"})
    out = json.load(urllib.request.urlopen(req, timeout=60))
    open("ad.mp3", "wb").write(base64.b64decode(out["audio_base64"]))
    json.dump(out["alignment"], open("align.json", "w"))
al = json.load(open("align.json"))
spoken = "".join(al["characters"])
starts = al["character_start_times_seconds"]
vo_end = al["character_end_times_seconds"][-1]
def at(sentence):
    i = spoken.find(sentence[:14])
    assert i >= 0, sentence
    return starts[i] + VO_AT

# 2. The cut: one visual per sentence of ad.txt. (sentence, kind, args)
sentences = [s.strip() for s in re.sub(r"<break[^>]*>", "", script).split("\n") if s.strip()]
PLAN = [
    ("card",  ("You finish a book.",)),
    ("card",  ("A month later you remember one idea.",)),
    ("clip", (9.4, "Every book you have read, with its cover.")),
    ("clip", (15.3, "Every chapter, in plain words.")),
    ("clip", (21.9, "Read it. Or press Listen.")),
    ("clip", (27.4, "Two voices talk it through. The words light up as they go.")),
    ("card",  ("Yours to keep.",)),
    ("end",   ()),
]
assert len(PLAN) == len(sentences), (len(PLAN), len(sentences))
t = [at(s) for s in sentences]
t[0] = 0.0
durs = [t[i + 1] - t[i] for i in range(len(t) - 1)] + [vo_end + VO_AT + TAIL - t[-1]]

def card(text, dur, out, size=108):
    png = text_png(text, size, INK, f"cut/card-{abs(hash(text))}.png")
    run(["-f", "lavfi", "-i", f"color=c={BG}:s={W}x{H}:r={FPS}", "-i", png, "-filter_complex",
         f"[0:v][1:v]overlay=(W-w)/2:(H-h)/2,fade=t=in:st=0:d=0.3,fade=t=out:st={dur - 0.3}:d=0.3,format=yuv420p", "-t", str(dur), "-c:v", "libx264", "-crf", "16", out])

def screen(shot, dur, cap, out, height=860, radius=54, start=None):
    # a real screenshot, rounded, on the paper, with a small caption low left; it rises 14px over the slot
    w, h = map(int, subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=p=0", shot],
                                   capture_output=True, text=True).stdout.strip().split(",")[:2])  # works for a still or the walk footage
    sw = round(w * height / h)
    mask = f"cut/mask-{sw}x{height}.png"
    subprocess.run(["magick", "-size", f"{sw}x{height}", "xc:black", "-fill", "white", "-draw", f"roundrectangle 0,0 {sw - 1},{height - 1} {radius},{radius}", mask], check=True)
    capp = text_png(cap, 36, INK, f"cut/cap-{abs(hash(cap))}.png")
    x = (W - sw) // 2
    top = 56  # the frame sits high; the caption is centred under it, where the eye lands next
    # the device: an ink bezel 14px proud of the screen, a soft shadow under it, a slow 3% push in
    bz, pad = 14, 90
    body = f"cut/body-{sw}x{height}.png"
    subprocess.run(["magick", "-size", f"{sw + 2 * pad}x{height + 2 * pad}", "xc:none",
                    "-fill", "#262626", "-draw", f"roundrectangle {pad - bz - 1},{pad - bz - 1} {pad + sw + bz + 1},{pad + height + bz + 1} {radius + bz},{radius + bz}",
                    "-fill", "#121212", "-draw", f"roundrectangle {pad - bz},{pad - bz} {pad + sw + bz},{pad + height + bz} {radius + bz},{radius + bz}", body], check=True)
    src = ["-ss", str(start), "-t", str(dur), "-i", shot] if start is not None else ["-loop", "1", "-framerate", str(FPS), "-i", shot]
    run([*src, "-loop", "1", "-framerate", str(FPS), "-i", mask,
         "-f", "lavfi", "-i", f"color=c={BG}:s={W}x{H}:r={FPS}", "-loop", "1", "-framerate", str(FPS), "-i", capp,
         "-loop", "1", "-framerate", str(FPS), "-i", body, "-filter_complex",
         f"[0:v]scale={sw}:{height}:flags=lanczos,format=rgba[v];[1:v]format=gray[m];[v][m]alphamerge[r];"
         f"[4:v][r]overlay={pad}:{pad}[dev];[dev]scale=w='iw*(1+0.03*min(t/{dur},1))':h=-1:eval=frame[z];"
         f"[2:v][z]overlay=(W-w)/2:{top - pad + (height + 2 * pad) // 2}-h/2[a];[a][3:v]overlay=(W-w)/2:{top + height + 44},"
         f"fade=t=in:st=0:d=0.3,fade=t=out:st={dur - 0.3}:d=0.3,format=yuv420p", "-t", str(dur), "-c:v", "libx264", "-crf", "16", out])

def end(dur, out):
    subprocess.run(["rsvg-convert", "-w", "240", "-h", "240", "../icon.svg", "-o", "cut/mark.png"], check=True)
    title = text_png("Bookrank", 104, INK, "cut/title.png")
    sub = text_png("Chapter summaries of the books you read.   bookrank.heyitsmejosh.com", 32, SOFT, "cut/sub.png")
    run(["-f", "lavfi", "-i", f"color=c={BG}:s={W}x{H}:r={FPS}", "-loop", "1", "-framerate", str(FPS), "-i", "cut/mark.png",
         "-loop", "1", "-framerate", str(FPS), "-i", title, "-loop", "1", "-framerate", str(FPS), "-i", sub, "-filter_complex",
         "[1:v]format=rgba,fade=t=in:st=0.2:d=0.6:alpha=1[k];[2:v]format=rgba,fade=t=in:st=0.9:d=0.6:alpha=1[t];[3:v]format=rgba,fade=t=in:st=1.9:d=0.6:alpha=1[s];"
         f"[0:v][k]overlay=(W-w)/2:300[a];[a][t]overlay=(W-w)/2:580[b];[b][s]overlay=(W-w)/2:720,fade=t=out:st={dur - 1.2}:d=1.2,format=yuv420p",
         "-t", str(dur), "-c:v", "libx264", "-crf", "16", out])

parts = []
for i, ((kind, a), dur) in enumerate(zip(PLAN, durs)):
    out = f"cut/{i:02d}.mp4"
    if kind == "card": card(a[0], dur, out)
    elif kind == "phone": screen(a[0], dur, a[1], out)
    elif kind == "clip":  # live footage from the simulator walk, cut first so the seek is exact
        # simctl records only when pixels change, so still moments have no frames; make it constant rate first
        if not os.path.exists("cut/walk24.mp4"):
            run(["-i", "shots/walk.mov", "-vf", f"fps={FPS}", "-fps_mode", "cfr", "-an", "-c:v", "libx264", "-crf", "14", "-pix_fmt", "yuv420p", "cut/walk24.mp4"])
        run(["-ss", str(a[0]), "-t", str(dur), "-i", "cut/walk24.mp4", "-an", "-c:v", "libx264", "-crf", "14", f"cut/clip{i}.mp4"])
        screen(f"cut/clip{i}.mp4", dur, a[1], out, start=0)
    else: end(dur, out)
    parts.append(out)
open("cut/list.txt", "w").write("".join(f"file '{os.path.basename(p)}'\n" for p in parts))
run(["-f", "concat", "-safe", "0", "-i", "cut/list.txt", "-c", "copy", "cut/picture.mp4"])
total = sum(durs)

# 3. Music: the Joshua Tree bed, cut to this length; groove in on the first screenshot, out on the end card.
m = open("music.py").read()
m = re.sub(r"SR, BPM, DUR = 44100, 120, [\d.]+", f"SR, BPM, DUR = 44100, 120, {total + 0.5:.2f}", m)
m = re.sub(r"^DROP = [\d.]+", f"DROP = {t[2]:.2f}", m, flags=re.M)
m = re.sub(r"^END = [\d.]+", f"END = {t[-1]:.2f}", m, flags=re.M)
open("cut/music.py", "w").write(m)
subprocess.run(["uv", "run", "--quiet", "--with", "numpy", "python3", "music.py"], check=True, cwd="cut")

run(["-i", "cut/picture.mp4", "-i", "ad.mp3", "-i", "cut/music2.wav", "-filter_complex",
     f"[1:a]adelay={int(VO_AT * 1000)}:all=1,aformat=channel_layouts=stereo,asplit[vo][vo2];"
     f"[2:a]asplit[lo][hi];[lo]lowpass=f=220,aformat=channel_layouts=stereo[l];"
     f"[hi]highpass=f=220,aformat=channel_layouts=stereo,adelay=0|14,aecho=0.8:0.5:90:0.18[h];"
     f"[l][h]amix=inputs=2:normalize=0,equalizer=f=90:t=q:w=1:g=-4,equalizer=f=2200:t=q:w=1:g=4,volume=0.7,afade=t=out:st={total - 2}:d=2[m];"
     f"[m][vo]sidechaincompress=threshold=0.1:ratio=1.6:attack=40:release=600[duck];"
     f"[duck][vo2]amix=inputs=2:normalize=0,loudnorm=I=-16:TP=-1.5[a]",
     "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", str(total), "-movflags", "+faststart", "bookrank-ad.mp4"])
run(["-ss", str(t[5] + 2.0), "-i", "bookrank-ad.mp4", "-frames:v", "1", "-q:v", "3", "ad-poster.jpg"])
print("AD", round(total, 1), "s; cuts at", [round(x, 1) for x in t])
