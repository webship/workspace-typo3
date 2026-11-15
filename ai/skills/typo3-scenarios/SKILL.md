---
name: typo3-scenarios
description: Write and run webship-js scenarios for a TYPO3 site of the Webship Workspace with the TYPO3 step pack (`@webship-js/typo3-steps`) — the phrases of the pack by area (the backend session and its modules, the page tree, records and content elements, the public site with its menus, breadcrumb, languages and search), the handles of the users registry, and the workspace command that runs them in the site's container. Use when asked to "write a scenario for this TYPO3 site", "test the editor account", "which step is there for the page tree", "add a feature for creating a page", or when a `.feature` file of a TYPO3 project is being written or fixed.
argument-hint: '<site> [what to cover]'
---

# typo3-scenarios

Scenarios for a TYPO3 site of a Webship Workspace (`~/workspace`, container-based, DDEV by
default), written from the steps of [`@webship-js/typo3-steps`](https://github.com/webship/typo3-steps)
and of [webship-js](https://github.com/webship/webship-js) itself, and run in the site's container
by the workspace's own command. It comes with the TYPO3 plugin (`@webship.co/workspace-typo3`),
like the builder (`cmd-typo3-project.sh`), the console tool (`cmd-tools-typo3-cli.sh`) and the
agents `typo3-site-builder` and `typo3-tester`.

## Where everything is

| What | Where |
| --- | --- |
| The site | `~/workspace/<folder>/<site>`, at `https://<site>.ddev.site`, the backend at `/typo3` (`<folder>` is a sites folder: `dev`, `test`, `sandboxes`, `demos`) |
| The suite's configuration | `<site>/cucumber.js`: the step definitions it loads and the users registry (`worldParameters.users`) |
| The features | `<site>/tests/features/*.feature` (`site.feature` is the first one the setup wrote) |
| The pack's steps | `<site>/node_modules/@webship-js/typo3-steps/tests/step-definitions/*.steps.js` |
| The pack's own features | `<site>/node_modules/@webship-js/typo3-steps/tests/features/*.feature`: written for the same Introduction package, worth reading before writing one |
| webship-js's steps | `<site>/node_modules/webship-js/tests/step-definitions/*.js` |
| The reports | `<site>/tests/reports/` |

## The order of work

1. **Make sure the testing stack is there.** From the sites folder:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site>
   ```
   It adds webship-js, the step pack, the users registry and `tests/features/site.feature`, and
   makes sure the default accounts are on the site. It is safe to run again: it adds what is
   missing and keeps what was changed.
2. **Read the installed steps before writing a phrase.** They are the source of truth: the pack
   moves, and a phrase from memory is a guess.
   ```bash
   cd ~/workspace/<folder>/<site>
   grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/typo3-steps/tests/step-definitions/*.steps.js
   ```
   Every step carries a comment block with examples above it; open the file when a phrase is not
   obvious.
3. **Look at the page first** (the Playwright MCP browser, a tab of your own) when the scenario
   is about a screen you have not seen. A scenario written without having seen the page asserts
   what you imagine.
4. **Write the feature** in `<site>/tests/features/`, from phrases that exist (the lists below).
5. **Match every step without a browser**, then run the feature, then the suite:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --tags "@critical"
   bash cmd-tools-testing.sh <site> --run
   ```
   A dry run says `Undefined` for a phrase no definition matches: fix the phrase, do not write a
   step for it.

## Accounts: a handle, never a password

A scenario logs in to the backend by a handle of the users registry. The default accounts are on
the site already (`bash cmd-tools-typo3-cli.sh <site> --add-users` adds them again if they were
removed):

| Handle | Account | Role |
| --- | --- | --- |
| `admin` | `administrator` | administrator (not a system maintainer) |
| `editor` | `editor` | the backend group "Advanced editors" of the Introduction package |

```gherkin
Given I am a logged in user with the "editor" user
Then I should be logged in as "editor"
```

## The phrases, by area

Each line is a phrase the pack defines, and each one passed on a site built with
`bash cmd-typo3-project.sh <site> --install --add-users` (TYPO3 with the Introduction package; the
names in quotes are that site's). Most `should` steps also take the negative: `should not see`,
`should not be`.

### The backend: session and modules

```gherkin
Given I am a logged in user with the "editor" user
Given I am not logged in
When I log out
Then I should be logged in as "editor"
Then I should not be logged in
Then I should not see a login error
When I open the "Page" module
Then the "Page" module should be active
Then I should see the "List" module
Then I should not see the "Backend Users" module
Then the module heading should be "Create new Page"
```

### The page tree

```gherkin
Then I should see the "Congratulations" page in the page tree
When I search the page tree for "Rich Text"
When I select the "Congratulations > 404" page in the page tree
When I choose "New subpage" from the context menu of the "Congratulations > 404" page
When I choose "Enable" from the context menu of the "Congratulations > 404 > A new page" page
When I choose "Delete" from the context menu of the "Congratulations > 404 > A new page" page
Then the "Congratulations > 404 > A new page" page should be hidden in the page tree
Then I should not see the "Congratulations > 404 > A new page" page in the page tree
Given there is no "Congratulations > 404 > A new page" page
```

### Records and content elements

```gherkin
When I fill in the "Page Title" record field with "A new page"
When I save the record
When I close the record
Then I should see the notification "Record saved"
Then the "Page Title" record field should be marked as invalid
When I confirm the dialog
When I add a "Header Only" content element to the "Normal" column
When I fill in the "Header" record field with "A header written by a scenario"
Then I should see the "A header written by a scenario" content element in the page module
```

### The public site

```gherkin
Then I should see the "Features" menu item
When I open the "Features" menu item
Then the "Features" menu item should be active
Then I should see the "Search" subnavigation item
When I open the "Search" subnavigation item
Then I should be viewing the "Search" page
Then I should see the breadcrumb
Then the breadcrumb should contain "Content Examples"
Then the "Deutsch" language should be available
When I switch to the "Deutsch" language
When I search the site for "zzzqqqxyz"
Then I should see no search results
Then I should be on the 404 page
```

`I am an anonymous user`, `I am on the homepage`, `I am on "<path>"`, `I should be on "<path>"`,
`the page language should be "<code>"`, `I should see "<text>"` and
`the response status code should be 200` are webship-js's own steps; its status codes, classes,
landmarks and accessibility audits are used as they are and never redefined for this platform.

## Traps found on a real site

- **A page is named by its path in the page tree**, from the root: `"Congratulations > 404 > A
  new page"`. A title alone finds only a page that is already shown.
- **The page tree steps need the backend and a module of the Web group.**
  `Given there is no "<path>" page` before the login, or before `I open the "Page" module`, fails:
  log in, open the module, then clear.
- **A new page is hidden**, and a logged in backend user previews hidden pages. Enable the page
  from its context menu, and drop the session (`Given I am not logged in`) before asserting what a
  visitor sees.
- **`I should be viewing the "<title>" page` reads the `h1`.** On a landing page of the
  Introduction package the `h1` is a slogan, not the page title: after
  `I open the "Features" menu item` assert `I should be on "/features"` and
  `the "Features" menu item should be active`. On a content page (`"Search"`) the step works.
- **The start page has no breadcrumb**: `I should not see the breadcrumb` passes there.
- **The pages, the menu and the translations are the Introduction package's.** A site built with
  `--bare` has a backend and no page: the public-site phrases and every page path above fail
  there.
- **`admin` is an administrator and not a system maintainer**: no Extensions module and no Admin
  Tools. A scenario about those needs another account, asked for, not made.
- **The generator is a value of a step**, not a part of its phrase: `the page generator should
  start with "TYPO3"`, `the page generator should be "TYPO3 CMS"`. The meta tag carries no
  version: read the version with `bash cmd-tools-typo3-cli.sh <site>`.
- A scenario that failed after it created a page left it behind: start the scenario with
  `Given there is no "<path>" page`, so the next run clears it.

## Rules

- **No account is created in a suite.** No `backend:user:create` in a hook, no step that adds an
  account. A role the registry does not have is asked for, not made.
- **Never the workspace account.** The site's own administrator is not in the registry; `admin`
  is the `administrator` default account.
- **No password in a feature file**, except where a wrong password is the subject.
- **No platform name in a step phrase**: `I open the "Page" module`, never a phrase that names
  the platform. The same holds for a custom step.
- **No selector when a step says it**: `the "Page" module`, `the "Header" record field`, not
  their classes.
- **What a scenario creates, it removes** in the same scenario, under a title nobody else uses.
- **A custom step is the last resort**: look in the pack and in webship-js first, write it in
  `<site>/tests/step-definitions/` with a comment block and examples, and say it may belong in
  the pack.
- **Everything runs in the container**, through `cmd-tools-testing.sh`. Never `npx cucumber-js`
  or `npx playwright` on the host.
- **A failing scenario is a result.** No `@wip`, no longer timeout, no looser assertion to turn a
  run green: say what the site did.

## Examples that run

`examples/` holds three features that pass on a site built with
`bash cmd-typo3-project.sh <site> --install --add-users`. Copy one into the suite and run it:

```bash
cp ~/workspace/ai-skills/typo3-scenarios/examples/modules-and-accounts.feature ~/workspace/<folder>/<site>/tests/features/
cd ~/workspace/<folder>
bash cmd-tools-testing.sh <site> --run --path tests/features/modules-and-accounts.feature
```

| Feature | What it shows |
| --- | --- |
| `examples/modules-and-accounts.feature` | The modules of the editor and of the administrator, a search of the page tree, the end of a session |
| `examples/page-lifecycle.feature` | A page created, enabled, given a content element, seen by a visitor and deleted; a page refused without a title |
| `examples/site-navigation.feature` | The main menu, the subnavigation, the breadcrumb, a translation, the 404 page and an empty search |
