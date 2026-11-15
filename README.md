# @webship.co/workspace-typo3

TYPO3 for the [Webship Workspace](https://github.com/webship/workspace) dashboard: a builder
that makes a real TYPO3 site in a container, a typo3 console tool for the sites it built, the default
accounts, the [TYPO3 step pack](https://github.com/webship/typo3-steps) wired into the
workspace's testing setup, and its AI items — two agents, a skill, a command and a prompt —
each listed in the workspace folder of its kind.

The workspace is container-based (DDEV by default): a TYPO3 project is a row like any other, so
the row menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it unchanged.

It is made from the reference platform plugin,
[`@webship.co/workspace-wordpress`](https://github.com/webship/workspace-wordpress).

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require github:webship/workspace-typo3   # npm install into the dashboard
bash core/scripts/plugins.sh --activate typo3                            # plugins.typo3 in settings.yml
bash core/scripts/plugins.sh --install typo3                             # commands, functions, args, AI items
bash core/scripts/plugins.sh --configure typo3                           # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an AI item you edited stays.

Everything the plugin carries lands in the folder it belongs to, when that folder is an active
workspace folder:

| What | Lands in |
| --- | --- |
| `cmd-typo3-project.sh`, `cmd-tools-typo3-cli.sh` | every active sites folder: `dev/`, `test/`, `sandboxes/`, `demos/` |
| The agents `typo3-site-builder`, `typo3-tester` | `ai-agents/` |
| The skill `typo3-scenarios` | `ai-skills/` |
| The command `/typo3-test` | `ai-commands/` |
| The prompt `typo3-build-and-test` | `ai-prompts/` |

There they are listed like any other item of the folder, and installed into Claude Code from there.

It needs a Webship Workspace 1.0.7 or later.

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder, for the builder and the tool: `dev`, `test`, `sandboxes`, `demos` (`dev` is the one added when none is there). The folder also carries `cmd-tools-testing.sh` and the Users tools this plugin's hooks answer to.
- `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`: the AI folders its agents, its skill, its command and its prompt are placed in.

`--require` says so, `--activate` and `--install` stop until the workspace has them, and `--with-needs` adds what is missing first:

```bash
bash core/scripts/plugins.sh --activate typo3 --with-needs   # dev and the four AI folders are required, activated and installed first
bash core/scripts/plugins.sh --install typo3
```

Everything the builder runs for a site runs in the site's own container, through the container tool the workspace already needs; the plugin asks for no command of its own on the machine.

A workspace that knows none of this (Webship Workspace 1.0.8 and older) ignores the keys: add a sites folder and the AI folders yourself, then `--install typo3` again. A kind whose folder is not there is skipped, and the install says so.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-typo3-project.sh` | The builder, in the Build list as **TYPO3 (13.4 LTS)**, installed into every sites folder |
| `commands/cmd-tools-typo3-cli.sh` | The typo3 console for one project: what the site is, a command, updates, caches, the default accounts |
| `scripts/functions/fun-typo3.sh` | The bash functions behind both, sourced by bootstrap once installed; the names the core's tools look for (`set_typo3_users`, `add_typo3_users`, `cancel_typo3_users`, `testing_configure_typo3`) |
| `scripts/args/arg-typo3.sh`, `arg-typo3-cli.sh` | Their argparse; the Build form draws the builder's flags from the first |
| `testing/site.feature` | The first feature a TYPO3 project gets when testing is set up |
| `ai/agents/typo3-site-builder.md` | The agent that builds and maintains TYPO3 sites with these commands |
| `ai/agents/typo3-tester.md` | The agent that writes and runs scenarios with the TYPO3 step pack |
| `ai/skills/typo3-scenarios/` | The skill: the step pack's phrases by area, the traps found on a real site, three example features |
| `ai/commands/typo3-test.md` | The slash command `/typo3-test <site>`: set up, match every step, run, report |
| `ai/prompts/typo3-build-and-test.md` | The prompt: a whole launch command for a new session |
| `docs/plugin-items-pattern.md` | How a plugin carries its own commands and AI items, and how to prove it |
| `src/index.ts` | `register(api)`: what the assistant is told about TYPO3 here |
| `features/typo3.feature` | Scenarios for the dashboard's own browser suite |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## The commands

Run them from a sites folder. `--help` is safe on both.

### Build a site

```bash
cd ~/workspace/dev
bash cmd-typo3-project.sh mysite --install --add-users
```

| Flag | What it does |
| --- | --- |
| `--version <x>` | The release to create the project from, as a Composer constraint of `typo3/cms-base-distribution`: `^13.4` (the default, TYPO3 13.4 LTS), or a number such as `13.4.20` |
| `--install` | Set the site up, with the workspace account as its administrator, and add the official Introduction package: a site with pages, content and a search |
| `--add-users` | With `--install`: add the default accounts, an administrator and an editor |
| `--bare` | With `--install`: leave the Introduction package out (a backend, and no site or page yet) |
| `--php-version <x>` | The PHP of the project container (`8.3`) |
| `--launch` | Open the site when it is ready |

The site answers at `https://mysite.ddev.site`, the backend at `/typo3`. The build runs
`ddev config --project-type=typo3` with the docroot `public` and the Node.js of the workspace (24),
creates the project with Composer in the container (`typo3/cms-base-distribution`), and sets it up
with TYPO3's own `setup` command. The setup is given the container's database values
(`db` / `db` / `db`), the same in every project, and nothing personal. A project of the same name
is deleted first.

The Introduction package (`typo3/cms-introduction`, on the Bootstrap Package theme) is the site the
step pack is written for; with it the build also runs the upgrade wizard its search content needs
and points the search results at the templates of Indexed Search.

TYPO3 asks for an administrator password of 8 characters or more, with an upper and a lower case
letter, a digit and a sign: the setup stops when the workspace account's does not pass.

### Work on a site

```bash
bash cmd-tools-typo3-cli.sh mysite                                    # version, address, sites, backend accounts
bash cmd-tools-typo3-cli.sh mysite --run "extension:list --active"
bash cmd-tools-typo3-cli.sh mysite --run "list"                       # every command of the console
bash cmd-tools-typo3-cli.sh mysite --flush                            # flush every cache
bash cmd-tools-typo3-cli.sh mysite --update                           # Composer packages, extension setup, caches
bash cmd-tools-typo3-cli.sh mysite --add-users                        # the default accounts
bash cmd-tools-typo3-cli.sh mysite --cancel-users                     # delete them
```

### The default accounts

| Account | Role | Handle in the tests |
| --- | --- | --- |
| `administrator` | administrator (not a system maintainer: the Extensions module and the Admin Tools stay with the workspace account) | `admin` |
| `editor` | the backend group "Advanced editors" (from the Introduction package) | `editor` |

Each has the address `<account>@example.com` and the password of the workspace's other default
lists. They are for local sites and for tests; the site's own administrator is the workspace
account and is never written into a test. The row's Users menu (**Add the test users**),
`bash cmd-tools-add-users.sh mysite typo3` and `bash cmd-tools-cancel-users.sh mysite typo3` add
and remove the same list. On a site without the Introduction package the editor is created without
a group.

### Test a site

```bash
bash cmd-tools-testing.sh mysite                 # webship-js, the step pack, the users registry, a first feature
bash cmd-tools-testing.sh mysite --run           # run the suite in the container
bash cmd-tools-testing.sh mysite --run --path tests/features/site.feature
```

`cmd-tools-testing.sh` is the workspace's own. For a TYPO3 project it also adds
`@webship-js/typo3-steps` to `package.json`, lists its step definitions in `cucumber.js` after
webship-js's own, writes the users registry (the handles above, overridable with
`TYPO3_<HANDLE>_USER` and `TYPO3_<HANDLE>_PASS`), places `tests/features/site.feature` when the
project has none, and makes sure the default accounts are on the site. Run it again and it adds what
is missing and keeps what you changed.

## The AI items

`ai/` in the package holds one folder per kind, the manifest's `ai` block names each item, and
`--install` places it in the workspace folder of that kind.

| Kind | Item | Use it to |
| --- | --- | --- |
| Agent | `typo3-site-builder` | Build, update, maintain or remove a TYPO3 site with the commands above, in containers only |
| Agent | `typo3-tester` | Set the testing stack up, look at the site in the Playwright MCP browser first, write scenarios from the pack's steps and run them; it never creates an account in a suite and never writes a platform name into a step phrase |
| Skill | `typo3-scenarios` | Write a scenario from phrases that exist: the pack's steps by area (the backend and its modules, the page tree, records and content elements, the public site), the handles of the users registry, the traps found on a real site, and three features that pass on a fresh site |
| Command | `/typo3-test <site> [feature or @tag]` | Run the suite of a site from inside a session: set up when missing, match every step, run, report what failed and why |
| Prompt | `typo3-build-and-test` | Start a session that builds a site with the Introduction package, says what it is, sets the testing stack up and runs the first feature |

After `--install` each is in its folder on the dashboard. **Install** there puts an agent, a skill
or a command into Claude Code (`~/.claude/agents`, `~/.claude/skills`, `~/.claude/commands`), or
from the command line:

```bash
cd ~/workspace/ai-agents   && bash cmd-tools-ai-items.sh typo3-tester --install
cd ~/workspace/ai-skills   && bash cmd-tools-ai-items.sh typo3-scenarios --install
cd ~/workspace/ai-commands && bash cmd-tools-ai-items.sh typo3-test --install
```

A prompt is not installed: it is the whole `claude …` launch command of a new session, and the
dashboard's **New screen** form lists it as a template. By hand, fill the placeholders in and run
the command of the file from the folder it names.

The items are written for any AI CLI, with Claude Code as the default shape: the frontmatter and
the file layout are Claude Code's, the body of each item is plain Markdown that names no tool or
feature of one CLI, a command says in words what its arguments are, and the text between the
triple quotes of a prompt can be given to another AI CLI as it is.

Every step phrase the items show is checked against the definitions of the step pack and of
webship-js (`tests/fixtures/step-definitions.txt`), and every command and flag against the
plugin's own. The shape is the reference's: [`docs/plugin-items-pattern.md`](docs/plugin-items-pattern.md).

## Develop it

```bash
npm install     # builds dist/ (TypeScript)
npm run lint
npm test        # the manifest, the commands, the AI items, the functions against a scaffolded project
```
