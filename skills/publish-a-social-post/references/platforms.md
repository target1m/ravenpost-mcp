# Platform reference

Generated from Ravenpost's platform registry. `platform_limits` returns the
same facts **live** — prefer it when a number decides whether a post is
accepted, because an operator can withdraw a platform between releases.

## Caption budgets and media

| Platform | Caption | Thread | Text-only post | Images | Videos | Formats honored |
|---|---|---|---|---|---|---|
| Instagram (`INSTAGRAM`) | 2200 | — | no | 10 | 10 | IMAGE, CAROUSEL, REEL, STORY |
| TikTok (`TIKTOK`) | 2200 | — | no | 35 | 1 | — |
| X (`TWITTER`) | 280 | 25 | yes | 4 | 1 | — |
| Telegram (`TELEGRAM`) | 4096 | 25 | yes | 10 | 10 | — |
| LinkedIn (`LINKEDIN`) | 3000 | — | yes | 20 | 1 | — |
| Threads (`THREADS`) | 500 | 25 | yes | 20 | 20 | — |
| Bluesky (`BLUESKY`) | 300 | 25 | yes | 4 | 1 | — |
| Discord (`DISCORD`) | 2000 | 25 | yes | 10 | 10 | — |
| Mastodon (`MASTODON`) | 500 | 25 | yes | 4 | 1 | — |
| YouTube (`YOUTUBE`) | 5000 | — | no | 0 | 1 | — |
| Pinterest (`PINTEREST`) | 800 | — | no | 5 | 1 | — |
| DEV (`DEVTO`) | 100000 | — | yes | 1 | 0 | — |
| Hashnode (`HASHNODE`) | 100000 | — | yes | 1 | 0 | — |

