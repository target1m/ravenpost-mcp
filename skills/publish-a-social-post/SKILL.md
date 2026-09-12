---
name: publish-a-social-post
description: Compose, preview and publish a social media post with Ravenpost — Instagram, TikTok, X (Twitter), LinkedIn, Threads, Bluesky, YouTube, Pinterest and Telegram. Use whenever the user wants to post, tweet, share, cross-post, schedule, queue or draft something to their connected social accounts ("post this on Instagram and X", "schedule a tweet for Tuesday 9am", "put this in the queue", "draft a launch post"). Covers choosing the workspace and accounts, the per-platform limits and required fields a post can fail on, previewing before anything is written, and the confirmation a publish needs.
---

# Publish a social post

Ravenpost is compose-once, fan-out: **one post carries one caption and one set
of media, and goes to any number of connected accounts across nine networks.**
Each account is a separate destination with its own publish status, permalink
and error.

Full argument list for every tool: [`references/tools.md`](references/tools.md).
Caption budgets and per-platform rules: [`references/platforms.md`](references/platforms.md).

## Before writing anything

**1. Settle the workspace.** Call `list_workspaces`. With exactly one, pass
nothing and forget about it. **With more than one, ask the user which** and pass
`workspaceId` on every later call. Do not guess and do not pick the first: a
workspace is a client, and the accounts differ per workspace. The server enforces
this — a workspace-scoped call with several available fails with an error naming
them, which is your cue to ask, not to retry.

**2. Find the destinations.** `list_accounts` returns each account's `id`,
`platform`, `username` and `status`. Targets are **account ids**, never platform
names. If the user said "Instagram" and two Instagram accounts are connected,
ask which; if they said "everywhere", list what you are about to select and let
them confirm.

## The workflow

**3. Collect what the destinations require.** Only some of this applies:

- **Pinterest** — call `list_boards` for that account and pass `board`. A pin
  belongs to a board, Pinterest has no default, and without one the post is
  created and then fails at publish time.
- **Instagram reel audio** — `list_audio` (omit the query for what is trending),
  then pass the track as `audio`. Only reels, and only Instagram accounts
  connected through Facebook; the tool says so if the account cannot.
- **TikTok** — the `tiktok` argument carries the creator's posting options.
  Omit it and the post publishes **privately** (`SELF_ONLY`), which is the safe
  default, not a bug. Say so rather than letting the user assume it went public.
- **Media** — Instagram, TikTok, YouTube and Pinterest refuse a post with none.
  Use the `prepare-post-media` skill; pass the returned ids as `mediaIds`.

**4. Preview. Always, when you composed any part of the post.** `preview_post`
takes exactly `create_post`'s arguments, **writes nothing**, and returns the post
as each destination will render it plus a `warnings` list. Fix the warnings before
you write. A caption 40 characters over X's budget is a rejected post, and the
preview is the only place that is visible before the fact.

Skip the preview only when the user dictated the post verbatim and asked for it
to go out immediately.

**5. Show the user what will happen, then write it.** Name the accounts, the
caption, and the time. `create_post` needs `caption`, `accountIds` and `action`:

| `action` | What happens | When |
|---|---|---|
| `draft` | Saved, nothing scheduled | The user is still working on it |
| `schedule` | Goes out at `scheduledAt` | A time was given — absolute ISO 8601 **with offset** (`2026-07-05T09:00:00+03:00`) |
| `queue` | Goes out at the workspace's next free queue slot | "queue it", "next slot", "whenever you normally post" — see `list_queue_slots` |
| `now` | Publishes immediately | **Only** when the user explicitly asked to publish now |

**Publishing is the one step that cannot be undone.** People see a post within
seconds, and Instagram, Threads, TikTok and YouTube expose no delete endpoint at
all — deleting in Ravenpost removes our copy and leaves theirs live. So
`action: "now"` and `publish_post` need an explicit instruction from the user in
this turn. Scheduling does not: it sits on the calendar where it can be read and
cancelled.

**6. Report what happened.** `create_post` returns the post id and its status.
Publishing is handed to a queue, so the per-account outcome arrives after the
call — `get_post` shows each target's status, permalink and error. Say "queued
for 3 accounts, I can check in a moment", not "published to 3 accounts".

## Decisions this skill makes for you

**One caption per post.** The MCP surface has no per-platform caption override.
If the user wants different wording per network — a short X post and a long
LinkedIn one — **create one post per group of accounts**, not one post and an
apology. Say that is what you are doing.

**Hashtags** go in `hashtags`; they are appended to the caption and count
against the budget like any other characters.

**Threads** (`thread`) are follow-up posts published in order after the caption,
which carries the media. Supported on X, Bluesky, Threads, Telegram; a platform
with no thread model just publishes the caption. Limits come from the strictest
selected platform, and an over-long thread is rejected rather than trimmed.

**Markdown belongs in Telegram-only posts.** Telegram renders a markdown subset
as real formatting; every other network publishes the caption verbatim, so
`**bold**` reaches Instagram as four asterisks.

## Refuse, or stop and ask

- Never invent media. The model cannot generate images or video here; the media
  tools ingest what the user provides. If a post needs a picture and there is
  none, ask for one.
- Never publish, delete, or change an existing post's schedule on your own
  initiative — only on a clear instruction.
- Never post to an account the user did not name or approve, and never fan out
  to "all accounts" without listing them first.
- If a tool errors, read it: this server's errors name the fix (which workspaces
  exist, which boards exist, why TikTok refused). Pass that on instead of
  retrying the same call.

## Worked example

> "Schedule this for Tuesday 9am on Instagram and X: *Ravenpost 1.0 is out.*"

1. `list_workspaces` → one workspace, nothing to ask.
2. `list_accounts` → `acc_ig` (@ravenpost), `acc_x` (@ravenpost).
3. `preview_post` with `caption`, `accountIds: [acc_ig, acc_x]` → warning:
   *Instagram requires media*. Ask the user for an image, upload it, preview
   again — clean, 31/280 characters.
4. Confirm: "Instagram @ravenpost and X @ravenpost, Tuesday 16 Sep 09:00
   (+03:00)."
5. `create_post` with `action: "schedule"` and
   `scheduledAt: "2026-09-16T09:00:00+03:00"`.
6. Report the post id and that both destinations are scheduled.
