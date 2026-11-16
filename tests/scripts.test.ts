import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { spawnSync } from 'child_process';

// Compiled, these tests run from dist/tests, so the package root is one folder further up.
const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const FUNCTIONS = path.join(PKG, 'scripts', 'functions', 'fun-typo3.sh');

// The cucumber.js webship-js scaffolds, as far as the testing hook reads it.
const SCAFFOLD = `module.exports = {
  default: {
    requireModule: ['ts-node/register'],
    require: [
      'node_modules/webship-js/tests/step-definitions/**/*.js',          // Webship-js core step definitions.
      'tests/step-definitions/**/*.js',                                  // Your custom step definitions.
    ],
    paths: ['tests/features/**/*.feature'],
    worldParameters: {
      launchUrl: process.env.LAUNCH_URL || 'http://localhost:8080',
    },
  },
};
`;

/** A project folder with the testing stack scaffolded, and the tooling folder the installer would have filled. */
function project(type: string) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'typo3-plugin-'));
  const dir = path.join(root, 'dev', 'site1');
  fs.mkdirSync(path.join(dir, '.ddev'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.ddev', 'config.yaml'), `name: site1\ntype: ${type}\ndocroot: public\n`);
  // A site that is set up has its settings file.
  fs.mkdirSync(path.join(dir, 'config', 'system'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'config', 'system', 'settings.php'), '<?php\n');
  fs.writeFileSync(path.join(dir, 'cucumber.js'), SCAFFOLD);
  fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify({ name: 'site1', devDependencies: { 'webship-js': '^2.0.6' } }, null, 2));
  const scripts = path.join(root, 'core', 'scripts');
  fs.mkdirSync(path.join(scripts, 'plugins', 'typo3'), { recursive: true });
  fs.copyFileSync(path.join(PKG, 'testing', 'site.feature'), path.join(scripts, 'plugins', 'typo3', 'site.feature'));
  return { root, dir, scripts };
}

/**
 * Run bash with the plugin's functions sourced and `ddev` replaced by a recorder. The database answers from
 * DDEV_DB: lines of `<words in the query> => <answer>`, so a test says which accounts and groups the site has.
 */
function bash(script: string, env: Record<string, string> = {}) {
  const fake = `ddev() { echo "ddev $*" >> "\${DDEV_LOG:-/dev/null}" ; if [ "$1" == "mysql" ] ; then local row ; while IFS= read -r row ; do [ -n "$row" ] || continue ; case "$*" in *"\${row%% => *}"*) echo "\${row#* => }" ; return 0 ;; esac ; done <<< "\${DDEV_DB:-}" ; case "$*" in *COUNT*) echo 0 ;; esac ; fi ; return 0 ; }`;
  const r = spawnSync('bash', ['-c', `${fake}\nsource ${FUNCTIONS}\n${script}`],
    { encoding: 'utf8', env: { ...process.env, ...env } });
  return r;
}

test('the default accounts are an administrator and an editor, with example addresses', () => {
  const r = bash('set_typo3_users ; for u in "${users[@]}" ; do n="user_${u}_name" ; m="user_${u}_mail" ; p="user_${u}_password" ; l="user_${u}_role" ; echo "${!n}|${!m}|${!p}|${!l}" ; done');
  assert.strictEqual(r.status, 0, r.stderr);
  const rows = r.stdout.trim().split('\n').map((l) => l.split('|'));
  assert.deepStrictEqual(rows.map((x) => x[0]), ['administrator', 'editor']);
  assert.deepStrictEqual(rows.map((x) => x[3]), ['admin', 'Advanced editors']);
  for (const [name, mail, password] of rows) {
    assert.strictEqual(mail, `${name}@example.com`);
    assert.match(password, /[a-z]/); assert.match(password, /[A-Z]/); assert.match(password, /[0-9]/); assert.match(password, /[^A-Za-z0-9]/);
    assert.ok(password.length >= 8, 'the password passes the rules of the platform');
  }
});

