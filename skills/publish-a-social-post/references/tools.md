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

List the social accounts connected to one workspace (Instagram, TikTok, X, Telegram, LinkedIn, Threads, Bluesky, YouTube and Pinterest; an account connected before its network was withdrawn still lists under its own platform). Returns each account id, platform, username, status, connection and captionMax — that account's own caption budget, which create_post holds its caption to. For X it depends on the account: `xPremium` true means X Premium and 25,000 characters, false means 280; X counts every link as 23 and each emoji or symbol such as → − • … as 2. Use an account id as a target when creating a post. Accounts belong to a single workspace, so with several workspaces give workspaceId (see list_workspaces) — an account id from one workspace is rejected by a post created in another. `connection` is only meaningful for Instagram: "FACEBOOK_LOGIN" accounts were connected through a Facebook Page and are the only ones that can browse and attach reel audio (list_audio) or invite collaborators; "INSTAGRAM_LOGIN" accounts — the way Instagram connects today — publish normally but can do neither.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `accounts`

## `list_posts`

**List posts** — read-only

List the posts in one workspace, 50 at a time: newest first, or soonest first when filtered to SCHEDULED. Optionally filtered by status (DRAFT, SCHEDULED, PUBLISHING, PUBLISHED, FAILED). `total` says how many posts match and `totalPages` how many pages there are; set `page` to read further back.

| Argument | Type | Notes |
|---|---|---|
| `status` | `DRAFT` \| `SCHEDULED` \| `PUBLISHING` \| `PUBLISHED` \| `FAILED` | Filter by post status |
| `page` | integer | Page to read, from 1 (the default); 50 posts a page |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `posts`, `total`, `page`, `totalPages`

## `get_post`

**Get a post** — read-only

Get one post by id, including its media, per-account targets and publish status. Clients that render MCP Apps also show it as it looks on each destination platform.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id |

Returns: `post`, `preview`

## `preview_post`

**Preview a post** — read-only

Render a post as each destination platform will show it — WITHOUT creating anything. Nothing is written, scheduled or published; call create_post afterwards with the same arguments to actually post it. Takes the same arguments as create_post (caption, hashtags, accountIds, mediaIds, type, thread, replyTo, quote, audio, collaborators, reelCover, trialReel), and returns the same preview a client with MCP Apps renders as an interactive card, one tab per platform. Use this before create_post whenever the user is composing rather than dictating: it is the cheapest way to show them what goes out, and it reports what would be rejected or silently dropped — a caption over the tightest platform's budget, a platform that requires media when there is none, a thread longer than the strictest limit, audio on a platform with no music API, Instagram collaborators on an account that cannot invite them, a reel cover or trial on a post that is not a reel (or a cover create_post would refuse), media Bluesky leaves behind (it takes up to four images or one video), and X's own rules — more than one $cashtag in a post, a thread reply @mentioning somebody new to the conversation, the same post on two X accounts, a reply or quote X only takes from an account the target post names, media X leaves behind. The character counts it returns are per platform and authoritative: they are the same ones create_post enforces. For Pinterest, include board (and link/title) too — the preview warns when a Pinterest target has no board, which is the way a Pinterest post most often fails. The board name is taken as given: create_post checks it against the account's boards (see list_boards) and refuses an unknown one before writing anything. A preview reads only this workspace's own accounts and media and calls no social network, so nothing outside Ravenpost is touched or shown to anyone.

