---
name: explaining-clearly-video
description: Use when the user asks for an explainer video, an animated or narrated explanation, a 3Blue1Brown or 3b1b style video, or a Manim animation of how code, a system, or a concept works.
---

# Explaining Clearly, as a Video

The video is a **story** told in scenes: afterward the viewer can rebuild the
whole picture from memory. Each scene is one narrated paragraph with the
animation built to match it, pointing at real code.

## The story

Every video uses this shape, in this order, one scene per part.
`Side by side` appears only when two things are compared; the other parts are
always present.

1. **The problem**: no code. The need, or what breaks without this. Open here
   so the code that follows already has a reason to exist.
2. **One scene per piece**, in build order, each named on screen for the real
   noun or mechanism inside it. Open each by naming the gap the previous piece
   left. Where the piece branches ("if X, continue, else stop"), show the field
   or check that drives it and where that value comes from, before either side.
3. **Side by side**: only when comparing two things, and only after each has
   its own scene. Show the one axis they differ on.
4. **The point, restated**: one or two plain sentences answering the original
   question. Nothing new here.
5. **Closing question**: not on screen. It ends the message you deliver the
   video in. Ask something a wrong or hesitant answer would expose, aimed at
   the scene most likely to be misread. Their answer decides whether to re-cut
   that scene.

Cut any scene the restated point didn't need.

## Done when

- Every code panel on screen carries its **receipt**: a caption under it with
  the `file:line` range it came from, read this turn. The caption is for the
  eye; the narration names the function, never the line number.
- Every branch point shows its **mechanism**: the exact field or check, and
  what produces its value.
- Every object on screen is introduced by the narration while it appears, and
  removed when its scene no longer needs it.
- A diagram grows with the story: each scene adds only the piece it explains.
  The full diagram appears last, when every piece in it has been named.
- Every term is grounded in something the viewer already owns, or defined in
  the same breath and then used.
- The narration is **audible in every scene** and the frames are checked, both
  measured as in Verify below, before you say the video is done.

## Narration voice

Write the way Sebastian Raschka and Chip Huyen talk when they explain a system.
One idea per sentence, then a period. Plain words: "use" not "utilize", "since"
not "given that", "but" not "however". Read the paragraph aloud; if you run out
of breath before the period, split it. An analogy comes after the mechanism,
never instead of it. Zero em dashes; use a period or a comma.

## If the story involves

- **A library or framework's behaviour**: the installed source can be pinned
  and stale, so also read the current official docs.
- **A worked example**: grep for a real caller first. None exists: say so, then
  build one from real names and values, labelling what you constructed.
- **A document rather than code**: the problem scene carries the need the
  document answers and the one idea it rests on. Organise the scenes by that
  argument, never by the source's own headings in its own order.

## Making the video

### Setup

- Manim Community is at `~/.local/bin/manim`; `ffmpeg`, `ffprobe` and LaTeX are
  installed.
- Narration is Voicebox, local and keyless: its server answers on
  `127.0.0.1:17493` and the step 2 snippet starts it when it is down (about
  20 s). The voice is the Kokoro preset `bf_isabella`, calm British, chosen by
  the user; use another only when asked (`GET /profiles/presets/kokoro`).
- Missing the model or profile on a fresh machine: `POST /models/download`
  with `{"model_name":"kokoro"}`, then `POST /profiles` with
  `{"name":"bf_isabella","voice_type":"preset","preset_engine":"kokoro","preset_voice_id":"bf_isabella","default_engine":"kokoro"}`.
- No Voicebox at all: macOS `say -o sN.aiff "<text>"` gives the same clips.

### Steps

1. **Script**: `script.md`, one narration paragraph per scene.
2. **Voice first**: one clip per scene, then measure each with `ffprobe`. The
   clip's length sets the scene's length, not the other way round.

   ```sh
   API=http://127.0.0.1:17493
   curl -sf $API/health >/dev/null || {
     nohup /Applications/Voicebox.app/Contents/MacOS/voicebox-server --port 17493 \
       --data-dir "$HOME/Library/Application Support/sh.voicebox.app" >/tmp/voicebox.log 2>&1 &
     for i in $(seq 60); do curl -sf $API/health >/dev/null && break; sleep 1; done; }
   VOICE=$(curl -s $API/profiles | jq -r '.[] | select(.name=="bf_isabella") | .id')

   clip() {  # clip s1 "<narration>"  ->  s1.wav; jq escapes quotes in the text
     local gid st i
     gid=$(jq -n --arg p "$VOICE" --arg t "$2" '{profile_id:$p, engine:"kokoro", text:$t}' |
       curl -s -X POST $API/generate -H 'Content-Type: application/json' -d @- | jq -r '.id // empty')
     [ -n "$gid" ] || { echo "no job: server down or no bf_isabella profile (Setup)" >&2; return 1; }
     for i in $(seq 240); do   # 2 min cap, so a stuck job fails instead of hanging
       st=$(curl -s -m 5 $API/generate/$gid/status | grep -oE '"(completed|failed)"') && break; sleep 0.5
     done
     [ "$st" = '"completed"' ] && curl -s -o "$1.wav" $API/audio/$gid
   }
   clip s1 "<scene 1 narration>"
   ```

3. **Scenes**: each one starts its clip, plays its animations, then waits out
   whatever is left of the clip. Code goes in `Code`, never `Text`: `Text`
   drops leading spaces, so indentation disappears.

   ```python
   def scene_start(self, clip):
       self.add_sound(clip)
       t0, d = self.renderer.time, duration(clip)   # duration = ffprobe
       return lambda: self.wait(max(0.1, d - (self.renderer.time - t0)) + 0.4)

   done = self.scene_start("s2.wav")
   code = Code(code_string=src, language="bash", add_line_numbers=False)
   cap = Text("install.sh:80-97", font_size=20).next_to(code, DOWN)
   self.play(FadeIn(code), FadeIn(cap))
   done()
   ```

4. **Render with `--disable_caching`, every time**:
   `manim -qh --disable_caching scene.py <Scene>`. With the cache warm, a
   re-render reuses the cached animations and drops their `add_sound` clips:
   a 50 s video came back with 17 s of audio, and only the first clip
   survived. Nothing errors; the scenes are just silent.
5. **Verify** the rendered file, not the code:

   ```sh
   ffprobe -v error -show_entries stream=codec_type,duration -of compact final.mp4
   ffmpeg -hide_banner -i final.mp4 -af silencedetect=noise=-40dB:d=2 -f null - 2>&1 | grep silence_duration
   ```

   Two checks, because a clip can drop in two places. The **audio** duration
   must be at least the sum of your clip lengths from step 2: shorter means
   clips dropped at the end, where the audio stream simply stops. And no
   `silence_duration` line unless you put that pause there on purpose: a silent
   stretch the length of one of your clips is that clip, dropped mid-video. Then
   look at a still from each scene (`manim -s`, or frames pulled with `ffmpeg`)
   for overlapping text and objects left over from an earlier scene.
6. **Deliver**: the path, what you measured in step 5 (the numbers), then the
   closing question.
