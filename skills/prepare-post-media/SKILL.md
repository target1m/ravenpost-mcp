---
name: prepare-post-media
description: Get images and video into Ravenpost's media library and into the right shape for each network — upload from a URL, a local path or a direct presigned upload, reformat to feed, square, landscape, story or reel canvases, and cut one image into several platform sizes at once. Use when a post needs a picture or video, when the user hands over a file or link to post, when an image is the wrong aspect ratio for Instagram or TikTok, or when they ask what sizes a platform wants.
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

## You cannot make the picture

These tools **ingest** files; nothing here generates an image or a video. If a
post needs media and the user has not provided any, ask for it. Do not describe
an image you intend to produce, and do not fetch a stock photo from the open web
on the user's behalf — that is someone else's licence, and they did not ask for it.

## Getting a file in

| Situation | Tool | Notes |
|---|---|---|
| The file is already online | `upload_media` with `url` | The usual case, and the cheapest |
| A large file, or anything in production | `create_media_upload` → HTTP `PUT` the bytes → `attach_media` | Bytes go straight to storage, never through this conversation |
| A small image you already hold as bytes | `upload_media` with `base64` | Images only; avoid for video |
| A local path | `upload_media` with `path` | Development only — the server reads its own disk, and refuses in production |
| It is already in the library | `list_media` | Reuse the id instead of uploading twice |

The presigned route is three calls on purpose: `create_media_upload` returns an
`uploadUrl` and a `storageKey`, you PUT the raw bytes to that URL with the
matching `Content-Type`, then `attach_media` records it with the **same**
`workspaceId` you presigned in.

## Shaping it

Images are reformatted on the way in; pass `format`:

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
Three consequences worth saying out loud before the post fails:

- **Instagram video must be posted as `REEL` or `STORY`.** An `IMAGE` or
  `CAROUSEL` post carrying a video is rejected at publish time.
- **Bluesky takes no video at all**, and **YouTube takes nothing but video**
  (one per post, no images).
- **TikTok refuses PNG images** — JPEG or WebP — and it refuses them
  *asynchronously*, minutes after the upload appeared to work. Convert before
  uploading rather than debugging it afterwards.

## Alt text

Alt text belongs to the asset, not the post: written once, it rides along to X,
Bluesky, Threads and Mastodon on every post that uses the file. Set it in the
Ravenpost media library.
