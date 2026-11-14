#!/usr/bin/env bash

# Installed by the TYPO3 plugin (plugins.sh --install typo3); __WORKSPACE__ is the workspace it was installed into.
#
# The typo3 console (vendor/bin/typo3) for one TYPO3 project of this workspace, in its container:
# say what the site is, run a console command, update the packages, flush the caches, add or
# remove the default accounts. Nothing here runs on the host.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="typo3";

ARGPARSE_DESCRIPTION="Run the typo3 console on a TYPO3 project of __WORKSPACE__: status, a command, updates, caches, the default accounts"
# The args file comes with the plugin: core/scripts/plugins/typo3/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/typo3/args/arg-typo3-cli.sh || exit 1 ;

shift $#;

typo3_cli_tool ;
