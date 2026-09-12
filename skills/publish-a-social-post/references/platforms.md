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
| Bluesky (`BLUESKY`) | 300 | 25 | yes | 4 | 0 | — |
| YouTube (`YOUTUBE`) | 5000 | — | no | 0 | 1 | — |
| Pinterest (`PINTEREST`) | 800 | — | no | 5 | 1 | — |

**A post going to several platforms is limited by the tightest one.** With X in
the selection the budget is 280 characters, whatever else is selected.
The API rejects an over-long caption rather than truncating it.

## What each platform can and cannot do afterwards

| Platform | Deleting from Ravenpost removes the live post | Analytics collected | Reconnect |
|---|---|---|---|
| Instagram (`INSTAGRAM`) | no | yes | automatic |
| TikTok (`TIKTOK`) | no | yes | automatic |
| X (`TWITTER`) | yes | yes | automatic |
| Telegram (`TELEGRAM`) | yes | no | automatic |
| LinkedIn (`LINKEDIN`) | yes | no | manual, every ~60 days (warned 14 days ahead) |
| Threads (`THREADS`) | no | no | automatic |
| Bluesky (`BLUESKY`) | yes | yes | automatic |
| YouTube (`YOUTUBE`) | no | no | automatic |
| Pinterest (`PINTEREST`) | yes | yes | automatic |

Deleting a post in Ravenpost always removes the Ravenpost copy and cancels a
pending publish. It **never** takes down a post already live on Instagram,
Threads, TikTok or YouTube — their APIs expose no delete we hold the scope for —
so say so rather than implying the post is gone from the internet.

## Per-platform requirements a post can fail on

- **Pinterest** needs a board. Pass `board` (a name or an id from
  `list_boards`); there is no default, and without one the post is created and
  then fails to publish. `link` is the pin's destination and `title` its
  headline.
- **Instagram** needs media, and video must be posted as `REEL` or `STORY` —
  an `IMAGE`/`CAROUSEL` post carrying a video is rejected at publish time.
  Reel audio (`list_audio`) works only on accounts connected through Facebook.
- **TikTok** needs media, rejects PNG images (JPEG or WebP only, and it fails
  minutes later rather than at upload), and carries per-creator posting options
  (`tiktok`) whose defaults publish privately.
- **YouTube** takes one video and no images.
- **Bluesky** takes no video at all.
- **Telegram** renders a markdown subset in captions — `[text](url)`,
  `**bold**`, `*italic*`, backtick code, `~~strike~~` — as native formatting.
  Every other platform publishes the caption as plain text, so markdown belongs
  in a Telegram-only post.
- **X** is the only platform with reply and quote targets (`replyTo`,
  `quote`), and threads are capped at 25 follow-ups of 280 characters.
