---
name: measure-and-time-posts
description: Read a Ravenpost workspace's social analytics — follower counts per connected account, a 30-day follower series, and engagement on recent posts — and answer "when should I post?" without inventing a measured hour. Use when the user asks how a post or an account is doing, how many followers they have, which post did best, or when they should publish ("how did last week do?", "what's the best time to post on Instagram?"). Covers the difference between a metric that is zero and one that was never collected, which is the mistake this data invites.
---

# Measure posts, and time the next one honestly

One tool does the measuring, and it is read-only:

- `get_analytics` — followers per connected account with a 30-day daily series,
  plus engagement on recent posts.

**Settle the workspace first** (`list_workspaces`); analytics are per workspace,
and an agency's clients are measured separately for a reason. Full argument list:
[`../publish-a-social-post/references/tools.md`](../publish-a-social-post/references/tools.md).

## Absent is not zero

This is the rule that decides whether your answer is true.

- An account's `followers` is **`null`** when that platform reports none — not
  when the account has none. Which platforms report nothing today is named in
  `get_analytics`'s own description; trust that over memory, because it moves
  as permissions are granted. Say "Instagram reports followers; LinkedIn
  doesn't expose them", never "LinkedIn: 0".
- A post metric that is **missing** was not collected. Do not add it into a total
  as a zero, and do not present a sum as complete when part of it is unknown.
- `collectedAt` says when the numbers were last read from the platforms. If the
  user is surprised by a stale number, that is the explanation.
- A post's `source` is `ravenpost` for one published from here and `platform`
  for one that was already on the account and imported so its engagement counts.
  Both are real posts; only the first went out through Ravenpost.

## When to post

Ravenpost does not compute a "best time to post", and nothing it returns is
one. When the user asks:

- **If the workspace runs a posting queue** (`list_queue_slots`), its slots are
  the times this workspace has chosen to post. `create_post` with
  `action: "queue"` takes the next free one, with no arithmetic.
- **Otherwise ask for a time**, or offer one plainly as a suggestion — never as
  a finding.
- You may point at which recent posts earned the most engagement in
  `get_analytics`, but say how many posts that rests on. A handful of posts is
  an anecdote, not a measurement, and it does not make an hour "the best".

When you do schedule, pass `scheduledAt` as an absolute ISO 8601 datetime **with
the offset**, worked out in the workspace's timezone (`list_workspaces` gives
it), and show the user the local time you computed — a timezone mistake should
be visible before the post is scheduled, not after it goes out.

## Never

- Never invent a benchmark ("good engagement for this size is ~3%"). Report what
  was measured.
- Never present an hour as a measured best time to post. Nothing here measures
  one.
