---
name: prepare-post-media
description: Get images and video into Ravenpost's media library and into the right shape for each network — upload from a URL, a local path or a direct presigned upload, reformat to feed, square, landscape, story or reel canvases, cut one image into several platform sizes at once, import an app's App Store or Google Play screenshots, screenshot a website, and make a short branded video from those pictures and the user's own clips — a reel told in scenes, with one of Ravenpost's own music tracks, or a fixed template (a launch video, a feature list, an announcement, a milestone). Use when a post needs a picture or video, when the user hands over a file or link to post, when an image is the wrong aspect ratio for Instagram or TikTok, when they ask for a reel, a TikTok, a launch or promo video, a screenshot of their site, or their store screenshots, or when they ask what sizes a platform wants.
---

# Prepare media for a post

Media lives in a per-workspace library and is referenced by id: upload once,
reuse the id in as many posts as you like. **Settle the workspace first**
(`list_workspaces`) — a media id from one workspace is refused in another, and
a storage key is refused outright.

Full argument list:
[`../publish-a-social-post/references/tools.md`](../publish-a-social-post/references/tools.md).
Per-platform media rules:
[`../publish-a-social-post/references/platforms.md`](../publish-a-social-post/references/platforms.md).

## You cannot invent the picture

No tool here draws an image with AI. The upload tools **ingest** files, and the
three further down make media only from what is already the user's — their
site, their store listing, their own screenshots and clips in a video. If a post
needs media and none of that fits, ask for it. Do not describe an image you
intend to produce, and do not fetch a stock photo from the open web on the
user's behalf — that is someone else's licence, and they did not ask for it.

## Getting a file in

| Situation | Tool | Notes |
|---|---|---|
| The file is already online | `upload_media` with `url` | The usual case, and the cheapest |
| A large file, or anything in production | `create_media_upload` → HTTP `PUT` the bytes → `attach_media` | Bytes go straight to storage, never through this conversation |
| A small image you already hold as bytes | `upload_media` with `base64` | Images only; avoid for video |
| A local path | `upload_media` with `path` | A development server only — it reads its own disk. The hosted server does not offer the argument at all |
| It is already in the library | `list_media` | Reuse the id instead of uploading twice |

The presigned route is three calls on purpose: `create_media_upload` returns an
`uploadUrl` and a `storageKey`, you PUT the raw bytes to that URL with the
matching `Content-Type`, then `attach_media` records it with the **same**
`workspaceId` you presigned in.

## Making pictures and video, not only uploading them

Three tools make media rather than take it, and all three land in the same
library as an upload, so the ids they return go wherever a media id goes:

| Want | Tool | Costs |
|---|---|---|
| The app's own store screenshots and icon | `import_app_screenshots` — reads the App Store or Google Play listing saved in the brand profile, or a link you pass | Nothing; a picture already imported is reused |
| A picture of the website | `capture_screenshot` — desktop and/or phone, first screen or whole page | The price per device `list_video_templates` returns |
| A short branded video | `list_video_templates`, then `create_video`: a storyboard's scenes take the pictures above and the user's own clips by media id, a fixed template takes the pictures as `shots` | The video price `list_video_templates` returns, handed back if the render fails |

Prices are the workspace's own and an administrator may change them, so read
them from `list_video_templates` rather than from memory. In this order:

1. **Store screenshots first** when the user has an app: `import_app_screenshots`
   costs nothing, and a picture already imported is reused rather than copied.
2. **Look before capturing**: `list_media` may already hold the screenshots or
   the capture you are about to pay for.
3. **Say the price before a render or a capture** the user did not explicitly
   ask to pay for, and stop if they decline. Once the month's credits are spent
   both tools refuse with the balance: tell the user, do not retry.

No generative model draws or composes anything here: `create_video` lays out
the user's own pictures, clips and words, and a storyboard's music is one of
three fixed tracks in Ravenpost's own catalogue, made once for these videos
and the same for every workspace.

