# Tool reference

Every tool the Ravenpost MCP server exposes, generated from the server's own
registrations. `*` marks a required argument.

**`workspaceId` is optional everywhere it appears and mandatory in practice
once the account has more than one workspace** — the server refuses to guess,
and answers with an error naming them. Call `list_workspaces` first and ask
the user which one.

## `list_workspaces`

**List workspaces** — read-only

List every workspace this account can act in, with its id and the caller's role. Call this FIRST when more than one may exist: every other tool takes an optional workspaceId, and once there are several it becomes required — the connected social accounts, media library, posting queue and analytics are all per workspace. When there is more than one, ASK THE USER which workspace to post to rather than choosing for them.

Takes no arguments.

Returns: `workspaces`

## `list_accounts`

**List connected accounts** — read-only

List the social accounts connected to one workspace (Instagram, TikTok, X, Telegram, LinkedIn, Threads, Bluesky, YouTube and Pinterest; an account connected before its network was withdrawn still lists under its own platform). Returns each account id, platform, username, status and connection. Use an account id as a target when creating a post. Accounts belong to a single workspace, so with several workspaces pass workspaceId (see list_workspaces) — an account id from one workspace is rejected by a post created in another. `connection` is only meaningful for Instagram: "FACEBOOK_LOGIN" accounts were connected through a Facebook Page and are the only ones that can browse and attach reel audio (list_audio); "INSTAGRAM_LOGIN" accounts — the way Instagram connects today — publish normally but cannot use audio.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `accounts`

## `list_posts`

**List posts** — read-only

List recent posts in one workspace, optionally filtered by status (DRAFT, SCHEDULED, PUBLISHING, PUBLISHED, FAILED).

| Argument | Type | Notes |
|---|---|---|
| `status` | `DRAFT` \| `SCHEDULED` \| `PUBLISHING` \| `PUBLISHED` \| `FAILED` | Filter by post status |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `posts`

## `get_post`

**Get a post** — read-only

Get one post by id, including its media, per-account targets and publish status. Clients that render MCP Apps also show it as it looks on each destination platform.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id |

Returns: `post`, `preview`

## `preview_post`

**Preview a post** — read-only

Render a post as each destination platform will show it — WITHOUT creating anything. Nothing is written, scheduled or published; call create_post afterwards with the same arguments to actually post it. Takes the same arguments as create_post (caption, hashtags, accountIds, mediaIds, type, thread, replyTo, quote, audio), and returns the same preview a client with MCP Apps renders as an interactive card, one tab per platform. Use this before create_post whenever the user is composing rather than dictating: it is the cheapest way to show them what goes out, and it reports what would be rejected — a caption over the tightest platform's budget, a platform that requires media when there is none, a thread longer than the strictest limit, audio on a platform with no music API. The character counts it returns are per platform and authoritative: they are the same ones create_post enforces. For Pinterest, pass board (and link/title) too — the preview warns when a Pinterest target has no board, which is the way a Pinterest post most often fails.

