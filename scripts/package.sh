#!/usr/bin/env bash
# Builds the ZIP OpenAI's plugin portal takes (Plugins → open Ravenpost →
# Upload plugin): the portable manifest with its listing and review metadata,
# the MCP server configuration, the skills and the icon — and nothing else.
# No Claude-only manifests, no registry server.json, no git metadata, no
# credentials: the portal rejects reviewer credentials in a package, and they
# go in its Review details form instead.
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
# Changes to the hosted tools need no new ZIP (the portal rescans the server);
# changes to plugin.json, mcp.json, skills/ or assets/ do.
set -euo pipefail
OPENAI_PACKAGE_NAME="app-6a9f18e033cc81919751236ea984375d"

cd "$(dirname "$0")/.."
version=$(python3 -c 'import json; print(json.load(open("plugin.json"))["version"])')
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R mcp.json skills assets LICENSE "$stage/"
python3 - "$OPENAI_PACKAGE_NAME" > "$stage/plugin.json" <<'PY'
import json, sys
manifest = json.load(open("plugin.json"))
manifest["name"] = sys.argv[1]
print(json.dumps(manifest, ensure_ascii=False, indent=2))
PY
mkdir -p dist
out="$PWD/dist/ravenpost-${version}.zip"
rm -f "$out"
(cd "$stage" && zip -q -r -X "$out" plugin.json mcp.json skills assets LICENSE -x '*.DS_Store')
echo "dist/ravenpost-${version}.zip"
