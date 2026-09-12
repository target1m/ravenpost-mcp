---
name: measure-and-time-posts
description: Read a Ravenpost workspace's social analytics and its measured best times to post — follower counts per account, engagement on recent posts, and the hours that actually earned engagement for these accounts. Use when the user asks how a post or an account is doing, how many followers they have, which post did best, or when they should publish ("what's the best time to post on Instagram?", "how did last week do?"). Covers the difference between a metric that is zero and one that was never collected, which is the mistake this data invites.
---

# Measure posts, and pick a time from the measurement

Two tools, and both are read-only:

- `get_analytics` — followers per connected account with a 30-day daily series,
  plus engagement on recent posts.
- `best_times` — the hours this workspace's own posts earned the most
  engagement, overall and per platform.

**Settle the workspace first** (`list_workspaces`); analytics are per workspace,
and an agency's clients are measured separately for a reason. Full argument list:
[`../publish-a-social-post/references/tools.md`](../publish-a-social-post/references/tools.md).

## Absent is not zero

This is the rule that decides whether your answer is true.

- An account's `followers` is **`null`** when that platform reports none — not
  when the account has none. LinkedIn, Threads and Telegram expose no insights
  at all, and TikTok's need a permission that is not approved yet. Say
  "Instagram and X report followers; LinkedIn doesn't expose them", never
  "LinkedIn: 0".
- A post metric that is **missing** was not collected. Do not add it into a total
  as a zero, and do not present a sum as complete when part of it is unknown.
- `collectedAt` says when the numbers were last read, and `refreshing` says a
  refresh is running right now. If the user is surprised by a stale number,
  that pair is the explanation.
- A post's `source` is `ravenpost` for one published from here and `platform`
  for one that was already on the account and imported so its engagement counts.
  Both are real; only the first has a Ravenpost post id behind it.

## `best_times`, and when it refuses to answer

The answer is measured from **this workspace's own published posts**, not from a
generic industry heatmap. That makes it trustworthy and it makes it refusable.

`overall` plus one report per platform. Each carries `slots` ordered strongest
first — `weekday` (0 = Sunday) and `minutes` from local midnight, **in the
workspace timezone** — a 7×24 `grid` for a heatmap, and a `score` where 1.0 is a
typical post for that account.

**When `insufficient` is true there is no answer.** `slots` is empty and that
means *unknown*, not "no good time". Say so. `reason` says which wall it hit,
and the honest reply differs:

| `reason` | What to say |
|---|---|
| `few_posts`, `few_samples` | Not enough history yet — publishing more will fix it, and `observations` vs `minObservations` says how far off it is |
| `low_engagement` | The posts earn too few interactions for any hour to stand out. More posting does **not** fix this; say that rather than promising it will |
| `not_collected` | That platform reports no per-post engagement to measure. There will never be an answer for it — do not say "not enough data yet" |
| `no_data` | Nothing published from this workspace yet |

Prefer a platform's own report over `overall` when the post is going to one
platform: Instagram's evenings and LinkedIn's mornings average into advice that
suits neither.

## Turning a slot into a post

A slot is a weekday and a minute offset in the workspace timezone. Convert it to
an absolute ISO 8601 datetime **with the offset** before passing it to
`create_post` (`action: "schedule"`) or `schedule_post` — and show the user the
local time you computed, so a timezone mistake is visible before it is scheduled.

If the workspace runs a posting queue (`list_queue_slots`), `action: "queue"` is
usually the better answer: the slots are already the times this workspace posts,
and the queue picks the next free one without any arithmetic.

## Never

- Never invent a benchmark ("good engagement for this size is ~3%"). Report what
  was measured.
- Never present a rank built on one or two posts as a finding; that is what
  `insufficient` exists to prevent.
