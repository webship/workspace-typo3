Feature: The site answers and its accounts work
  As the owner of the site
  I want the front page, the login form and each default account to work
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.
  # The accounts are the default ones (cmd-tools-add-users.sh); a scenario logs in by a handle of
  # the users registry in cucumber.js, so no password is written here. The module names are those
  # of a backend in English.

  @critical
  Scenario: The front page is served
    Given I am an anonymous user
    And I am on the homepage
    Then the response status code should be 200
    And the page should have a title

  @critical
  Scenario: The login form is served to a visitor
    Given I am not logged in
    Then I should not be logged in
    And I should see "Username"
    And I should see "Password"

  Scenario Outline: Each default account logs in
    Given I am a logged in user with the "<handle>" user
    Then I should be logged in as "<handle>"

    Examples:
      | handle |
      | admin  |
      | editor |

  # The administrator account is an administrator, not a system maintainer: the modules of a
  # system maintainer (Extensions, the Admin Tools) stay with the account that set the site up.
  Scenario: The administrator has the administration modules
    Given I am a logged in user with the "admin" user
    Then I should see the "Page" module
    And I should see the "Backend Users" module
    And I should see the "Log" module

  Scenario: The editor has the content modules, and no administration module
    Given I am a logged in user with the "editor" user
    Then I should see the "Page" module
    And I should see the "List" module
    And I should not see the "Backend Users" module
    And I should not see the "Log" module

  Scenario: Logging out ends the session
    Given I am a logged in user with the "editor" user
    When I log out
    Then I should not be logged in
    And I should not see a login error
