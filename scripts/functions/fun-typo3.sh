#!/usr/bin/env bash

# TYPO3 for the Webship Workspace: build a site, run the typo3 console on it, add its default
# accounts, and wire its step pack into the testing setup.
#
# Placed by `plugins.sh --install typo3` in core/scripts/plugins/typo3/functions/, where
# bootstrap sources it after the core's own functions. Everything runs in the project's container
# (DDEV by default: `ddev composer …`, `ddev exec vendor/bin/typo3 …`), never on the host. The
# setup command is given the container's own database values (db / db / db) and nothing personal.
#
# Four names are the ones the core's tools look for, under the DDEV project type `typo3`:
#   set_typo3_users        the default accounts            (cmd-tools-add-users.sh <project> typo3)
#   add_typo3_users        create them with the console    (the same tool, and --add-users of the builder)
#   cancel_typo3_users     delete them                     (cmd-tools-cancel-users.sh <project> typo3)
#   testing_configure_typo3  the step pack in the testing stack (cmd-tools-testing.sh <project>)

# The step pack a TYPO3 project is tested with, and the release line it is required at.
readonly TYPO3_STEPS_PACKAGE='@webship-js/typo3-steps';
readonly TYPO3_STEPS_VERSION='^2.1.0';

# The backend group the editor account joins: the one the Introduction package brings.
readonly TYPO3_EDITOR_GROUP='Advanced editors';

# The default accounts: an administrator and an editor, the ones a scenario logs in as. Accounts
# are configuration, created once on the site; a test suite never creates or deletes one. The
# role is `admin` for an administrator, or the title of a backend group.
function set_typo3_users() {
  users=(administrator editor);
  local roles=('admin' "${TYPO3_EDITOR_GROUP}") i user ;
  for i in "${!users[@]}" ; do
    user="${users[$i]}" ;
    printf -v "user_${user}_name" '%s' "${user}" ;
    printf -v "user_${user}_mail" '%s' "${user}@example.com" ;
    printf -v "user_${user}_password" '%s' 'dD.123123ddd' ;
    printf -v "user_${user}_role" '%s' "${roles[$i]}" ;
  done
}

# Is this folder a TYPO3 project? Its DDEV project type says so.
function typo3_is_project() {
  local project_path="$1";
  grep -qE '^type:[[:space:]]*"?typo3"?[[:space:]]*$' "${project_path}/.ddev/config.yaml" 2>/dev/null ;
}

# Is the site set up? The setup command writes config/system/settings.php, and nothing else does.
function typo3_is_installed() {
  [ -f "$1/config/system/settings.php" ] ;
}

# Go to the project a tool was asked about, or say why not.
function typo3_enter_project() {
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}";
  if [ ! -d "${project_path}" ] ; then
    echo "No project ${PROJECT_NAME} in ${WORKSPACE_ROOT}/${doc_name}." ;
    return 1 ;
  fi
  if ! typo3_is_project "${project_path}" ; then
    echo "${doc_name}/${PROJECT_NAME} is not a TYPO3 project (its .ddev/config.yaml does not say type: typo3)." ;
    return 1 ;
  fi
  cd "${project_path}" || return 1 ;
}

# Run the typo3 console in the container of the project the shell is in. Every argument is
# quoted for the container's shell, so a password with a sign in it arrives as one argument.
function typo3_cli() {
  local line="vendor/bin/typo3" arg ;
  for arg in "$@" ; do
    line="${line} $(printf '%q' "${arg}")" ;
  done
  ddev exec "${line}" ;
}

# One value from the project's database, read in its container.
function typo3_query() {
  ddev mysql -N -B -e "$1" 2>/dev/null | tr -d '\r' | head -1 ;
}

# Is there a backend account of this username on the site?
function typo3_user_exists() {
  [ "$(typo3_query "SELECT COUNT(*) FROM be_users WHERE username = '$1' AND deleted = 0")" == '1' ] ;
}