| Argument | Type | Notes |
|---|---|---|
| `caption`* | string | The post caption / text body |
| `accountIds`* | array of string | Target social account ids (from list_accounts) |
| `hashtags` | array of string | Hashtags to append to the caption (with or without a leading #) |
| `thread` | array of string | Follow-up posts, previewed as the reply chain they publish as |
| `mediaIds` | array of string | Ordered media asset ids (from upload_media / list_media) |
| `type` | `IMAGE` \| `CAROUSEL` \| `REEL` \| `STORY` | Instagram format; defaults to IMAGE |
| `replyTo` | string | X reply: tweet id or URL the head post replies to |
| `quote` | string | X quote: tweet id or URL to embed as a card |
| `audio` | object | Instagram reel track, for the preview caption line |
| `link` | string | Facebook link card / Pinterest pin destination URL |
| `board` | string | Pinterest board name or id — pass it so the preview does not warn about a board you already picked |
| `title` | string | Pinterest pin title |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `postId`, `status`, `type`, `scheduledAt`, `publishedAt`, `media`, `thread`, `audio`, `pinTitle`, `linkUrl`, `replyToTweetId`, `quoteTweetId`, `targets`, `warnings`

## `create_post`

**Create a post** — writes · destructive · reaches the live platforms

Create a post and either publish it now, schedule it, queue it, or save it as a draft. With more than one workspace, ASK THE USER which one to post to and pass workspaceId — the connected accounts differ per workspace and posting to the wrong one is not undoable. Accounts, media and queue slots must all come from that same workspace. action="queue" schedules at the workspace's next free posting-queue slot (see list_queue_slots) — no scheduledAt needed; it errors if the workspace has no slots defined. Targets are account ids from list_accounts (cross-posting to several is allowed). Caption limit is the tightest selected platform (e.g. X = 280 chars). For media, first upload with upload_media and pass the returned media ids. type is Instagram’s format model (IMAGE/CAROUSEL/REEL/STORY) reused as the shared vocabulary. Instagram honors all four, and Instagram video must be posted as REEL (or STORY) — an IMAGE/CAROUSEL post with a video will be rejected at publish time. Facebook honors STORY (published to Page Stories, which have NO caption — the text is dropped) and treats every other type as a normal feed post. TikTok, X, and Telegram ignore type entirely. See platform_limits.formats for which types each platform honors. thread: extra posts published as replies after the main one, forming a chain. Supported on X, Bluesky, Mastodon, Threads, Telegram and Discord; a platform without a thread model publishes just the caption. The caption is post 1 and carries the media. Limits come from the strictest selected platform (X is tightest at 280 chars per post, 25 follow-ups) and going over is rejected, not truncated. replyTo (X only): reply to an existing tweet — pass the tweet id or its URL (x.com/<user>/status/<id>) and the post is published as a reply under it instead of a standalone tweet (a thread then continues under that reply). Non-X targets ignore it and publish a normal post, so for a pure reply target only the X account. quote (X only): quote-tweet an existing tweet — pass the tweet id or its URL and it is embedded as a card under this post. Can be combined with replyTo (X allows replying and quoting in the same tweet). Non-X targets ignore it. Telegram renders a markdown subset in captions ([text](url) links, **bold**, *italic*, `code`, ~~strikethrough~~) as native formatting; every other platform publishes the caption as plain text, so markdown would show literally there — only use it when all targets are Telegram (see platform_limits.captionFormatting). Threads takes text-only posts, one image/video, or a carousel of up to 20 items, and ignores type. Its 500-character limit is the tightest after X, so a mixed X+Threads selection is still capped at 280. LinkedIn publishes the caption as plain text — its reserved characters are escaped for you, so write normal prose; markdown is not rendered and a bare link does NOT produce a preview card. LinkedIn ignores type, allows text-only posts, and takes either one video or up to 20 images. audio attaches a track from Instagram’s catalog to a reel (find one with list_audio). It applies only to type="REEL" on Instagram accounts connected via Facebook — other platforms and other types ignore it, and the worker logs that it was dropped rather than failing. TikTok and Facebook have NO music API at all: for them the audio has to already be part of the video file. tiktok carries TikTok’s required per-post choices, keyed by account id — most importantly privacyLevel, which TikTok makes mandatory. Leave it out and TikTok targets publish privately. Pinterest needs a board: pass `board` (a board name or an id from list_boards) whenever a Pinterest account is targeted — a pin belongs to a board and there is no default, so without it the post is created but fails to publish. `link` is the pin’s destination URL, which is the point of a pin, and `title` is its headline (the caption becomes the description, max 800 chars).

| Argument | Type | Notes |
|---|---|---|
| `caption`* | string | The post caption / text body |
| `accountIds`* | array of string | Target social account ids (from list_accounts) |
| `hashtags` | array of string | Hashtags to append to the caption (with or without a leading #) |
| `thread` | array of string | Thread: follow-up posts replied in order after the caption (X, Bluesky, Mastodon, Threads, Telegram, Discord; limits come from the strictest selected platform — at most 25 entries, each ≤280 chars on X) |
| `collaborators` | array of string | Instagram only: co-author usernames (max 3). They get an invite and the post appears on their profile too. Feed posts and reels only — not stories — and only for accounts connected through Facebook Login. |
| `link` | string | The URL this post points at. Facebook publishes it as a link preview card (used when the post has no media); Pinterest makes it the pin's destination, which is the whole point of a pin. Every other platform ignores it. Empty string clears it. |
| `replySettings` | `following` \| `mentionedUsers` \| `subscribers` \| `verified` | X only: who may reply to this post. Omit for X's default (everyone). |
| `community` | string | X only: post into a Community — its id or URL (x.com/i/communities/<id>). Empty string clears it. |
| `replyTo` | string | X reply: tweet id or tweet URL to reply to — the post publishes as a reply under that tweet instead of a standalone tweet (X targets only; other platforms ignore it) |
| `quote` | string | X quote: tweet id or tweet URL to quote — embedded as a card under this post; combinable with replyTo (X targets only; other platforms ignore it) |
| `audio` | object | Instagram reel audio — a catalog track from list_audio. Requires type="REEL" and an Instagram account connected via Facebook; ignored otherwise. |
| `board` | string | Pinterest only, and REQUIRED for a Pinterest target: the board this pin goes to — its name (matched case-insensitively) or its id from list_boards. Pinterest has no default board, so a Pinterest post without one fails at publish time. Other platforms ignore it. |
| `title` | string | Pinterest only: the pin title (max 100 chars), which Pinterest shows above the description. Defaults to the caption’s first line. Other platforms ignore it. |
| `tiktok` | object | TikTok posting options, keyed by TikTok account id. Omit and TikTok targets publish privately (SELF_ONLY) — TikTok requires the creator to choose a visibility per post, so nothing wider is assumed on their behalf. |
| `type` | `IMAGE` \| `CAROUSEL` \| `REEL` \| `STORY` | Instagram format; defaults to IMAGE |
| `mediaIds` | array of string | Ordered media asset ids (from upload_media) |
| `action`* | `now` \| `schedule` \| `queue` \| `draft` | Publish immediately, schedule for later, queue at the next free posting-queue slot, or save as draft |
| `scheduledAt` | string | ISO 8601 datetime — required when action is "schedule" |
| `timezone` | string | IANA timezone for the schedule |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `post`, `preview`

## `update_post`

**Edit a post** — writes · destructive · reaches the live platforms

Edit an existing post (draft or scheduled) — caption, hashtags, format, media or target accounts. A published/publishing post can no longer be edited. IMPORTANT: editing resets the post to a DRAFT. To keep it going out, also pass action="schedule" + scheduledAt (or action="now" to publish immediately). Omit action to leave it as a draft (i.e. to unschedule). caption replaces the whole caption; pass hashtags to append them. Telegram targets render a markdown subset in the caption ([text](url), **bold**, *italic*, `code`, ~~strikethrough~~); other platforms publish it as plain text. audio replaces the Instagram reel track (see list_audio); pass null to remove it. tiktok replaces TikTok’s per-account posting options (privacyLevel, allow*, brand toggles); pass {} to clear them, which makes TikTok targets publish privately again. board moves a Pinterest pin to another board (name or id from list_boards); title replaces the pin title.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id (from list_posts / create_post) |
| `caption` | string | New caption (replaces the existing one) |
| `hashtags` | array of string | Hashtags to append to the caption |
| `type` | `IMAGE` \| `CAROUSEL` \| `REEL` \| `STORY` | Instagram format |
| `thread` | array of string | Replace the thread (follow-up posts; limits come from the strictest selected platform — at most 25 entries, each ≤280 chars on X. Pass [] to remove the thread) |
| `replyTo` | string | Replace the X reply target (tweet id or tweet URL; pass "" to make it a standalone tweet again) |
| `quote` | string | Replace the X quoted tweet (tweet id or tweet URL; pass "" to remove the quote) |
| `audio` | object | Instagram reel audio — a catalog track from list_audio. Requires type="REEL" and an Instagram account connected via Facebook; ignored otherwise. |
| `tiktok` | object | TikTok posting options, keyed by TikTok account id. Omit and TikTok targets publish privately (SELF_ONLY) — TikTok requires the creator to choose a visibility per post, so nothing wider is assumed on their behalf. |
| `board` | string | Pinterest only: move the pin to another board — its name (matched case-insensitively) or an id from list_boards. Applied to every Pinterest target on the post. |
| `title` | string | Pinterest only: replace the pin title (max 100 chars); pass "" to fall back to the caption’s first line. |
| `mediaIds` | array of string | Replace the media set (ordered asset ids) |
| `accountIds` | array of string | Replace the target accounts |
| `action` | `now` \| `schedule` \| `queue` \| `draft` | now = publish, schedule = re-schedule (needs scheduledAt), queue = next free posting-queue slot, draft = keep as draft |
| `scheduledAt` | string | ISO 8601 datetime — required when action is "schedule" |
| `timezone` | string | IANA timezone for the schedule |

Returns: `ok`, `post`, `preview`

## `delete_post`

**Delete a post** — writes · destructive

Delete Ravenpost’s copy of a post and cancel any scheduled publish. Use this to remove drafts or duplicate/obsolete scheduled posts. It never takes a post down from a network: a post already published stays live on the platform. The dashboard offers a separate "delete everywhere" where the platform’s API allows it (Instagram, TikTok, Threads and YouTube expose no delete endpoint at all); this tool does not.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id to delete |

Returns: `ok`, `deleted`

## `schedule_post`

**Schedule a post** — writes · destructive

Schedule (or reschedule) an existing post for a future time, without editing its content. Pass scheduledAt as an absolute ISO 8601 datetime (include the offset, e.g. 2026-07-05T09:00:00+03:00).

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id |
| `scheduledAt`* | string | ISO 8601 datetime to publish at (include timezone offset) |

Returns: `ok`, `post`

## `publish_post`

**Publish a post now** — writes · destructive · reaches the live platforms

Publish an existing post immediately (e.g. a draft), without editing its content.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id to publish now |

Returns: `ok`, `post`, `preview`

## `upload_media`

**Upload media** — writes

Upload an image or a video (mp4/mov/webm) to the media library, returning a media id for create_post. Images are reformatted to the requested publishing format; videos are stored as-is (format/fit are ignored — upload the video pre-edited). Give the file as ONE of: url (preferred when it is already online), path (an absolute local file path — local dev only, the server reads it from disk, no base64), or base64 (fallback for small images; avoid for video). For a large local file in production, prefer create_media_upload (direct upload, no base64 through this channel). format: feed_square (1:1), feed_portrait (4:5), landscape (1.91:1), story or reel (9:16), or original (no resize). fit: "cover" crops to fill (default), "contain" fits the whole image and pads.

| Argument | Type | Notes |
|---|---|---|
| `url` | string | Public URL to fetch the file from (preferred if already online) |
| `path` | string | Absolute local file path — local dev only; the server reads it directly (no base64) |
| `base64` | string | Base64 file bytes (data URI ok) — fallback for small images; avoid for video |
| `format`* | `feed_square` \| `feed_portrait` \| `landscape` \| `story` \| `reel` \| `original` | Target format / aspect ratio (images only — videos are stored as-is) |
| `fit` | `cover` \| `contain` | cover = crop to fill (default), contain = fit + pad |
| `crop` | `smart` \| `centre` | How a 'cover' crop chooses what to keep: 'smart' = saliency-based, keeps the subject (default); 'centre' = predictable middle crop, better for posters/screenshots |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `media`, `note`

## `create_media_upload`

**Start a direct media upload** — writes

Get a presigned URL to upload a file straight to storage — no base64 through this channel, no third-party host. Best for large files and production. Flow: (1) call this with the contentType; (2) HTTP PUT the raw file bytes to the returned uploadUrl (e.g. `curl -X PUT --data-binary @file -H "Content-Type: <type>" "<uploadUrl>"`); (3) call attach_media with the returned storageKey to save it to the media library.

| Argument | Type | Notes |
|---|---|---|
| `contentType`* | string | MIME type of the file, e.g. image/jpeg, image/png, video/mp4 |
| `filename` | string | Original filename (for a nicer storage key) |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `uploadUrl`, `storageKey`, `expiresInSec`, `next`

## `attach_media`

**Attach an uploaded file** — writes · destructive

Save an already-uploaded object (from create_media_upload) to the media library and return a media id. Works for images and videos (mp4/mov/webm). Images can optionally be reformatted to a publishing format first (the server reads it back from storage, reformats, and stores the result); videos are always recorded as-is. Omit format (or use "original") to record it unchanged. Pass the SAME workspaceId you gave create_media_upload — a storage key belongs to the workspace it was minted in and is refused anywhere else.

| Argument | Type | Notes |
|---|---|---|
| `storageKey`* | string | The storageKey returned by create_media_upload |
| `format` | `feed_square` \| `feed_portrait` \| `landscape` \| `story` \| `reel` \| `original` | Reformat to this before saving; omit to keep original |
| `fit` | `cover` \| `contain` | cover = crop to fill (default), contain = fit + pad |
| `crop` | `smart` \| `centre` | How a 'cover' crop chooses what to keep: 'smart' = saliency-based, keeps the subject (default); 'centre' = predictable middle crop, better for posters/screenshots |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `media`, `note`

## `list_media`

**List media** — read-only

List recent media assets in one workspace (id, url, type, dimensions) — reuse an existing asset id in create_post instead of re-uploading. The library is per workspace, like the accounts.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `media`

## `image_formats`

**List image formats** — read-only

List the supported image formats and their target dimensions (for choosing a format in upload_media).

Takes no arguments.

Returns: `formats`

## `create_variants`

**Resize an image for other platforms** — writes

Reshape ONE image already in the media library into several platform canvases at once, and return the new asset ids: feed_portrait (1080×1350, 4:5), feed_square (1080×1080), landscape (1080×566, 1.91:1) and story (1080×1920, 9:16 — also what a reel or a TikTok photo wants). Cropping is saliency-based by default: sharp scores regions by saturation, luminance and skin tone and keeps the strongest, so an off-centre subject survives a 4:5 → 9:16 cut. Pass crop="centre" for images composed around their middle (posters, screenshots, flat graphics), where a predictable crop beats a guessed one. fit="contain" pads instead of cropping — use it when nothing may be cut off at all. Images only; video is not re-encoded. Variants inherit the source’s alt text and folder, and asking for two formats with the same dimensions produces one file, not two. Typical use: upload once, call this with the formats the selected platforms want, then pass the right variant id per post.

| Argument | Type | Notes |
|---|---|---|
| `mediaId`* | string | Source image asset id (from list_media or upload_media) |
| `formats`* | array of `feed_portrait` \| `feed_square` \| `landscape` \| `story` | Canvases to produce |
| `fit` | `cover` \| `contain` | 'cover' crops to fill (default); 'contain' pads to fit |
| `crop` | `smart` \| `centre` | 'smart' = saliency-based (default); 'centre' = predictable middle crop |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `sourceId`, `variants`

## `get_analytics`

**Get analytics** — read-only

Get one workspace's analytics overview: follower counts per connected account (plus a daily follower series for the last 30 days) and engagement on recent posts. A post's `source` says where it came from: "ravenpost" for one published from here, "platform" for one already on the account and imported so its engagement counts too. An account's `followers` is null when that platform reports none — Telegram, LinkedIn, Threads and YouTube expose no insights through their APIs, and TikTok's need a scope that is not approved yet — so null means "unknown", never zero. Likewise a post metric that is absent was not collected rather than being 0.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `totalFollowers`, `trackedPosts`, `collectedAt`, `refreshing`, `accounts`, `posts`

## `list_audio`

**Search reel audio** — read-only

Search Instagram’s audio catalog for tracks that can be attached to a reel, then pass the chosen track’s id as create_post/update_post `audio.audioId`. Call it WITHOUT a query to get what is currently trending — that is the featured list. accountId must be an Instagram account connected through Facebook; a directly-connected Instagram account cannot reach the catalog and returns an error explaining how to fix it. Meta only exposes tracks licensed for third-party use, so this catalog is narrower than the one in the Instagram app — a track the user can pick on their phone may legitimately be missing here. This is Instagram-only. TikTok and Facebook expose no music API, so there is nothing to list for them.

| Argument | Type | Notes |
|---|---|---|
| `accountId`* | string | Instagram account id (from list_accounts) to search on behalf of |
| `query` | string | Search text (song or artist). Omit to get trending tracks. |
| `kind` | `music` \| `original_sound` | 'music' = licensed catalog track (default); 'original_sound' = audio lifted from another creator's reel |
| `limit` | number | Max tracks to return (default 25) |

Returns: `tracks`

## `best_times`

**Find the best times to post** — read-only

Recommended posting hours for one workspace, measured from its own published posts and the engagement collected against them — never from a generic industry heatmap. Each workspace is measured separately, so ask for the one you are about to post to. Returns `overall` plus one report per platform. Each has `slots` (weekday 0 = Sunday … 6 = Saturday, `minutes` from local midnight, in the workspace timezone) ordered strongest first, a 7×24 `grid` for a heatmap, and `score`, where 1.0 = a typical post for that account. IMPORTANT: when `insufficient` is true there is no answer and `slots` is empty — that means "unknown", NOT "no good time". Say so rather than picking an hour anyway. `reason` says which wall it hit, and they need different answers: "few_posts" and "few_samples" are fixed by publishing more (`observations` vs `minObservations` says how far off), but "low_engagement" means the posts earn too few interactions for any hour to be distinguishable and "not_collected" means the platform reports no per-post engagement at all — for those two, more posting changes nothing and saying "not enough data yet" is misleading. Use a slot to fill scheduled_at on schedule_post/create_post, and prefer a platform-specific report over `overall` when posting to one platform.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `overall`, `byPlatform`

## `list_queue_slots`

**List posting queue slots** — read-only

List the workspace posting schedule: the recurring weekly queue slots (weekday + local time) that action="queue" publishes into, plus the next few free occurrences. Slots are defined in dashboard Settings and are workspace-wide (shared by every connected account), so each workspace has its own schedule. weekday 0 = Sunday … 6 = Saturday, in the workspace timezone.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `slots`, `nextFreeSlot`

## `list_boards`

**List Pinterest boards** — read-only

List the boards on a connected Pinterest account. Every pin belongs to a board and Pinterest has no default, so a post targeting Pinterest must name one — pass the board name or id as `board` on create_post/update_post. accountId is a Pinterest account id from list_accounts; other platforms have no boards and are rejected.

| Argument | Type | Notes |
|---|---|---|
| `accountId`* | string | A Pinterest account id from list_accounts |

Returns: `boards`

## `platform_limits`

**Get platform limits** — read-only

Return per-platform caption limits, media rules, thread limits, and recommended media specs (dimensions, container formats, size/duration caps). Consult this BEFORE generating or picking media for a post so images/videos match what the platform renders best (e.g. X images at 1600×900 16:9, X video as MP4 H.264 ≤140s). threadMax is the max follow-up posts a thread can carry after the caption; null means the platform has no thread model. captionFormatting describes the rich-text markup the platform renders in captions (e.g. Telegram accepts a markdown subset); null means captions publish as plain text. formats lists the post.type values the platform honors; null means it ignores type and just consumes the media set. supportsAudio means a track from the platform’s own catalog can be attached through the API (see list_audio) — only Instagram reels can. For every other platform the audio must already be baked into the video file.

Takes no arguments.

Returns: `platforms`

