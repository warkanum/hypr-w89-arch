#!/usr/bin/env bash
# Use the same named-theme installer as the standalone workflow.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$here/sddm-theme.sh" set --theme "${SDDM_THEME:-stargate}" "$@"
