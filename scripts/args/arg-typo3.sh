#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The name of the project: its folder, and its name on the container runtime (on DDEV its host name too).')
parser.add_argument('--runtime',
                    dest='RUNTIME',
                    default="_none_",
                    choices=['ddev', 'docker', 'podman', 'kubernetes', 'lando', 'docksal'],
                    help='The container runtime to build on: ddev (the default, or container.runtime of settings.yml), docker (Docker Compose), podman, kubernetes, lando or docksal.')
parser.add_argument('-v', '--version',
                    default="${site_version}",
                    help='The TYPO3 release to create the project from, as a Composer constraint of typo3/cms-base-distribution. Example: --version 13.4.20 [default %(default)s]')
parser.add_argument('-i', '--install',
                    action='store_true',
                    default=False,
                    help='Set TYPO3 up, with the workspace account as the administrator, and add the Introduction package: a site with pages and content.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='With --install, add the default accounts: an administrator and an editor, the ones the test scenarios log in as.')
parser.add_argument('-b', '--bare',
                    action='store_true',
                    default=False,
                    help='With --install, leave the Introduction package out: an installation with a backend, and no site or page yet.')
parser.add_argument('-l', '--launch',
                    action='store_true',
                    default=False,
                    help='Open the site in a browser when it is ready.')
parser.add_argument('--php-version',
                    default="8.3",
                    choices=['8.4', '8.3', '8.2'],
                    help='PHP version for the project container. Example: --php-version 8.4 [default %(default)s]')
ARGEOF