# Build a TYPO3 site from nothing: the container, the code, and with --install the site itself.
function typo3_build() {
  trim_project_name ;
  local base_url="https://${PROJECT_NAME}.ddev.site" ;
  local version="${VERSION:-${site_version:-^13.4}}" ;
  local php_version="${PHP_VERSION:-${site_php_version:-8.3}}" ;

  cd ${WORKSPACE_ROOT}/${doc_name} || exit 1 ;

  drop_database ;
  rm -rf "${PROJECT_NAME}" ;
  mkdir -p "${PROJECT_NAME}" ;
  cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;

  ddev config --project-type=typo3 --docroot="${distribution_webroot}" --project-name=${PROJECT_NAME} \
    --php-version=${php_version} --nodejs-version=$(ddev_nodejs_version) --auto || exit 1 ;
  ddev_up start -y || exit 1 ;

  ddev composer create-project "${project_template}:${version}" . --no-interaction \
    || { echo "composer create-project ${project_template}:${version} failed." ; exit 1 ; } ;

  if [ "${INSTALL}" == 'yes' ] ; then
    # The container's own database values, the same in every project: nothing personal is written.
    typo3_cli setup --no-interaction --force --server-type=other \
      --driver=mysqli --host=db --port=3306 --dbname=db --username=db --password=db \
      --admin-username="${account_name}" --admin-user-password="${account_pass}" --admin-email="${account_mail}" \
      --project-name="${doc_name} ${PROJECT_NAME}" \
      || { echo "typo3 setup failed. TYPO3 asks for an administrator password of 8 characters or more, with an upper and a lower case letter, a digit and a sign: see account: pass in core/config/settings.yml." ; exit 1 ; } ;

    if [ "${BARE}" == 'yes' ] ; then
      echo "No Introduction package: the installation has no site and no page yet." ;
    else
      typo3_introduction || exit 1 ;
    fi

    if [ "${ADD_USERS}" == 'yes' ] ; then
      set_typo3_users ;
      add_typo3_users ;
      cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;
    fi

    typo3_cli cache:flush ;

    echo "${doc_name} ${PROJECT_NAME} has been installed: $(typo3_cli --version 2>/dev/null | head -1).";
    echo "Go to ${base_url}/typo3 and log in as ${account_name}";
  else
    [ "${ADD_USERS}" == 'yes' ] && echo "--add-users needs --install: there is no site to add accounts to yet." ;
    echo "${doc_name} ${PROJECT_NAME} is ready to install.";
    echo "Go to ${base_url}/typo3/install.php";
  fi

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The official Introduction package (typo3/cms-introduction, on the Bootstrap Package theme): a
# site with pages, content, a search and the backend groups the editor account joins. It is the
# site the step pack is written for.
function typo3_introduction() {
  echo "Adding the Introduction package." ;
  ddev composer require typo3/cms-introduction --no-interaction \
    || { echo "composer require typo3/cms-introduction failed." ; return 1 ; } ;

  # Activates the package and imports its content and its site configuration.
  typo3_cli extension:setup || return 1 ;

  # The content stores the search as a plugin of the old kind, and the setup marks every upgrade
  # wizard as done before the content is imported: run the one that turns it into a content element.
  typo3_cli upgrade:mark:undone indexedSearchCTypeMigration ;
  typo3_cli upgrade:run indexedSearchCTypeMigration --no-interaction ;

  # The search result templates of the theme call a ViewHelper TYPO3 13.4 no longer ships, which
  # breaks the result list: use the templates of Indexed Search itself.
  ddev mysql -e "UPDATE sys_template SET config = CONCAT(IFNULL(config, ''), '
plugin.tx_indexedsearch.view.templateRootPaths.20 >
plugin.tx_indexedsearch.view.templateRootPaths.21 >
plugin.tx_indexedsearch.view.partialRootPaths.20 >
plugin.tx_indexedsearch.view.partialRootPaths.21 >
plugin.tx_indexedsearch.view.layoutRootPaths.20 >
plugin.tx_indexedsearch.view.layoutRootPaths.21 >
') WHERE root = 1 AND (config IS NULL OR config NOT LIKE '%plugin.tx_indexedsearch.view.templateRootPaths.20 >%')" ;
}

# Create the default accounts with the typo3 console. An account that is already there is left as it is.
# The list is loaded by the caller (set_typo3_users): the core's add_users, the builder, the CLI tool.
function add_typo3_users() {
  typo3_enter_project || return 1 ;
  local user user_name user_mail user_password user_role group ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail";
    user_password="user_${user}_password"; user_role="user_${user}_role";

    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo "      User mail: ${!user_mail}";
    echo "  User password: ${!user_password}";
    echo "      User role: ${!user_role}";
    echo " ================================================================= ";

    if typo3_user_exists "${!user_name}" ; then
      echo "   ${!user_name} is already there." ;
    elif [ "${!user_role}" == 'admin' ] ; then
      typo3_cli backend:user:create --no-interaction --username="${!user_name}" \
        --password="${!user_password}" --email="${!user_mail}" --admin && echo "   ${!user_name} is created." ;
    else
      # A backend group is named by its number: look it up by its title.
      group="$(typo3_query "SELECT uid FROM be_groups WHERE title = '${!user_role}' AND deleted = 0 LIMIT 1")" ;
      if [ -z "${group}" ] ; then
        echo "   The site has no backend group \"${!user_role}\" (the Introduction package brings it): ${!user_name} is created without a group." ;
        typo3_cli backend:user:create --no-interaction --username="${!user_name}" \
          --password="${!user_password}" --email="${!user_mail}" && echo "   ${!user_name} is created." ;
      else
        typo3_cli backend:user:create --no-interaction --username="${!user_name}" \
          --password="${!user_password}" --email="${!user_mail}" --groups="${group}" && echo "   ${!user_name} is created." ;
      fi
    fi
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Delete the default accounts. The console has no command for it, so the records are removed
# from the project's database, in its container.
function cancel_typo3_users() {
  typo3_enter_project || return 1 ;
  local user user_name ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name";
    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo " ================================================================= ";
    if typo3_user_exists "${!user_name}" ; then
      ddev mysql -e "DELETE FROM be_users WHERE username = '${!user_name}'" && echo "   ${!user_name} is deleted." ;
    else
      echo "   ${!user_name} is not there." ;
    fi
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# What cmd-tools-typo3-cli.sh does: the first of --run, --update, --flush, --add-users,
# --cancel-users that was asked for; with none of them, what the site is.
function typo3_cli_tool() {
  trim_project_name ;
  typo3_enter_project || exit 1 ;

  if ! ddev describe -j 2>/dev/null | grep -q '"status":"running"' ; then
    ddev start -y || exit 1 ;
  fi

  if [ ! "${RUN}" == '_none_' ] ; then
    # One string on purpose: --run "extension:list --active" is a command and its arguments.
    ddev exec "vendor/bin/typo3 ${RUN}" ;
    exit $? ;
  fi

  if [ "${UPDATE}" == 'yes' ] ; then
    ddev composer update --with-all-dependencies --no-interaction \
      && typo3_cli extension:setup && typo3_cli cache:flush ;
  elif [ "${FLUSH}" == 'yes' ] ; then
    typo3_cli cache:flush && echo "The caches are flushed." ;
  elif [ "${ADD_USERS}" == 'yes' ] ; then
    set_typo3_users ;
    add_typo3_users ;
  elif [ "${CANCEL_USERS}" == 'yes' ] ; then
    set_typo3_users ;
    cancel_typo3_users ;
  else
    echo "${doc_name}/${PROJECT_NAME}: $(typo3_cli --version 2>/dev/null | head -1) at https://${PROJECT_NAME}.ddev.site" ;
    if typo3_is_installed "$(pwd)" ; then
      echo "" ; echo "Sites:" ; typo3_cli site:list ;
      echo "" ; echo "Backend accounts:" ;
      ddev mysql -t -e "SELECT username, email, IF(admin = 1, 'admin', usergroup) AS role FROM be_users WHERE deleted = 0 AND username <> '_cli_' ORDER BY uid" ;
    else
      echo "The site is not set up yet: open its address at /typo3/install.php, or build it again with --install." ;
    fi
  fi
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The step pack in the testing stack of a TYPO3 project. The core's testing_configure calls
# this in the project folder once webship-js is scaffolded and before the dependencies are
# installed; for a project that is not TYPO3 it changes nothing.
#
# It adds the pack to package.json, lists its step definitions in cucumber.js after webship-js's
# own, gives cucumber.js the users registry of the default accounts (a handle a scenario reads,
# mapped to an account; never the workspace account), and writes a first feature when the project
# has none of its own. Every part is skipped when it is already there, so a second run adds what
# the first missed and never resets a suite.
function testing_configure_typo3() {
  local project_path="$1";
  typo3_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  TYPO3: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  echo "Adding the TYPO3 step pack (${TYPO3_STEPS_PACKAGE} ${TYPO3_STEPS_VERSION}).";
  set_typo3_users ;
  local registry="" user user_name user_password handle ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_password="user_${user}_password";
    # The pack's features call the administrator "admin".
    handle="${user}" ; [ "${user}" == 'administrator' ] && handle="admin" ;
    registry="${registry}${handle}|${!user_name}|${!user_password}"$'\n' ;
  done

  # The pack reads TYPO3_<HANDLE>_USER and TYPO3_<HANDLE>_PASS: the registry keeps its names.
  python3 - "${project_path}" "${TYPO3_STEPS_PACKAGE}" "${TYPO3_STEPS_VERSION}" 'TYPO3' 'PASS' "${registry}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version, prefix, secret, registry = sys.argv[1:7]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=2) + '\n')
    print('  package.json: %s %s' % (pack, version))

# cucumber.js: the pack's step definitions after webship-js's own, and the users registry.
cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/**/*.js'," % pack
    core = re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if core:
        src = src[:core.end()] + '\n' + core.group(1) + line + src[core.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

if not re.search(r"^[ \t]*users:[ \t]*\{", src, re.M):
    world = re.search(r"^([ \t]*)worldParameters:[ \t]*\{[ \t]*$", src, re.M)
    if not world:
        sys.exit("  cucumber.js has no worldParameters block to add the users registry to.")
    pad = world.group(1) + '  '
    rows = [r.split('|') for r in registry.splitlines() if r.strip()]
    block = [
        pad + "// The users registry: a handle a scenario reads, mapped to an account of this site (the default",
        pad + "// accounts: cmd-tools-add-users.sh). Override one with %s_<HANDLE>_USER and %s_<HANDLE>_%s." % (prefix, prefix, secret),
        pad + "users: {",
    ]
    for handle, name, password in rows:
        env = '%s_%s' % (prefix, handle.upper())
        block.append(pad + "  %s: { username: process.env.%s_USER || '%s', password: process.env.%s_%s || '%s' }," % (handle, env, name, env, secret, password))
    block.append(pad + "},")
    src = src[:world.end()] + '\n' + '\n'.join(block) + src[world.end():]
    print('  cucumber.js: the users registry (%s)' % ', '.join(r[0] for r in rows))

if src != before:
    open(cucumber_file, 'w').write(src)
PYEOF

  # A first feature, when the project has none for the site yet: the front page, the login form,
  # each default account in its role.
  local feature="${WORKSPACE_SCRIPTS}/plugins/typo3/site.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/site.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/site.feature" \
      && echo "  tests/features/site.feature: a first feature for the site" ;
  fi

  # The scenarios log in as the default accounts: make sure a site that is set up has them.
  if typo3_is_installed "${project_path}" ; then
    ( add_typo3_users > /dev/null ) && echo "  the default accounts are on the site (${users[*]})" ;
  fi
}
