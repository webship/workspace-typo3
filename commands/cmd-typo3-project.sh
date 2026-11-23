#!/usr/bin/env bash

# workspace-name: TYPO3 (13.4 LTS)

# Installed by the TYPO3 plugin (plugins.sh --install typo3); __WORKSPACE__ is the workspace it was installed into.
#
# Build a TYPO3 site in a container: TYPO3 13.4 LTS, or the release --version names, on DDEV (the default) at https://<name>.ddev.site, or
# with --runtime docker, podman, kubernetes, lando or docksal at the address the build prints. With --install the site is set up with the workspace account as its
# administrator and gets the official Introduction package (a site with pages and content); with
# --add-users it also gets the default accounts, an administrator and an editor.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Set site version.
site_version="^13.4";

# Distribution.
distribution_name="typo3";
distribution_title="TYPO3";
distribution_webroot="public";
project_template="typo3/cms-base-distribution";

ARGPARSE_DESCRIPTION="Build a ${distribution_title} project in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/typo3/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/typo3/args/arg-typo3.sh || exit 1 ;

shift $#;

typo3_build ;
