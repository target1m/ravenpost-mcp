---
name: prepare-post-media
description: Get images and video into Ravenpost's media library and into the right shape for each network — upload from a URL, a local path or a direct presigned upload, reformat to feed, square, landscape, story or reel canvases, cut one image into several platform sizes at once, import an app's App Store or Google Play screenshots, screenshot a website, and make a short branded template video (a launch video, a feature list, an announcement, a milestone) from those pictures. Use when a post needs a picture or video, when the user hands over a file or link to post, when an image is the wrong aspect ratio for Instagram or TikTok, when they ask for a launch or promo video, a screenshot of their site, or their store screenshots, or when they ask what sizes a platform wants.
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
site, their store listing, their own screenshots in a template video. If a post
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
| A short branded video | `list_video_templates`, then `create_video` with the pictures above as `shots` | The video price `list_video_templates` returns, handed back if the render fails |

Prices are the workspace's own and an administrator may change them, so read
them from `list_video_templates` rather than from memory. In this order:

1. **Store screenshots first** when the user has an app: `import_app_screenshots`
   costs nothing, and a picture already imported is reused rather than copied.
2. **Look before capturing**: `list_media` may already hold the screenshots or
   the capture you are about to pay for.
3. **Say the price before a render or a capture** the user did not explicitly
   ask to pay for, and stop if they decline. Once the month's credits are spent
   both tools refuse with the balance: tell the user, do not retry.

No generative model draws anything here: `create_video` fills a fixed
template with the user's own pictures and words.

`create_video` takes one flat set of fields for every template — headline,
subheadline, body, shots, features, cta, stat — and each template reads what
it needs; its result says what a template left out. Render only what the user
asked for, settle the template, the headline and the pictures first, and when
the call comes back still rendering, pick it up with `get_video` (`wait: 45`)
rather than starting another. A vertical video is the default and right for
Reels, TikTok, Shorts and Stories; Instagram takes it as `type: "REEL"`.

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
