#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The TYPO3 project in this workspace.')
parser.add_argument('-r', '--run',
                    default="_none_",
                    help='A typo3 console command to run in the project, without the leading typo3. Example: --run "extension:list --active"')
parser.add_argument('-u', '--update',
                    action='store_true',
                    default=False,
                    help='Update the Composer packages of the project (TYPO3 and its extensions) within their constraints, set the extensions up and flush the caches.')
parser.add_argument('-f', '--flush',
                    action='store_true',
                    default=False,
                    help='Flush every cache, and nothing else.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='Add the default accounts, an administrator and an editor. An account that is already there is left as it is.')
parser.add_argument('-c', '--cancel-users',
                    action='store_true',
                    default=False,
                    help='Delete the default accounts.')
ARGEOF
