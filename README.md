# Ravenpost

Schedule and publish social media posts from Claude. [Ravenpost](https://ravenpo.st/)
is a social media scheduler for content creators, influencers and agencies:
write a post once, send it to Instagram, TikTok, X, LinkedIn, Threads, Bluesky,
YouTube, Pinterest and Telegram, and see how each network will show it before
anything goes out.

This plugin connects Claude to Ravenpost's hosted MCP server and adds four
skills that teach Claude the workflow around it: settle the workspace and the
accounts, preview before writing anything, and publish only when you ask.

## What you can do

- **Preview a post as every network will show it**, before anything is
  created, with a warning for anything a network would reject: a caption over
  X's 280 characters, a post with no media where one is required, a Pinterest
  pin with no board.
- **Draft, schedule, queue or publish** to one account or several at once — at
  a time you name, or in the next free slot of your weekly posting queue.
- **Edit, reschedule or cancel** posts that have not gone out yet, and check how
  a published post landed on each account.
- **Bring in images and video** from a link, and reshape one image into each
  network's format.
- **Read followers and engagement** for the accounts each network lets Ravenpost
  measure.

## Getting started

1. Create a Ravenpost account at [ravenpo.st](https://ravenpo.st/) — the free
   plan is enough to try it — and connect your social accounts in the
   dashboard. Connecting a social account happens there, not in Claude.
2. Add the plugin, then connect Ravenpost from its **Connectors** tab and sign
   in when asked. There is no API key to copy: the server uses OAuth.
3. Ask Claude, for example:
   - "Preview a launch post for my Instagram and X accounts before anything is
     posted."
   - "Schedule the LinkedIn version for Tuesday at 9am."
   - "Put this in the queue for all my accounts."
   - "What's scheduled for next week, and did yesterday's post go out
     everywhere?"
   - "How are my accounts doing — followers and engagement on recent posts?"

## Skills

| Skill | What it teaches Claude |
|---|---|
| [`publish-a-social-post`](skills/publish-a-social-post/SKILL.md) | Settle the workspace, pick the accounts, collect what each destination requires, **preview before writing**, and ask before publishing — the one step that cannot be taken back |
| [`manage-scheduled-posts`](skills/manage-scheduled-posts/SKILL.md) | Find, edit, move, cancel and check posts — including that editing resets a post to a draft, and that deleting removes Ravenpost's copy rather than the live one |
| [`prepare-post-media`](skills/prepare-post-media/SKILL.md) | Getting files in, the canvases each network wants, cutting one image for several networks, and the media rules a post actually fails on |
| [`measure-and-time-posts`](skills/measure-and-time-posts/SKILL.md) | Reading analytics without turning "not collected" into a zero, and answering "when should I post?" without inventing a measured hour |

## Data and privacy

The plugin runs nothing on your computer. Its skills are written instructions,
and its one connector is Ravenpost's hosted server at
`https://api.ravenpo.st/mcp`. When Claude calls a tool, the request — captions,
links to media, the accounts you choose, the times you set — goes to Ravenpost
under your own sign-in, and Ravenpost posts to the networks you selected when
you publish or when a scheduled time arrives.

One other destination, and only for a file you hand over: a large image or
video can go straight into Ravenpost's own storage, a Cloudflare R2 bucket
(`*.r2.cloudflarestorage.com`), through a one-time upload link the connector
issues (`create_media_upload`), so its bytes never pass through the
conversation. Nothing is sent anywhere else.

Ravenpost keeps your posts, media and connected accounts until you delete them
or your account. Privacy policy: <https://ravenpo.st/privacy/>.

## Good to know

- A published post cannot be taken back through Ravenpost on Instagram, TikTok,
  Threads or YouTube, and deleting a post in Ravenpost never removes it from a
  network. That is why Claude previews first and publishes only on your
  instruction; scheduling and drafting stay changeable.
- Ravenpost does not write captions or generate images. The words and the files
  come from you or from Claude, and media is brought in from a link you give.
- Some networks report no numbers to Ravenpost. Those are shown as not
  collected, never as zero.
- With several workspaces — one per client, on the Agency plan — Claude asks
  which one to use rather than guessing, so one client's post never lands on
  another's accounts.

## Tools

21 tools. Every one declares a title and read-only / destructive / open-world
hints, so your client can tell you what a call will do before you allow it.

### Accounts

| Tool | What it does |
|---|---|
| `list_workspaces` | Every workspace the credential can act in. With more than one, the other tools require a `workspaceId` rather than guessing which client you meant. |
| `list_accounts` | Connected accounts with their ids, platforms and status. |

### Posts

| Tool | What it does |
|---|---|
| `list_posts` | Posts 50 at a time — newest first, or soonest first when filtered to scheduled — optionally filtered by status, with the total that matches. |
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
| `upload_media` | Upload an image or video from a URL or base64 (a local path too, on a development server only); images are reformatted to the platform shape you name. |
| `create_media_upload` | Presigned direct upload — for large or production files, so bytes never pass through the model's context. |
| `attach_media` | Register a direct upload as an asset, reformatting an image or recording a video as-is. |
| `create_variants` | Cut one image into several platform canvases at once, cropping on the subject rather than the middle. |
| `list_media` | Recent media assets, to reuse one instead of re-uploading. |
| `image_formats` | The image formats and target dimensions `upload_media` accepts. |

### Analytics

| Tool | What it does |
|---|---|
| `get_analytics` | Followers per account and engagement on recent posts — a number a platform doesn't report is absent, never a zero. |

### Reference

| Tool | What it does |
|---|---|
| `list_audio` | Search Instagram's licensed audio catalog for a reel track — Instagram accounts connected through a Facebook Page only. |
| `list_queue_slots` | The weekly posting schedule and the next free slot. |
| `list_boards` | The Pinterest boards each connected account owns — a pin has to name one, and Pinterest has no default. |
| `platform_limits` | Caption budgets, media rules, posting rules and recommended specs per platform. |

## Other ways to connect

The server is hosted; there is nothing to install or run.

```
https://api.ravenpo.st/mcp
```

Transport: **Streamable HTTP**. Official registry entry:
[`st.ravenpo/ravenpost`](https://registry.modelcontextprotocol.io/v0/servers?search=ravenpost).

**OAuth (recommended).** Add the URL above as a custom connector in any client
that speaks MCP authorization — Claude, ChatGPT, Cursor, VS Code — and sign in
when it opens Ravenpost. The server is an OAuth resource server:
`/.well-known/oauth-protected-resource` names the authorization server and the
`401` carries the challenge, so the client runs the whole flow on its own.

**Personal access token.** For clients with no browser flow. Generate one on the
**MCP** page of the Ravenpost dashboard (shown once, revocable at any time):

```bash
claude mcp add --transport http ravenpost https://api.ravenpo.st/mcp \
  --header "Authorization: Bearer rvp_your_token"
```

Clients that cannot set headers can pass it in the URL instead —
`https://api.ravenpo.st/mcp?token=rvp_…`.

## This repository

Documentation, the registry manifest and the plugin for a hosted service.
Ravenpost's own source is not public. Issues about the MCP server are welcome
here; anything account-specific should go to support.

```
plugin.json                 portable manifest (Agent Plugins 1.0.0), with the
                            ChatGPT listing and review metadata under
                            extensions.com.openai
mcp.json                    the hosted server, Agent Plugins format, OAuth (DCR)
.claude-plugin/plugin.json  the same identity, for Claude
.mcp.json                   the hosted server, Claude format
skills/<name>/SKILL.md      one workflow each
skills/publish-a-social-post/references/
    tools.md                every tool, its arguments and what it returns
    platforms.md            caption budgets, media rules, per-platform limits
server.json                 the official MCP registry entry
scripts/package.sh          builds the ZIP the ChatGPT plugin portal takes
```

Both reference files are **generated from the server's own tool registrations
and platform registry**, not transcribed — a skill that describes an argument
the server no longer takes is worse than one that says nothing, because the
model follows it and the call fails.

**Submitting to ChatGPT.** OpenAI's plugin portal takes the package as a ZIP
(Plugins → Upload plugin). `scripts/package.sh` builds it from `plugin.json`,
`mcp.json`, `skills/`, the licence and the icon the site serves — nothing
Claude-only and no credentials (reviewer sign-in goes in the portal's Review
details form). The repository keeps no image of its own: the Claude directory
holds a plugin for review while one sits beside a script that could reach it. The
listing text, the five positive and three negative review cases and the
release notes ride in `plugin.json`, so changing them means a new version and
a new ZIP; changes to the hosted tools don't — the portal rescans the server.

## Links

- Product: <https://ravenpo.st/>
- What the MCP server does: <https://ravenpo.st/mcp/>
- Tool reference: <https://ravenpo.st/docs/mcp/>
- REST API: <https://ravenpo.st/docs/api/>
- Privacy: <https://ravenpo.st/privacy/> · Terms: <https://ravenpo.st/terms/>
- Support: support@ravenpo.st
