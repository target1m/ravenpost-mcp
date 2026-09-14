# Ravenpost MCP server

Schedule and publish social media posts to Instagram, TikTok, X, LinkedIn,
Threads, Bluesky, YouTube, Pinterest and Telegram from Claude, ChatGPT, Cursor,
Claude Code or any other MCP client.

[Ravenpost](https://ravenpo.st/) is a multi-platform social media scheduler
covering those nine networks (Facebook Pages is built but not on offer at the
moment — Meta lets one app hold either the Instagram Login or the Facebook
Login permission family, and Ravenpost chose Instagram). This repository
documents its **hosted MCP server**, which exposes the
same posting flow to any MCP client: list the accounts you have connected,
upload or reshape media, preview a post exactly as each network will render it,
then publish it now, schedule it, or drop it into a weekly posting queue.

The server is hosted. There is nothing to install and nothing to run.

```
https://api.ravenpo.st/mcp
```

Transport: **Streamable HTTP**. Official registry entry:
[`st.ravenpo/ravenpost`](https://registry.modelcontextprotocol.io/v0/servers?search=ravenpost).

## Connecting

Two ways, and the first needs no credential handling at all.

**OAuth (recommended).** Add the URL above as a custom connector and sign in
when your client opens Ravenpost. The server is an OAuth resource server —
`/.well-known/oauth-protected-resource` names the authorization server and the
`401` carries the challenge — so a client that speaks MCP authorization runs the
whole flow on its own.

**Personal access token.** For clients with no browser flow. Generate one in
Ravenpost under Settings → MCP tokens (shown once, revocable at any time):

```bash
claude mcp add --transport http ravenpost https://api.ravenpo.st/mcp \
  --header "Authorization: Bearer rvp_your_token"
```

Clients that cannot set headers can pass it in the URL instead —
`https://api.ravenpo.st/mcp?token=rvp_…`.

You need a Ravenpost account with at least one connected social account. The
free plan is enough to try it.

## Tools

22 tools. Every one declares a title and read-only / destructive hints, so your
client can tell you what a call will do before you allow it.

### Accounts

| Tool | What it does |
|---|---|
| `list_workspaces` | Every workspace the credential can act in. With more than one, the other tools require a `workspaceId` rather than guessing which client you meant. |
| `list_accounts` | Connected accounts with their ids, platforms and status. |

### Posts

| Tool | What it does |
|---|---|
| `list_posts` | List recent posts, optionally filtered by status. |
| `get_post` | One post with every destination's status and permalink. |
| `preview_post` | Render a post as each platform will show it **without creating anything** — an interactive card in clients that support MCP Apps, and per-platform character counts everywhere else. |
| `create_post` | Draft, publish, schedule or queue a post across any set of accounts. |
| `update_post` | Edit a draft or scheduled post — resets it to draft, so pass an action to re-send it. |
| `delete_post` | Delete the Ravenpost copy and cancel a pending publish. Never takes a live post down from a network. |
| `schedule_post` | Move a post to a new time. |
| `publish_post` | Publish a post immediately. |

### Media

| Tool | What it does |
|---|---|
| `upload_media` | Upload an image or video from a URL, a local path (dev only) or base64; images are reformatted to the platform shape you name. |
| `create_media_upload` | Presigned direct upload — for large or production files, so bytes never pass through the model's context. |
| `attach_media` | Register a direct upload as an asset, reformatting an image or recording a video as-is. |
| `create_variants` | Cut one image into several platform canvases at once, cropping on the subject rather than the middle. |
| `list_media` | Recent media assets, to reuse one instead of re-uploading. |
| `image_formats` | The image formats and target dimensions `upload_media` accepts. |

### Analytics

| Tool | What it does |
|---|---|
| `get_analytics` | Followers per account and engagement on recent posts. |
| `best_times` | Recommended posting hours measured from this workspace's own posts — with an explicit "not enough data yet" answer rather than a confident guess. |

### Reference

| Tool | What it does |
|---|---|
| `list_audio` | Search Instagram's licensed audio catalog for a reel track. |
| `list_queue_slots` | The weekly posting schedule and the next free slot. |
| `list_boards` | The Pinterest boards each connected account owns — a pin has to name one, and Pinterest has no default. |
| `platform_limits` | Caption budgets, media rules and recommended specs per platform. |

## Skills

The tools are the capability; the skills are the judgement about when to reach
for which. This repository is also a **plugin** — four skills that teach an
assistant the workflow the tools sit inside:

| Skill | What it teaches |
|---|---|
| [`publish-a-social-post`](skills/publish-a-social-post/SKILL.md) | Settle the workspace, pick the accounts, collect what each destination requires, **preview before writing**, and the confirmation a publish needs — because publishing is the one step that cannot be taken back |
| [`manage-scheduled-posts`](skills/manage-scheduled-posts/SKILL.md) | Find, edit, move, cancel and check posts — including that editing resets a post to a draft, and that deleting removes our copy rather than the live one |
| [`prepare-post-media`](skills/prepare-post-media/SKILL.md) | Getting files in, the four canvases, cutting one image for several networks, and the media rules a post actually fails on |
| [`measure-and-time-posts`](skills/measure-and-time-posts/SKILL.md) | Reading analytics without turning "not collected" into a zero, and quoting `best_times` only when it has an answer |

```
plugin.json                 portable manifest (Agent Plugins 1.0.0)
.claude-plugin/plugin.json  the same, for clients that read this path
.mcp.json                   points at the hosted server above
skills/<name>/SKILL.md      one workflow each
skills/publish-a-social-post/references/
    tools.md                every tool, its arguments and what it returns
    platforms.md            caption budgets, media rules, per-platform limits
```

Both reference files are **generated from the server's own tool registrations
and platform registry**, not transcribed — a skill that describes an argument
the server no longer takes is worse than one that says nothing, because the
model follows it and the call fails.

## Two things worth knowing

**Preview before publish.** `preview_post` writes nothing. It returns the post
as each destination renders it, together with the warnings a picture cannot
carry: a caption over the tightest selected platform's limit, a network that
requires media when there is none, a thread aimed at a platform with no thread
model, audio outside a reel. A preview that looks right and stays quiet about a
rejection is worse than no preview.

**It refuses to guess your workspace.** A credential acts as a *user*, and a
user can run several workspaces (one per client, on the Agency plan). Ask a
workspace-scoped tool with more than one available and it errors, naming them,
rather than posting one client's content to another's accounts.

## Links

- Product: <https://ravenpo.st/>
- What the MCP server does: <https://ravenpo.st/mcp/>
- Tool reference: <https://ravenpo.st/docs/mcp/>
- REST API: <https://ravenpo.st/docs/api/>
- Privacy: <https://ravenpo.st/privacy/> · Terms: <https://ravenpo.st/terms/>
- Support: support@ravenpo.st

## About this repository

Documentation and the registry manifest (`server.json`) for a hosted service.
Ravenpost's own source is not public. Issues about the MCP server are welcome
here; anything account-specific should go to support.
