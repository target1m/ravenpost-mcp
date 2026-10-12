#!/usr/bin/env bash
# Builds the ZIP OpenAI's plugin portal takes (Plugins → Upload plugin):
# the portable manifest with its listing and review metadata, the MCP server
# configuration, the skills and the icon — and nothing else. No Claude-only
# manifests, no registry server.json, no git metadata, no credentials: the
# portal rejects reviewer credentials in a package, and they go in its Review
# details form instead.
#
#   scripts/package.sh            → dist/ravenpost-<version>.zip
#
# Changes to the hosted tools need no new ZIP (the portal rescans the server);
# changes to plugin.json, mcp.json, skills/ or assets/ do, with a new version.
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(python3 -c 'import json; print(json.load(open("plugin.json"))["version"])')
mkdir -p dist
out="dist/ravenpost-${version}.zip"
rm -f "$out"
zip -q -r -X "$out" plugin.json mcp.json skills assets LICENSE -x '*.DS_Store'
echo "$out"