test('the testing hook adds the step pack, the users registry and a first feature to a TYPO3 project, once', () => {
  const p = project('typo3');
  const log = path.join(p.root, 'ddev.log');
  const run = () => bash(`cd ${p.dir} && testing_configure_typo3 ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1', DDEV_LOG: log, DDEV_DB: 'be_groups => 7' });
  const r = run();
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const pkg = JSON.parse(fs.readFileSync(path.join(p.dir, 'package.json'), 'utf8'));
  assert.strictEqual(pkg.devDependencies['@webship-js/typo3-steps'], '^2.2.0');
  assert.strictEqual(pkg.devDependencies['webship-js'], '^2.0.6', 'what was there stays');
  const cucumber = fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8');
  const lines = cucumber.split('\n');
  const core = lines.findIndex((l) => l.includes('node_modules/webship-js/tests/step-definitions'));
  assert.strictEqual(lines[core + 1], "      'node_modules/@webship-js/typo3-steps/tests/step-definitions/**/*.js',", 'the pack is listed right after webship-js');
  assert.match(cucumber, /admin: \{ username: process\.env\.TYPO3_ADMIN_USER \|\| 'administrator', password: process\.env\.TYPO3_ADMIN_PASS \|\| '[^']+' \},/);
  assert.match(cucumber, /editor: \{ username: process\.env\.TYPO3_EDITOR_USER \|\| 'editor', password: process\.env\.TYPO3_EDITOR_PASS \|\| /);
  // Still a module node can load, with the registry where webship-js reads it.
  const loaded = spawnSync(process.execPath, ['-e', `const c = require(${JSON.stringify(path.join(p.dir, 'cucumber.js'))}).default; console.log(JSON.stringify([c.require, Object.keys(c.worldParameters.users)]))`], { encoding: 'utf8' });
  assert.strictEqual(loaded.status, 0, loaded.stderr);
  const [requires, handles] = JSON.parse(loaded.stdout);
  assert.strictEqual(requires.length, 3);
  assert.deepStrictEqual(handles, ['admin', 'editor']);
  assert.ok(fs.existsSync(path.join(p.dir, 'tests', 'features', 'site.feature')));
  const calls = fs.readFileSync(log, 'utf8');
  assert.match(calls, /ddev exec vendor\/bin\/typo3 backend:user:create --no-interaction --username=administrator --password=\S+ --email=administrator@example\.com --admin\n/, 'a site that is set up gets the administrator');
  assert.match(calls, /backend:user:create --no-interaction --username=editor --password=\S+ --email=editor@example\.com --groups=7\n/, 'and the editor, in the group looked up by its title');
  // Again, after a person changed the feature: nothing is doubled, nothing is reset.
  fs.writeFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'Feature: mine\n');
  assert.strictEqual(run().status, 0);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), cucumber);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'utf8'), 'Feature: mine\n');
});

test('the testing hook leaves a project of another platform alone', () => {
  const p = project('drupal11');
  const r = bash(`cd ${p.dir} && testing_configure_typo3 ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stdout, '');
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), SCAFFOLD);
  assert.ok(!fs.existsSync(path.join(p.dir, 'tests')));
});

test('the CLI tool refuses a project that is not TYPO3', () => {
  const p = project('drupal11');
  const r = bash('PROJECT_NAME=site1 ; RUN="cache:flush" ; trim_project_name() { :; } ; typo3_cli_tool', { WORKSPACE_ROOT: p.root, doc_name: 'dev' });
  assert.strictEqual(r.status, 1);
  assert.match(r.stdout, /is not a TYPO3 project/);
});

test('an account that is already on the site is left as it is, and an editor without its group is still created', () => {
  const p = project('typo3');
  const log = path.join(p.root, 'ddev.log');
  // The administrator is there; no group has the title the editor asks for.
  const r = bash('PROJECT_NAME=site1 ; set_typo3_users ; add_typo3_users', { WORKSPACE_ROOT: p.root, doc_name: 'dev', DDEV_LOG: log, DDEV_DB: "username = 'administrator' => 1" });
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /administrator is already there/);
  assert.match(r.stdout, /no backend group "Advanced editors"/);
  const calls = fs.readFileSync(log, 'utf8');
  assert.doesNotMatch(calls, /backend:user:create .*--username=administrator /);
  assert.match(calls, /backend:user:create --no-interaction --username=editor --password=\S+ --email=editor@example\.com\n/);
});

test('the default accounts are deleted from the database of the project, and only they', () => {
  const p = project('typo3');
  const log = path.join(p.root, 'ddev.log');
  const r = bash('PROJECT_NAME=site1 ; set_typo3_users ; cancel_typo3_users', { WORKSPACE_ROOT: p.root, doc_name: 'dev', DDEV_LOG: log, DDEV_DB: "username = 'editor' => 1" });
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /administrator is not there/);
  const deletes = fs.readFileSync(log, 'utf8').split('\n').filter((l) => /DELETE/.test(l));
  assert.deepStrictEqual(deletes, ["ddev mysql -e DELETE FROM be_users WHERE username = 'editor'"]);
});

test('the first feature names no platform in a step, and no password', () => {
  const feature = fs.readFileSync(path.join(PKG, 'testing', 'site.feature'), 'utf8');
  const steps = feature.split('\n').filter((l) => /^\s*(Given|When|Then|And|But) /.test(l));
  assert.ok(steps.length >= 10);
  for (const s of steps) assert.doesNotMatch(s, /typo3/i, s);
  assert.doesNotMatch(feature, /password "/);
  assert.doesNotMatch(feature, /user create|I register/i, 'a suite never creates an account');
});

test('every --run "extension:list …" example of the package uses an option the command has', () => {
  // TYPO3 13.4: `extension:list [-a|--all] [-i|--inactive]`. It lists the active extensions by default;
  // there is no --active option, and an example with it ends in an error.
  const known = ['--all', '-a', '--inactive', '-i'];
  const files = ['README.md', 'scripts/args/arg-typo3-cli.sh', 'scripts/functions/fun-typo3.sh',
    ...fs.readdirSync(path.join(PKG, 'ai', 'agents')).map((f) => `ai/agents/${f}`)];
  let examples = 0;
  for (const rel of files) {
    const text = fs.readFileSync(path.join(PKG, rel), 'utf8');
    for (const m of text.matchAll(/extension:list((?: +-{1,2}[a-z-]+)*)/g)) {
      examples += 1;
      for (const option of m[1].trim().split(/ +/).filter(Boolean)) {
        assert.ok(known.includes(option), `${rel}: extension:list has no ${option} option`);
      }
    }
  }
  assert.ok(examples >= 3, 'the help, the README and the agent each give the example');
});