**A post going to several platforms is limited by the tightest one.** With X in
the selection the budget is 280 characters, whatever else is selected —
or 25,000 when every X account on the post has X Premium
(`list_accounts` gives each account's `captionMax` and `xPremium`). X counts every link as
23 characters and each emoji or symbol such as → − • … as 2. The API rejects an
over-long caption rather than truncating it.

## What each platform accepts

Every rule here is refused **before** a post is written, scheduled or
published, with the reason — never left to fail when the post falls due, after
the other accounts have published. `list_accounts` gives the same sentence
for each account as `accepts`, and `platform_limits` gives the rules as
data (`mediaRules`, `refusesMixedMedia`).

- **Instagram** (`INSTAGRAM`): Needs media: up to 10 images and videos (images: JPEG, PNG, up to 8 MB; video: MP4, MOV, 3 s to 15 min, up to 1 GB). A post with no media is refused.
- **TikTok** (`TIKTOK`): Needs media: up to 35 images or one video (images: JPEG, WebP, up to 20 MB; video: MP4, MOV, WebM, 3 s to 10 min, up to 4 GB). A post with no media is refused.
- **X** (`TWITTER`): Text alone, or with up to 4 images or one video (images: JPEG, PNG, WebP, GIF, up to 5 MB; video: MP4, MOV, 0.5 s to 20 min, up to 8 GB).
- **Telegram** (`TELEGRAM`): Text alone, or with up to 10 images and videos (images: JPEG, PNG, WebP, GIF, up to 10 MB; video: MP4, MOV, WebM, up to 50 MB).
- **LinkedIn** (`LINKEDIN`): Text alone, or with up to 20 images or one video (images: JPEG, PNG, GIF, up to 10 MB; video: MP4, 3 s to 30 min, up to 500 MB).
- **Threads** (`THREADS`): Text alone, or with up to 20 images and videos (images: JPEG, PNG, up to 8 MB; video: MP4, MOV, up to 5 min, up to 1 GB).
- **Bluesky** (`BLUESKY`): Text alone, or with up to 4 images or one video (images: JPEG, PNG, WebP, GIF; video: MP4, MOV, WebM, up to 10 min, up to 286 MB).
- **Discord** (`DISCORD`): Text alone, or with up to 10 images and videos (images: JPEG, PNG, GIF, WebP, up to 25 MB; video: MP4, MOV, WebM, up to 25 MB).
- **Mastodon** (`MASTODON`): Text alone, or with up to 4 images or one video, never both together (images: JPEG, PNG, GIF, WebP, up to 16 MB; video: MP4, WebM, MOV, up to 99 MB).
- **YouTube** (`YOUTUBE`): Video only: one video (MP4, MOV, WebM, 1 s to 12 h, up to 256 GB). A post with photos and no video is refused.
- **Pinterest** (`PINTEREST`): Needs media: up to 5 images or one video (images: JPEG, PNG, WebP, GIF, up to 20 MB; video: MP4, MOV, M4V, at least 4 s, up to 2 GB). A post with no media is refused.
- **DEV** (`DEVTO`): Text alone, or with one image (JPEG, PNG, GIF, WebP). Videos are left out.
- **Hashnode** (`HASHNODE`): Text alone, or with one image (JPEG, PNG, GIF, WebP). Videos are left out.

## What each platform can and cannot do afterwards

| Platform | Deleting from Ravenpost removes the live post | Analytics collected | Reconnect |
|---|---|---|---|
| Instagram (`INSTAGRAM`) | no | yes | automatic |
| TikTok (`TIKTOK`) | no | no | automatic |
| X (`TWITTER`) | yes | no | automatic |
| Telegram (`TELEGRAM`) | yes | no | automatic |
| LinkedIn (`LINKEDIN`) | yes | no | manual, every ~60 days (warned 14 days ahead) |
| Threads (`THREADS`) | no | no | automatic |
| Bluesky (`BLUESKY`) | yes | yes | automatic |
| Discord (`DISCORD`) | yes | no | automatic |
| Mastodon (`MASTODON`) | yes | yes | automatic |
| YouTube (`YOUTUBE`) | no | no | automatic |
| Pinterest (`PINTEREST`) | yes | yes | automatic |
| DEV (`DEVTO`) | yes | yes | automatic |
| Hashnode (`HASHNODE`) | yes | yes | automatic |

Deleting a post in Ravenpost always removes the Ravenpost copy and cancels a
pending publish. It **never** takes down a post already live on Instagram,
Threads, TikTok or YouTube — their APIs expose no delete we hold the scope for —
so say so rather than implying the post is gone from the internet.

## Per-platform requirements a post is refused for

- **Pinterest** needs a board. Set `board` (a name or an id from
  `list_boards`); there is no default, so a post to Pinterest without one can
  only be a draft — scheduling or publishing it is refused. `link` is the
  pin's destination and `title` its headline.
- **Instagram** needs media, and publishes it as the post's `type`. Left out,
  the type follows the media — several files `CAROUSEL`, one video `REEL`,
  one photo `IMAGE` — and a type the media cannot be published as (a video as
  `IMAGE`, a `REEL` of photos, a `STORY` of several files, a `CAROUSEL` of
  one file or more than 10) is refused. Reel audio (`list_audio`) works only
  on accounts connected through Facebook.
- **TikTok** needs media, takes JPEG or WebP photos only — a PNG is
  refused — and carries per-creator posting options (`tiktok`) whose
  defaults publish privately.
- **YouTube** takes one video and nothing else: a post of photos is refused,
  whatever other accounts it goes to.
- **Mastodon** takes up to 4 images or one video, never both together — a
  post carrying both is refused.
- **Discord**: a server connected by bot (`connection` `DISCORD_BOT` in
  `list_accounts`) posts to the channel picked on each post, and no tool here
  can pick one. Save a post for it as a draft and pick the channel on the post
  in Ravenpost; scheduling or publishing it before then is refused. A webhook
  connection names its channel already.
- **Bluesky** takes up to 4 images or one video, never both —
  a video goes alone. Video is rationed per account per day, and an account
  Bluesky hosts needs a verified email address first; a video Bluesky refuses
  fails the post with the reason instead of publishing it without the video.
- **Telegram** renders a markdown subset in captions — `[text](url)`,
  `**bold**`, `*italic*`, backtick code, `~~strike~~` — as native formatting.
  Every other platform publishes the caption as plain text, so markdown belongs
  in a Telegram-only post.
- **X** is the only platform with reply and quote targets (`replyTo`,
  `quote`), and threads are capped at 25 follow-ups of 280 characters.