| Argument | Type | Notes |
|---|---|---|
| `caption`* | string | The post caption / text body |
| `accountIds`* | array of string | Target social account ids (from list_accounts) |
| `hashtags` | array of string | Hashtags to append to the caption (with or without a leading #) |
| `thread` | array of string | Follow-up posts, previewed as the reply chain they publish as |
| `mediaIds` | array of string | Ordered media asset ids (from upload_media / list_media) |
| `type` | `IMAGE` \| `CAROUSEL` \| `REEL` \| `STORY` | Instagram format; defaults to IMAGE |
| `replyTo` | string | X reply: tweet id or URL the head post replies to — X only takes it when that post is the account's own or @mentions it |
| `quote` | string | X quote: tweet id or URL to embed as a card — X only takes it when that post is the account's own or @mentions it |
| `audio` | object | Instagram reel track, for the preview caption line |
| `collaborators` | array of string | Instagram co-author usernames, as you would pass them to create_post. Nothing in the card draws them — pass them so the preview can warn when the targeted Instagram accounts cannot invite them and they would be dropped. |
| `reelCover` | object | Instagram reel cover, as you would pass it to create_post — checked against the media library the way create_post checks it, and drawn on the card. |
| `trialReel` | `MANUAL` \| `SS_PERFORMANCE` | Instagram trial reel graduation, as you would pass it to create_post. |
| `link` | string | Facebook link card / Pinterest pin destination URL |
| `board` | string | Pinterest board name or id — pass it so the preview does not warn about a board you already picked |
| `title` | string | Pinterest pin title |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `postId`, `status`, `type`, `scheduledAt`, `publishedAt`, `media`, `thread`, `audio`, `reelCover`, `trialReel`, `pinTitle`, `linkUrl`, `replyToTweetId`, `quoteTweetId`, `targets`, `warnings`

## `create_post`

**Create a post** — writes · destructive · reaches outside Ravenpost

Create a post and either publish it now, schedule it, queue it, or save it as a draft. Publishing — now, or when a scheduled or queued time arrives — makes the post public on the selected networks, and it cannot be undone from here: delete_post removes only Ravenpost's copy, and a post on Instagram, TikTok, Threads and YouTube cannot be taken down through Ravenpost at all. Only a draft stays private. Each call creates a new post, so never repeat a call that succeeded. With more than one workspace, ASK THE USER which one to post to and give workspaceId — the connected accounts differ per workspace and posting to the wrong one is not undoable. Accounts, media and queue slots must all come from that same workspace. action="queue" schedules at the workspace's next free posting-queue slot (see list_queue_slots) — no scheduledAt needed; it errors if the workspace has no slots defined. Targets are account ids from list_accounts (cross-posting to several is allowed — but one X account per post: every X account publishes the same text, and X forbids the same post on several accounts). Caption limit is the tightest selected account — each account's captionMax in list_accounts. X's depends on the account: 280 characters, or 25,000 with X Premium, counted as X counts (every link is 23, each emoji or symbol such as → − • … is 2); a caption over it is rejected, naming the account. X refuses two more things a caption can hold, and so does this tool, before anything is written: more than one $cashtag in a post (each reply of a thread is a post of its own — write other tickers without the $), and, in a thread reply, an @mention of anybody the first post did not mention. For media, first upload with upload_media and pass the returned media ids. type is Instagram’s format model (IMAGE/CAROUSEL/REEL/STORY) reused as the shared vocabulary. Instagram honors all four, and Instagram video must be posted as REEL (or STORY) — an IMAGE/CAROUSEL post with a video will be rejected at publish time. Facebook honors STORY (published to Page Stories, which have NO caption — the text is dropped) and treats every other type as a normal feed post. TikTok, X, and Telegram ignore type entirely. See platform_limits.formats for which types each platform honors. thread: extra posts published as replies after the main one, forming a chain. Supported on X, Bluesky, Mastodon, Threads, Telegram and Discord; a platform without a thread model publishes just the caption. The caption is post 1 and carries the media. Limits come from the strictest selected platform (X is tightest at 280 chars per post, or 25,000 for an account on X Premium, and 25 follow-ups) and going over is rejected, not truncated. replyTo (X only): reply to an existing tweet — pass the tweet id or its URL (x.com/<user>/status/<id>) and the post is published as a reply under it instead of a standalone tweet (a thread then continues under that reply). X takes a reply from an app only when the post it answers is the account's own, or @mentions the account, or quotes one of its posts; a reply to anybody else's post fails at publish time. Non-X targets ignore it and publish a normal post, so for a pure reply target only the X account. quote (X only): quote-tweet an existing tweet — pass the tweet id or its URL and it is embedded as a card under this post. X takes it on the same terms as a reply: the account's own post, or one that @mentions it — quoting anybody else's post fails at publish time. Can be combined with replyTo. Non-X targets ignore it. Telegram renders a markdown subset in captions ([text](url) links, **bold**, *italic*, `code`, ~~strikethrough~~) as native formatting; every other platform publishes the caption as plain text, so markdown would show literally there — only use it when all targets are Telegram (see platform_limits.captionFormatting). Threads takes text-only posts, one image/video, or a carousel of up to 20 items, and ignores type. Its 500-character limit is the tightest after X, so a mixed X+Threads selection is still capped at 280 (unless the X account has X Premium). LinkedIn publishes the caption as plain text — its reserved characters are escaped for you, so write normal prose; markdown is not rendered and a bare link does NOT produce a preview card. LinkedIn ignores type, allows text-only posts, and takes either one video or up to 20 images. audio attaches a track from Instagram’s catalog to a reel (find one with list_audio). It applies only to type="REEL" on Instagram accounts connected via Facebook — other platforms and other types ignore it, and the worker logs that it was dropped rather than failing. TikTok and Facebook have NO music API at all: for them the audio has to already be part of the video file. reelCover and trialReel are an Instagram reel’s own options: its cover (a library JPEG, or a frame of the video) and a trial — a reel shown to non-followers first. Both apply only to type="REEL" on Instagram, on either connection; anywhere else they are dropped. tiktok carries TikTok’s required per-post choices, keyed by account id — most importantly privacyLevel, which TikTok makes mandatory. Leave it out and TikTok targets publish privately. Pinterest needs a board: set `board` (a board name or an id from list_boards) whenever a Pinterest account is targeted — a pin belongs to a board and there is no default, so without it the post is created but fails to publish. `link` is the pin’s destination URL, which is the point of a pin, and `title` is its headline (the caption becomes the description, max 800 chars).

| Argument | Type | Notes |
|---|---|---|
| `caption`* | string | The post caption / text body |
| `accountIds`* | array of string | Target social account ids (from list_accounts) |
| `hashtags` | array of string | Hashtags to append to the caption (with or without a leading #) |
| `thread` | array of string | Thread: follow-up posts replied in order after the caption (X, Bluesky, Mastodon, Threads, Telegram, Discord; limits come from the strictest selected platform — at most 25 entries, each ≤280 chars on X, or 25,000 on X Premium) |
| `collaborators` | array of string | Instagram only: co-author usernames (max 3). They get an invite, and once they accept the post appears on their profile too. Feed posts and reels only — never a STORY — and ONLY on an Instagram account whose connection is "FACEBOOK_LOGIN" (see list_accounts). On any other Instagram account they are dropped: the post still publishes, without them, and nothing reports it afterwards — so do not promise the user co-authors without checking. preview_post takes the same argument and warns when they would be dropped. |
| `link` | string | The URL this post points at. Facebook publishes it as a link preview card (used when the post has no media); Pinterest makes it the pin's destination, which is the whole point of a pin. Every other platform ignores it. Empty string clears it. |
| `replySettings` | `following` \| `mentionedUsers` \| `subscribers` \| `verified` | X only: who may reply to this post. Omit for X's default (everyone). |
| `community` | string | X only: post into a Community — its id or URL (x.com/i/communities/<id>). Empty string clears it. |
| `replyTo` | string | X reply: tweet id or tweet URL to reply to — the post publishes as a reply under that tweet instead of a standalone tweet. X only takes it when that post is the account's own or @mentions it (X targets only; other platforms ignore it) |
| `quote` | string | X quote: tweet id or tweet URL to quote — embedded as a card under this post; combinable with replyTo. X only takes it when that post is the account's own or @mentions it (X targets only; other platforms ignore it) |
| `audio` | object | Instagram reel audio — a catalog track from list_audio. Requires type="REEL" and an Instagram account connected via Facebook; ignored otherwise. |
| `reelCover` | object | Instagram reel cover — an image OR a frame of the video, not both. Only for type="REEL" on an Instagram account, either connection; other types and platforms ignore it and it is dropped there. Leave it out for Instagram’s default, the first frame. |
| `trialReel` | `MANUAL` \| `SS_PERFORMANCE` | Instagram trial reel: shown to non-followers first, and to followers only once it graduates — MANUAL means the user graduates it by hand in the Instagram app, SS_PERFORMANCE that Instagram graduates it if it performs well. Only for type="REEL" on an Instagram account; other types and platforms ignore it. Instagram decides which accounts may post one (public professional accounts it can recommend) and answers only when the reel is published: if it refuses, the post fails — it is never sent as a normal reel instead. Set it only when the user asks for a trial. |
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

**Edit a post** — writes · destructive · reaches outside Ravenpost

Edit an existing post (draft or scheduled) — caption, hashtags, format, media or target accounts. A published/publishing post can no longer be edited. IMPORTANT: editing resets the post to a DRAFT. To keep it going out, also send action="schedule" + scheduledAt (or action="now" to publish immediately). Omit action to leave it as a draft (i.e. to unschedule). The edit overwrites the stored post — no earlier version is kept — and with action now, schedule or queue the result goes public on its networks, now or at that time. The schedule is the only thing an edit drops on its own: anything else you leave out stays exactly as it was, so to REMOVE something pass its empty form ("", [], null or {} — each argument says which) rather than leaving it out. tiktok and board belong to specific accounts, so when accountIds adds a TikTok or Pinterest account, pass them again for it — a new TikTok target without options publishes privately, and a new Pinterest target without a board fails to publish. caption replaces the whole caption; use hashtags to append them. Telegram targets render a markdown subset in the caption ([text](url), **bold**, *italic*, `code`, ~~strikethrough~~); other platforms publish it as plain text. replySettings (who may reply) and community (the Community it posts into) are X only, like replyTo and quote; use "" to either to go back to X’s default — everyone may reply, and the post goes to the timeline. audio replaces the Instagram reel track (see list_audio); use null to remove it. reelCover replaces the Instagram reel cover; use null to go back to the first frame. trialReel changes how a trial reel graduates; use "" to make it a normal reel. collaborators replaces the Instagram co-authors; use [] to remove them. They reach only an Instagram account whose connection is "FACEBOOK_LOGIN" (see list_accounts) and never a STORY — anywhere else they are dropped and the post publishes without them. tiktok replaces TikTok’s per-account posting options (privacyLevel, allow*, brand toggles); use {} to clear them, which makes TikTok targets publish privately again. board moves a Pinterest pin to another board (name or id from list_boards); title replaces the pin title. link replaces the URL the post points at — Facebook’s link preview card, Pinterest’s pin destination; use "" to remove it.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id (from list_posts / create_post) |
| `caption` | string | New caption (replaces the existing one) |
| `hashtags` | array of string | Hashtags to append to the caption |
| `type` | `IMAGE` \| `CAROUSEL` \| `REEL` \| `STORY` | Instagram format |
| `thread` | array of string | Replace the thread (follow-up posts; limits come from the strictest selected platform — at most 25 entries, each ≤280 chars on X, or 25,000 on X Premium. Use [] to remove the thread) |
| `replyTo` | string | Replace the X reply target (tweet id or tweet URL; use "" to make it a standalone tweet again). X only takes a reply to the account's own post or one that @mentions it |
| `quote` | string | Replace the X quoted tweet (tweet id or tweet URL; use "" to remove the quote). X only takes a quote of the account's own post or one that @mentions it |
| `replySettings` | `following` \| `mentionedUsers` \| `subscribers` \| `verified` \| `""` | X only: replace who may reply to this post. Use "" to go back to X's default (everyone). |
| `community` | string | X only: replace the Community this posts into — its id or URL (x.com/i/communities/<id>). Use "" to post to the timeline again. |
| `audio` | object \| null | Instagram reel audio — a catalog track from list_audio. Requires type="REEL" and an Instagram account connected via Facebook; ignored otherwise. Use null to remove the track. |
| `reelCover` | object \| null | Instagram reel cover — an image OR a frame of the video, not both. Only for type="REEL" on an Instagram account, either connection; other types and platforms ignore it and it is dropped there. Leave it out for Instagram’s default, the first frame. Use null to go back to the first frame. |
| `trialReel` | `MANUAL` \| `SS_PERFORMANCE` \| `""` | Instagram trial reel: shown to non-followers first, and to followers only once it graduates — MANUAL means the user graduates it by hand in the Instagram app, SS_PERFORMANCE that Instagram graduates it if it performs well. Only for type="REEL" on an Instagram account; other types and platforms ignore it. Instagram decides which accounts may post one (public professional accounts it can recommend) and answers only when the reel is published: if it refuses, the post fails — it is never sent as a normal reel instead. Set it only when the user asks for a trial. Use "" to make it a normal reel again. |
| `collaborators` | array of string | Instagram only: replace the co-author usernames (max 3); use [] to remove them. They get an invite, and once they accept the post appears on their profile too. Feed posts and reels only — never a STORY — and ONLY on an Instagram account whose connection is "FACEBOOK_LOGIN" (see list_accounts). On any other Instagram account they are dropped: the post still publishes, without them, and nothing reports it afterwards — so check the connection before promising the user co-authors. |
| `tiktok` | object | TikTok posting options, keyed by TikTok account id. Omit and TikTok targets publish privately (SELF_ONLY) — TikTok requires the creator to choose a visibility per post, so nothing wider is assumed on their behalf. |
| `board` | string | Pinterest only: move the pin to another board — its name (matched case-insensitively) or an id from list_boards. Applied to every Pinterest target on the post. |
| `title` | string | Pinterest only: replace the pin title (max 100 chars); use "" to fall back to the caption’s first line. |
| `link` | string | Replace the URL this post points at. Facebook publishes it as a link preview card (used when the post has no media); Pinterest makes it the pin's destination, which is the whole point of a pin. Every other platform ignores it. Use "" to remove it. |
| `mediaIds` | array of string | Replace the media set (ordered asset ids) |
| `accountIds` | array of string | Replace the target accounts |
| `action` | `now` \| `schedule` \| `queue` \| `draft` | now = publish, schedule = re-schedule (needs scheduledAt), queue = next free posting-queue slot, draft = keep as draft |
| `scheduledAt` | string | ISO 8601 datetime — required when action is "schedule" |
| `timezone` | string | IANA timezone for the schedule |

Returns: `ok`, `post`, `preview`

## `delete_post`

**Delete a post** — writes · destructive

Permanently delete Ravenpost’s copy of a post and cancel any scheduled publish — the post cannot be restored. Use this to remove drafts or duplicate/obsolete scheduled posts. It never takes a post down from a network: a post already published stays live on the platform. The dashboard offers a separate "delete everywhere" on the networks Ravenpost can delete from (a post on Instagram, TikTok, Threads and YouTube cannot be taken down through Ravenpost at all); this tool does not.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id to delete |

Returns: `ok`, `deleted`

## `schedule_post`

**Schedule a post** — writes · destructive · reaches outside Ravenpost

Schedule (or reschedule) an existing post for a future time, without editing its content. Give scheduledAt as an absolute ISO 8601 datetime (include the offset, e.g. 2026-07-05T09:00:00+03:00). Rescheduling replaces the previous time, which is not kept. At that time the post is published to its target accounts, where it is public — tell the user the accounts and the time. A time in the past is refused rather than published immediately; use publish_post for that, and only on an explicit instruction.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id |
| `scheduledAt`* | string | ISO 8601 datetime to publish at (include timezone offset) |

Returns: `ok`, `post`, `warnings`

## `publish_post`

**Publish a post now** — writes · destructive · reaches outside Ravenpost

Publish an existing post immediately (e.g. a draft), without editing its content. A post that has already been published, or is publishing right now, is refused rather than sent twice. It goes public on every target account at once and cannot be undone from here: delete_post removes only Ravenpost's copy, and a post on Instagram, TikTok, Threads and YouTube cannot be taken down through Ravenpost at all.

| Argument | Type | Notes |
|---|---|---|
| `postId`* | string | The post id to publish now |

Returns: `ok`, `post`, `preview`

## `upload_media`

**Upload media** — writes · reaches outside Ravenpost

Upload an image or a video (mp4/mov/webm) to the media library, returning a media id for create_post. Each call adds a new asset to this workspace’s private library; nothing already there is replaced, and nothing is posted anywhere. Images are reformatted to the requested publishing format; videos are stored as-is (format/fit are ignored — upload the video pre-edited). Give the file as ONE of: url (preferred when it is already online — the server downloads it from whatever public address you give) or base64 (fallback for small images; avoid for video). For a large local file in production, prefer create_media_upload (direct upload, no base64 through this channel). format: feed_square (1:1), feed_portrait (4:5), landscape (1.91:1), story or reel (9:16), or original (no resize). fit: "cover" crops to fill (default), "contain" fits the whole image and pads.

| Argument | Type | Notes |
|---|---|---|
| `url` | string | Public URL to fetch the file from (preferred if already online) |
| `base64` | string | Base64 file bytes (data URI ok) — fallback for small images; avoid for video |
| `format`* | `feed_square` \| `feed_portrait` \| `landscape` \| `story` \| `reel` \| `original` | Target format / aspect ratio (images only — videos are stored as-is) |
| `fit` | `cover` \| `contain` | cover = crop to fill (default), contain = fit + pad |
| `crop` | `smart` \| `centre` | How a 'cover' crop chooses what to keep: 'smart' = saliency-based, keeps the subject (default); 'centre' = predictable middle crop, better for posters/screenshots |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `media`, `note`

## `create_media_upload`

**Start a direct media upload** — writes

Get a presigned URL to upload a file straight to storage — no base64 through this channel, no third-party host. Best for large files and production. The URL grants write access to this workspace’s own private storage for 10 minutes; it replaces nothing, and the file joins the media library only when attach_media records it. Flow: (1) call this with the contentType; (2) HTTP PUT the raw file bytes to the returned uploadUrl (e.g. `curl -X PUT --data-binary @file -H "Content-Type: <type>" "<uploadUrl>"`); (3) call attach_media with the returned storageKey to save it to the media library.

| Argument | Type | Notes |
|---|---|---|
| `contentType`* | string | MIME type of the file, e.g. image/jpeg, image/png, video/mp4 |
| `filename` | string | Original filename (for a nicer storage key) |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `uploadUrl`, `storageKey`, `expiresInSec`, `next`

## `attach_media`

**Attach an uploaded file** — writes · destructive

Save an already-uploaded object (from create_media_upload) to the media library and return a media id. Works for images and videos (mp4/mov/webm). Images can optionally be reformatted to a publishing format first: the server reads the upload back from storage, stores the reformatted image as a new file and deletes the raw upload at storageKey, which cannot be undone. Videos are always recorded as-is. Omit format (or use "original") to record it unchanged — recording as-is deletes nothing. Pass the SAME workspaceId you gave create_media_upload — a storage key belongs to the workspace it was minted in and is refused anywhere else.

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

Reshape ONE image already in the media library into several platform canvases at once, and return the new asset ids: feed_portrait (1080×1350, 4:5), feed_square (1080×1080), landscape (1080×566, 1.91:1) and story (1080×1920, 9:16 — also what a reel or a TikTok photo wants). Cropping is saliency-based by default: sharp scores regions by saturation, luminance and skin tone and keeps the strongest, so an off-centre subject survives a 4:5 → 9:16 cut. Use crop="centre" for images composed around their middle (posters, screenshots, flat graphics), where a predictable crop beats a guessed one. fit="contain" pads instead of cropping — use it when nothing may be cut off at all. Images only; video is not re-encoded. The source image is left unchanged and every canvas is a new asset. Variants inherit the source’s alt text and folder, and asking for two formats with the same dimensions produces one file, not two. Typical use: upload once, call this with the formats the selected platforms want, then pass the right variant id per post.

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

Get one workspace's analytics overview: follower counts per connected account (plus a daily follower series for the last 30 days) and engagement on recent posts. A post's `source` says where it came from: "ravenpost" for one published from here, "platform" for one already on the account and imported so its engagement counts too. An account's `followers` is null when we collect none for its platform — today TikTok, X, Telegram, LinkedIn, Threads and YouTube, whose APIs either expose no insights or need a permission that is not approved yet (or, for X, charge for every read, so we read none and its numbers are in its own app) — so null means "unknown", never zero. Likewise a post metric that is absent was not collected rather than being 0.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `totalFollowers`, `trackedPosts`, `collectedAt`, `accounts`, `posts`

## `list_audio`

**Search reel audio** — read-only · reaches outside Ravenpost

Search Instagram’s audio catalog for tracks that can be attached to a reel, then pass the chosen track’s id as create_post/update_post `audio.audioId`. Call it WITHOUT a query to get what is currently trending — that is the featured list. accountId must be an Instagram account connected through a Facebook Page ("FACEBOOK_LOGIN" in list_accounts); a directly-connected one cannot reach the catalog and gets an error saying so. Instagram connects directly today, so only an account connected through Facebook earlier can use this. Meta only exposes tracks licensed for third-party use, so this catalog is narrower than the one in the Instagram app — a track the user can pick on their phone may legitimately be missing here. The catalog is Meta’s, shared by every Instagram account — licensed tracks plus original sounds from other creators’ reels — not the user’s own data; searching it only reads and attaches nothing. This is Instagram-only. TikTok and Facebook expose no music API, so there is nothing to list for them.

| Argument | Type | Notes |
|---|---|---|
| `accountId`* | string | Instagram account id (from list_accounts) to search on behalf of |
| `query` | string | Search text (song or artist). Omit to get trending tracks. |
| `kind` | `music` \| `original_sound` | 'music' = licensed catalog track (default); 'original_sound' = audio lifted from another creator's reel |
| `limit` | number | Max tracks to return (default 25) |

Returns: `tracks`

## `list_queue_slots`

**List posting queue slots** — read-only

List the workspace posting schedule: the recurring weekly queue slots (weekday + local time) that action="queue" publishes into, plus `nextFreeSlot` — the next slot no post is booked into, which is where action="queue" would put a post now (null when there are no slots, or none is free in the weeks ahead). Slots are defined in dashboard Settings and are workspace-wide (shared by every connected account), so each workspace has its own schedule. weekday 0 = Sunday … 6 = Saturday, in the workspace timezone.

| Argument | Type | Notes |
|---|---|---|
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `slots`, `nextFreeSlot`

## `list_boards`

**List Pinterest boards** — read-only

List the boards on one of the user's own connected Pinterest accounts, read live from Pinterest's API with that account's token. It reads that one account only: nothing on Pinterest is created, changed or published, and nothing becomes visible to anyone. Every pin belongs to a board and Pinterest has no default, so a post targeting Pinterest must name one — pass the board name or id as `board` on create_post/update_post. accountId is a Pinterest account id from list_accounts; other platforms have no boards and are rejected.

| Argument | Type | Notes |
|---|---|---|
| `accountId`* | string | A Pinterest account id from list_accounts |

Returns: `boards`

## `platform_limits`

**Get platform limits** — read-only

Return per-platform caption limits, media rules, thread limits, and recommended media specs (dimensions, container formats, size/duration caps). Consult this BEFORE generating or picking media for a post so images/videos match what the platform renders best (e.g. X images at 1600×900 16:9, X video as MP4 H.264 up to 20 minutes). threadMax is the max follow-up posts a thread can carry after the caption; null means the platform has no thread model. captionFormatting describes the rich-text markup the platform renders in captions (e.g. Telegram accepts a markdown subset); null means captions publish as plain text. formats lists the post.type values the platform honors; null means it ignores type and just consumes the media set. supportsAudio means a track from the platform’s own catalog can be attached through the API (see list_audio) — only Instagram reels can. For every other platform the audio must already be baked into the video file. postingRules lists what the platform refuses beyond length and media (X: one $cashtag per post, replies and quotes only where the target post names the account, thread replies that @mention only people already in the conversation, one X account per post); empty means nothing beyond the numbers.

Takes no arguments.

Returns: `platforms`

## `list_video_templates`

**List video templates** — read-only

List the video templates create_video can render, with what each one is for, the fields it reads and the ones it cannot do without, plus the canvases (9:16, 1:1, 16:9) and what a video and a screenshot cost in credits. Reads a fixed catalogue; nothing is created. Call it once before the first create_video of a conversation, then choose the template whose `when` matches what the user asked for. Every template takes the same flat fields — headline, subheadline, body, shots, features, cta, stat — and ignores the ones it does not use; the brand (name, tagline, icon, accent colour) is filled in from the workspace unless overridden.

Takes no arguments.

Returns: `templates`, `canvases`, `fields`, `credits`

## `create_video`

**Make a video** — writes

Render a short branded video (9:16 vertical by default; also square and landscape) and save it to the media library as an mp4 — returning a media id create_post takes as mediaIds. Either a storyboard (template storyboard: the scenes given in `scenes`, in order, with an optional music bed) or one of the fixed, silent templates in list_video_templates. Pick the canvas by where it goes: vertical for Reels, TikTok, Shorts and Stories (every word is kept clear of the buttons and captions those apps draw over a video, and inside the feed's 4:5 crop), square for X, LinkedIn and other feeds, landscape only for YouTube or a website. Fewer, shorter lines read better: three features beat five. It lays out the user's own pictures, clips and words — no generative model draws anything. It costs 25 of the workspace's monthly credits, taken before rendering and handed back if the render fails; once the month's credits are spent it is refused with the balance — tell the user, do not retry. Render only what the user asked for: confirm the template, the headline and the pictures first when they have not said. Pictures come from the media library: upload_media for a file, capture_screenshot for the website, import_app_screenshots for the App Store or Google Play listing. A shot given by mediaId must be an image. The brand name, tagline and icon are filled in from the brand profile and the workspace unless overridden here; set accent to a #rrggbb colour to give the video the brand's colour. Rendering takes one to five minutes on a shared box, a 30-second storyboard the most. The call waits up to `wait` seconds (default 40) reporting progress, then returns the finished video — or the render's id and status when it needs longer, in which case call get_video with the id. The result names any field the template leaves out. Nothing is posted anywhere: the video sits in the private library until a post carrying it is published.

| Argument | Type | Notes |
|---|---|---|
| `template`* | `app_showcase` \| `feature_list` \| `announcement` \| `milestone` \| `storyboard` | storyboard (your own scenes — the one for a reel or a TikTok), or a fixed template: app_showcase, feature_list, announcement or milestone (see list_video_templates) |
| `canvas` | `vertical` \| `square` \| `landscape` | vertical (9:16, default), square (1:1) or landscape (16:9) |
| `headline`* | string | The big line the video opens with; for a storyboard, the name it is filed under (its hook scene opens it) |
| `subheadline` | string | The line under the headline |
| `body` | string | A sentence of detail (announcement template) |
| `shots` | array of object | The pictures, in order (app_showcase needs at least one; announcement and feature_list take the first) |
| `features` | array of object | Two to five features, for feature_list |
| `cta` | object | The closing call to action |
| `stat` | object | The number the milestone template counts up to |
| `brandName` | string | Overrides the brand name the workspace knows |
| `brandTagline` | string | Overrides the tagline; "" for none |
| `iconMediaId` | string | An image in the media library to use as the brand mark (the app icon) |
| `accent` | string | Brand colour as #rrggbb |
| `theme` | `dark` \| `light` | dark (default) or light background |
| `title` | string | A name for the video in the library; defaults to the headline |
| `scenes` | array of value | The storyboard template's scenes, in order: 2 to 10, at most 30 s in all, opening on a hook and ending on an end card (see list_video_templates). The other templates ignore them. |
| `music` | `glow` \| `pulse` \| `drift` | A music bed under a storyboard: glow (warm and calm — a product walkthrough, a story); pulse (upbeat — a launch, a release, a big number); drift (mellow lo-fi — tips, how-tos, behind the scenes). Leave out for none; the templates are always silent. |
| `wait` | integer | Seconds to wait for the render before answering (default 40) |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `render`, `media`, `posterUrl`, `ignored`, `credits`, `next`

## `get_video`

**Check a video render** — read-only

Check a render create_video or capture_screenshot started: its status (queued, rendering, ready, failed), progress and, once ready, the media ids and URLs. Reads one row; nothing is changed. Set `wait` (seconds, up to 45) to hold the call until it settles or the time is up — one call like that beats polling every second.

| Argument | Type | Notes |
|---|---|---|
| `renderId`* | string | The id create_video or capture_screenshot returned |
| `wait` | integer | Seconds to wait for it to finish (default 0: answer at once) |

Returns: `ok`, `render`, `media`, `posterUrl`, `ignored`, `credits`, `next`

## `capture_screenshot`

**Screenshot a website** — writes · reaches outside Ravenpost

Take screenshots of a web page — the workspace's own site, usually — with a headless browser, as a desktop (1440×900 at 2×) and/or a mobile (390×844 at 3×) capture, and save them to the media library as images: shots for create_video, or pictures for a post. Each device costs 2 credits; when the month's credits cover fewer devices than asked, it captures what they cover and says so, and once they are spent it is refused with the balance — tell the user, do not retry. The server fetches whatever public https address is given, so point it only at pages the user named; private and internal addresses are refused. fullPage captures the whole page (as a JPEG) rather than the first screen (PNG). Waits up to `wait` seconds (default 40) for the capture; a page that takes longer is finished with get_video.

| Argument | Type | Notes |
|---|---|---|
| `url`* | string | The page to capture, e.g. https://example.com/ |
| `devices` | array of `desktop` \| `mobile` | Which captures to take (default both) |
| `fullPage` | boolean | The whole page rather than the first screen (default false) |
| `wait` | integer | Seconds to wait for the capture (default 40) |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `render`, `media`, `posterUrl`, `ignored`, `credits`, `next`

## `import_app_screenshots`

**Import app store screenshots** — writes · reaches outside Ravenpost

Copy an app's store listing pictures — its phone screenshots and its icon — from the App Store or Google Play into the media library, returning media ids: the screenshots become shots for create_video (app_showcase especially) and the icon its brand mark (iconMediaId). Reads the listing the workspace's brand profile holds when no url is given. Costs no credits; a picture already imported is reused rather than copied again. Apple's listing is read through its lookup API; Google Play's from its page, best effort.

| Argument | Type | Notes |
|---|---|---|
| `url` | string | The App Store or Google Play link; omit to use the brand profile's |
| `store` | `app_store` \| `google_play` | Which of the profile's listings to read (default: the App Store one when both are saved) |
| `limit` | integer | How many screenshots at most (default 6) |
| `workspaceId` | string | Which workspace to act in — an id from list_workspaces. Optional with a single workspace; REQUIRED once there are several, where guessing would mean posting one client's content to another client's accounts. Ask the user which one before publishing. |

Returns: `ok`, `store`, `name`, `screenshots`, `icon`, `reused`, `next`

