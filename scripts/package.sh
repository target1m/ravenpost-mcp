#!/usr/bin/env bash
# Builds the ZIP OpenAI's plugin portal takes (Plugins → open Ravenpost →
# Upload plugin): the listing and review metadata, the skills and the icon —
# and nothing else. No Claude-only manifests, no registry server.json, no git
# metadata, no credentials: the portal rejects reviewer credentials in a
# package, and they go in its Review details form instead.
#
#   scripts/package.sh            → dist/ravenpost-<version>.zip
#
# The portal ties a package to the plugin it was first created as, and
# refuses one whose `name` is anything but that plugin's package name. Ours
# was created through the old submission form, so its name is the app id —
# while this repo's plugin.json stays `ravenpost`, the identity Claude Code
# installs and namespaces the skills by. So the name is swapped in the copy
# that goes into the ZIP, and only there.
#
# That plugin's MCP server is the app the old form connected, and it lives
# outside the package: the release ZIP the portal hands back for it is a bare
# `.codex-plugin/plugin.json`, with no `.mcp.json` and no `mcpServers`. A
# package that declares a server of its own is refused ("Keep the existing
# MCP connection"), so for that plugin the ZIP is built the way the portal's
# own is — the Codex layout, the server left out. A plugin created fresh from
# a ZIP is the opposite case: its server has to be in the first upload, so any
# other package name gets the portable layout with `mcp.json`.
#
# Changes to the hosted tools need no new ZIP (the portal rescans the server);
# changes to plugin.json, skills/ or assets/ do, with a new version.
set -euo pipefail
# Override for a plugin created fresh from a ZIP, which takes its package
# name from the manifest:  OPENAI_PACKAGE_NAME=ravenpost scripts/package.sh
EXISTING_APP="app-6a9f18e033cc81919751236ea984375d"
OPENAI_PACKAGE_NAME="${OPENAI_PACKAGE_NAME:-$EXISTING_APP}"

cd "$(dirname "$0")/.."
version=$(python3 -c 'import json; print(json.load(open("plugin.json"))["version"])')
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R skills assets LICENSE "$stage/"

if [ "$OPENAI_PACKAGE_NAME" = "$EXISTING_APP" ]; then
  mkdir "$stage/.codex-plugin"
  python3 - "$OPENAI_PACKAGE_NAME" > "$stage/.codex-plugin/plugin.json" <<'PY'
import json, sys
src = json.load(open("plugin.json"))
openai = src["extensions"]["com.openai"]
identity = ("version", "description", "author", "homepage", "repository", "license", "keywords")
manifest = {"name": sys.argv[1], **{k: src[k] for k in identity if k in src}}
manifest["skills"] = "./skills/"
manifest["interface"] = openai["interface"]
# Review cases in a package belong to the one MCP server that package
# declares ("Plugin-level test_cases require exactly one MCP server"), and
# this one declares none. They stay with the existing MCP app — the portal
# keeps a plugin's cases when a package omits them — and are edited in its
# Review details, like the demo video and the commerce answer.
rest = {k: v for k, v in openai.items() if k not in ("interface", "review")}
if rest:
    manifest["extensions"] = {"com.openai": rest}
print(json.dumps(manifest, ensure_ascii=False, indent=2))
PY
  files=(.codex-plugin skills assets LICENSE)
  suffix=""
else
  cp mcp.json "$stage/"
  python3 - "$OPENAI_PACKAGE_NAME" > "$stage/plugin.json" <<'PY'
import json, sys
manifest = json.load(open("plugin.json"))
manifest["name"] = sys.argv[1]
print(json.dumps(manifest, ensure_ascii=False, indent=2))
PY
  files=(plugin.json mcp.json skills assets LICENSE)
  suffix="-${OPENAI_PACKAGE_NAME}"
fi

mkdir -p dist
out="$PWD/dist/ravenpost-${version}${suffix}.zip"
rm -f "$out"
(cd "$stage" && zip -q -r -X "$out" "${files[@]}" -x '*.DS_Store')
echo "dist/ravenpost-${version}${suffix}.zip"
