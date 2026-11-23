Feature: A site on Docker Compose and on Kubernetes
  The builder builds on DDEV by default, and with --runtime on Docker Compose, Podman, Kubernetes, Lando or
  Docksal. A site built on Docker Compose or Kubernetes has the row a DDEV site has: its state, its own
  address, the runtime's menu, and the test users of the plugin in its Tests menu.

  # Each scenario drives a real site of that runtime, built with cmd-typo3-project.sh --runtime: the first running
  # one the workspace holds of this platform. Without one it is skipped, with the reason. In the plugin's CI the
  # Docker Compose site is the one the manifest's featuresSite builds.

  @needs-runtime-docker @needs-platform-typo3
  Scenario: A site built on Docker Compose runs at its own address, with the DOCKER menu
    Given I am on the folder of the "docker" site
     Then the row of the "docker" site should show "Running"
      And the row of the "docker" site should link to the address of its runtime
      And the address of the "docker" site should answer
      And the row of the "docker" site should carry the "DOCKER" menu and no DDEV menu

  @needs-runtime-docker @needs-platform-typo3
  Scenario: The Tests menu of a site on Docker Compose offers the test users
    Given I am on the folder of the "docker" site
     When I open the "tests" menu of the "docker" site
     Then the open menu should offer "Add the test users"
      And the open menu should offer "Cancel the test users"

  @needs-runtime-docker @needs-platform-typo3
  Scenario: The site on Docker Compose is installed: its front page and a page of its content
    Given I am on the folder of the "docker" site
     When I open "/" on the "docker" site
     Then I should see "Possibilities"
     When I open "/content-examples" on the "docker" site
     Then I should see "Content Management Made Easy"

  @needs-runtime-kubernetes @needs-platform-typo3
  Scenario: A site built on Kubernetes runs at the address of its node, with the K8S menu
    Given I am on the folder of the "kubernetes" site
     Then the row of the "kubernetes" site should show "Running"
      And the row of the "kubernetes" site should link to the address of its runtime
      And the address of the "kubernetes" site should answer
      And the row of the "kubernetes" site should carry the "K8S" menu and no DDEV menu

  @needs-runtime-kubernetes @needs-platform-typo3
  Scenario: The Tests menu of a site on Kubernetes offers the test users
    Given I am on the folder of the "kubernetes" site
     When I open the "tests" menu of the "kubernetes" site
     Then the open menu should offer "Add the test users"
      And the open menu should offer "Cancel the test users"

  @needs-runtime-kubernetes @needs-platform-typo3
  Scenario: The site on Kubernetes is installed: its front page and a page of its content
    Given I am on the folder of the "kubernetes" site
     When I open "/" on the "kubernetes" site
     Then I should see "Possibilities"
     When I open "/content-examples" on the "kubernetes" site
     Then I should see "Content Management Made Easy"
