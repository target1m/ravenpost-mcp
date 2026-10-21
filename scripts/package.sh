#!/usr/bin/env bash
# Builds the ZIP OpenAI's plugin portal takes (Plugins → Upload new or
# existing plugin): the portable manifest with its listing and review
# metadata, the MCP server configuration, the skills and the icon — and
# nothing else. No Claude-only manifests, no registry server.json, no git
# metadata, no credentials: the portal rejects reviewer credentials in a
# package, and they go in its Review details form instead.
#
#   scripts/package.sh            → dist/ravenpost-<version>.zip
#
# The plugin is `ravenpost`, created fresh from this package. The first one,
# made through the old submission form (package name
# app-6a9f18e033cc81919751236ea984375d), cannot take a package at all: one
# that declares the MCP server is refused until "the existing MCP app" is
# configured, which the portal shows as unavailable, and one that leaves the
# server out is refused because removing it isn't supported. Should OpenAI
# repair that plugin, a package for it is this one under its name:
#   OPENAI_PACKAGE_NAME=app-6a9f18e033cc81919751236ea984375d scripts/package.sh
# The repo's plugin.json is the source either way; the name is swapped in the
# copy that goes into the ZIP, and only there.
#
# Changes to the hosted tools need no new ZIP (the portal rescans the server);
# changes to plugin.json, mcp.json, skills/ or the icon do, with a new version.
#
# The icon is fetched from ravenpo.st — the same file the site serves — rather
# than kept here. This folder is also the Claude directory's plugin, and its
# validator holds every version for a reviewer while a binary file it cannot
# read sits beside a script that could reach it.
set -euo pipefail
OPENAI_PACKAGE_NAME="${OPENAI_PACKAGE_NAME:-ravenpost}"
ICON_URL="https://ravenpo.st/icon-512.png"

cd "$(dirname "$0")/.."
version=$(python3 -c 'import json; print(json.load(open("plugin.json"))["version"])')
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R mcp.json skills LICENSE "$stage/"
mkdir -p "$stage/assets"
curl -fsSL "$ICON_URL" -o "$stage/assets/icon.png"
python3 - "$OPENAI_PACKAGE_NAME" > "$stage/plugin.json" <<'PY'
import json, sys
manifest = json.load(open("plugin.json"))
manifest["name"] = sys.argv[1]
print(json.dumps(manifest, ensure_ascii=False, indent=2))
PY
mkdir -p dist
suffix=""
[ "$OPENAI_PACKAGE_NAME" = "ravenpost" ] || suffix="-${OPENAI_PACKAGE_NAME}"
out="$PWD/dist/ravenpost-${version}${suffix}.zip"
rm -f "$out"
(cd "$stage" && zip -q -r -X "$out" plugin.json mcp.json skills assets LICENSE -x '*.DS_Store')
echo "dist/ravenpost-${version}${suffix}.zip"
