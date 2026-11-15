Feature: Each account gets the backend modules of its role
  As the owner of the site
  I want the administrator and the editor to log in and to see their own modules
  So that a change of backend groups is caught by the suite

  # The accounts are the default ones; a scenario logs in by a handle of the users registry.

  Scenario: The editor works in the Page module and has no administration module
    Given I am a logged in user with the "editor" user
    Then I should be logged in as "editor"
    When I open the "Page" module
    Then the "Page" module should be active
    And I should see the "Congratulations" page in the page tree
    And I should see the "List" module
    And I should not see the "Backend Users" module
    And I should not see the "Log" module

  Scenario: The administrator has the administration modules
    Given I am a logged in user with the "admin" user
    Then I should see the "Backend Users" module
    And I should see the "Log" module
    When I open the "List" module
    Then the "List" module should be active

  Scenario: The page tree finds a page by its title
    Given I am a logged in user with the "editor" user
    When I open the "Page" module
    And I search the page tree for "Rich Text"
    Then I should see the "Rich Text" page in the page tree

  Scenario: Logging out ends the session
    Given I am a logged in user with the "editor" user
    When I log out
    Then I should not be logged in
    And I should not see a login error