Render only what the user asked for, and settle the template, the words and
the pictures first. Rendering takes one to five minutes, a 30-second
storyboard the most; when the call comes back still rendering, pick it up
with `get_video` (`wait: 45`) rather than starting another. A vertical video
is the default and right for Reels, TikTok, Shorts and Stories; Instagram
takes it as `type: "REEL"`.

### A reel is a storyboard

A reel, a TikTok or a Short is `template: "storyboard"` unless the user asked
for one of the fixed templates: two to ten `scenes`, at most 30 seconds,
cross-faded in order. `headline` is still required; for a storyboard it is
the name the video is filed under. What holds a scroll:

- **Scene 1 is a `hook`**, and it is also the cover: the viewer's question, a
  claim they would argue with, or the problem in their words, in under seven
  words, with the turn in `accent` ("Posting to nine apps?" / "Do it once.").
  Never open on the brand's name or a greeting.
- **Then show it**, in two to four scenes: `device` with a real screen of the
  product (store screenshots or a capture first; `motion: "scroll"` for a whole
  page), `clip` with the user's own footage, `compare` for the old way beside
  the new, `chat` for an app that answers questions, `stat` for a number the
  user gave you, `list` for at most three short points, `statement` for one
  sentence.
- **End on `end`**: the brand, a closing line and `create_video`'s own `cta`.
  Five to seven scenes and 12 to 25 seconds hold best; leave the durations to
  the template unless a scene needs longer.
- **Music** is `music`: `pulse` for a launch or a number, `glow` for a
  walkthrough, `drift` for tips. Leave it out when the user's clip has sound
  worth keeping, and set `sound: true` on that scene.
- One idea per scene and few words: a scene is read in two seconds. The
  template keeps every word clear of the buttons and the caption Reels, TikTok
  and Shorts draw over a vertical video, so never pad text to move it.

### The fixed templates

App showcase, feature list, announcement and milestone are silent and take one
flat set of fields — headline, subheadline, body, shots, features, cta, stat —
each reading what it needs; the result says what a template left out. Use
them when the user asked for one, or for a release note (feature list) or a
number (milestone) outside a reel.

## Shaping it

Images are reformatted on the way in, to the canvas the `format` argument names:

- `feed_square` (1:1), `feed_portrait` (4:5 — the largest an Instagram feed shows),
  `landscape` (1.91:1), `story` (9:16, also what a reel or a TikTok photo wants),
  `original` (untouched).
- `fit`: `cover` crops to fill (default), `contain` pads so nothing is cut off.
- `crop`: `smart` finds the subject (default), `centre` is predictable — better
  for posters, screenshots and flat graphics composed around their middle.

`image_formats` returns the live list with target dimensions.

**One image, several networks:** `create_variants` cuts one library image into
any of `feed_portrait`, `feed_square`, `landscape` and `story` in one call and
returns the new ids. Variants inherit the source's alt text and folder, the
source is left alone, and two formats with the same dimensions produce one file.
This is the right move when a post goes to an Instagram feed and a TikTok at
once — pass each destination the id that fits it.

## Video is stored as-is

Video is never re-encoded: `format`, `fit` and `crop` are ignored, and the file
is recorded exactly as uploaded (mp4, mov or webm). Cut it before uploading.
Four consequences worth saying out loud before the post fails:

- **Instagram video must be posted as `REEL` or `STORY`.** An `IMAGE` or
  `CAROUSEL` post carrying a video is rejected at publish time.
- **Bluesky takes up to four images or one video, never both** — a video goes
  alone. Bluesky rations video per account per day, and an account it hosts
  needs a verified email address before it can upload any; a video Bluesky
  refuses fails the post with the reason rather than publishing it without the
  video.
- **YouTube takes nothing but video** (one per post, no images).
- **TikTok refuses PNG images** — JPEG or WebP — and it refuses them
  *asynchronously*, minutes after the upload appeared to work. Convert before
  uploading rather than debugging it afterwards.

## Alt text

Alt text belongs to the asset, not the post: written once, it rides along to X,
Bluesky and Threads on every post that uses the file (Instagram's publishing API
has no field for it). Set it in the Ravenpost media library.
