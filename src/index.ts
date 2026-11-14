/**
 * TYPO3 for Webship Workspace: a platform plugin.
 *
 * What the package carries is placed by the installer from the manifest: the builder and the
 * typo3 console tool in the sites folders, their functions and argparse under core/scripts/plugins/typo3/,
 * the agents in the AI Agents folder. The dashboard needs nothing drawn for it: the builder is in the
 * Build list because it is a cmd-*-project.sh, the row menus are the core's, the agents are listed
 * like any other. What register() adds is what the assistant is told.
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from the
 * dashboard's own files, so it can be installed from npm and removed without a trace.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';

/** The plugin's name, which is also the DDEV project type its functions are named after. */
export const PLATFORM = 'typo3';

/** The commands the installer places in every sites folder. */
export const COMMANDS = ['cmd-typo3-project.sh', 'cmd-tools-typo3-cli.sh'];

/** The agents the installer places in the AI Agents folder. */
export const AGENTS = ['typo3-site-builder', 'typo3-tester'];

/** What the assistant is told about TYPO3 in this workspace. */
export function assistantContext(): string {
  return [
    'TYPO3 (a plugin, @webship.co/workspace-typo3): a TYPO3 site is built with',
    '`bash cmd-typo3-project.sh <name> --install --add-users` from a sites folder (dev, test, sandboxes, demos),',
    'in a container like every other project, at https://<name>.ddev.site (the backend at /typo3); --install sets TYPO3 13.4 LTS up',
    'with the Introduction package (a site with pages and content), --bare leaves that package out.',
    '`bash cmd-tools-typo3-cli.sh <name>` says what the site is; `--run "<command>"` runs the typo3 console (vendor/bin/typo3) in it,',
    '`--update` updates the Composer packages, `--flush` flushes the caches, `--add-users` adds the default accounts (an administrator and an editor).',
    '`bash cmd-tools-testing.sh <name>` sets up webship-js with the TYPO3 step pack; `--run` runs the suite.',
    `For TYPO3 work, hand over to the agents ${AGENTS.map((a) => `\`${a}\``).join(' and ')}.`,
    'Never run php, composer, npm or mysql on the host for a project.',
  ].join(' ');
}

export function register(api: PluginApi): void {
  api.addAssistantContext(assistantContext);
}
