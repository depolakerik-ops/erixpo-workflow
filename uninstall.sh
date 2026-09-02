#!/usr/bin/env bash
# Remove the erixpo pack this repo installed into a project.
# Wrapper around install.sh --uninstall so agents can find a file named uninstall.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec bash "$HERE/install.sh" --uninstall "$@"
