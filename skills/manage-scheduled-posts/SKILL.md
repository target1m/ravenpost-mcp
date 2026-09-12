---
name: manage-scheduled-posts
description: Find, edit, reschedule, cancel or delete posts already in Ravenpost, and check how a published post actually landed on each account. Use when the user asks what is scheduled, wants to change or move a post ("move Friday's post to Monday", "fix the typo in the draft", "cancel the TikTok one"), asks whether a post went out, or asks why one failed. Covers the trap that editing a post resets it to a draft, and what deleting does and does not remove.
---

# Manage posts that already exist

Everything here acts on a post that is already in Ravenpost. Composing a new one
is the `publish-a-social-post` skill. Full argument list:
[`../publish-a-social-post/references/tools.md`](../publish-a-social-post/references/tools.md).

**Settle the workspace first** — `list_workspaces`, and ask if there is more than
one. Post ids belong to a workspace like everything else.

## Finding the post

`list_posts` takes an optional `status`: `DRAFT`, `SCHEDULED`, `PUBLISHING`,
`PUBLISHED`, `FAILED`. "What's scheduled?" is `status: "SCHEDULED"`; "did
anything fail?" is `FAILED`.

`get_post` returns one post with **every destination's own status, permalink and
error**. That per-target list is the answer to "did it go out?" — a post can be
published to X and failed on Instagram at the same time, and the rollup alone
would hide it.

## Changing one

| The user wants | Use | Watch out for |
|---|---|---|
| Different words, media, accounts or format | `update_post` | **It resets the post to a draft.** |
| The same post at a different time | `schedule_post` | Content untouched; absolute ISO 8601 with offset |
| It out now | `publish_post` | Not reversible — needs an explicit instruction |
| It gone | `delete_post` | Only removes Ravenpost's copy |

**The reset is the one that bites.** `update_post` returns the post to `DRAFT`,
so a scheduled post that is edited **stops going out** unless the same call also
carries `action` (`schedule` + `scheduledAt`, `queue`, or `now`). Fixing a typo
in Friday's post and leaving it there is how a post silently misses its slot.
When the user says "fix the typo", the whole job is: update, re-schedule to the
same time, and say both happened.

A published or publishing post can no longer be edited. Offer to delete it and
compose a new one instead — and see the next section before promising that.

## What deleting actually does

`delete_post` removes the Ravenpost copy and cancels a pending publish. **It does
not take down a post that is already live**, and on Instagram, Threads, TikTok and
YouTube nothing can: their APIs expose no delete endpoint Ravenpost holds the
scope for. Say which copies stay up rather than letting "deleted" be heard as
"gone from the internet". A post the user actually wants removed from Instagram
has to be removed in Instagram.

Deleting is permanent and takes the post's targets and queued jobs with it, so
confirm before calling it — a draft is cheap to keep, and there is no undo.

## Watching a publish land

Publishing is queued, not synchronous: `publish_post` and `create_post` with
`action: "now"` return as soon as the job is accepted. The per-account outcome
arrives seconds to minutes later.

So report it honestly — "queued for 3 accounts" — then call `get_post` to see
each target settle. A target that fails carries the platform's own reason in
`error`; pass it on verbatim rather than paraphrasing it into something vaguer.
Common ones are worth recognising:

- **a token that expired** — LinkedIn connections need reconnecting roughly
  every 60 days, and the account shows as needing attention on the Accounts page.
  Nothing you can do from here; tell the user where to fix it.
- **a missing Pinterest board** — the post was created without one. Add it with
  `update_post` (`board`), then re-publish.
- **TikTok rejecting an image** — PNG is refused; JPEG or WebP only, and the
  refusal arrives minutes after the upload succeeded.
