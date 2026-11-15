Feature: A page is made in the backend and taken away again
  As an administrator
  I want to create a page, give it content, show it to visitors and delete it
  So that the suite proves the backend works and leaves the site as it found it

  # A page is named by its path in the page tree. A new page is hidden until it is enabled, and a
  # logged in backend user previews hidden pages: the visitor steps drop the session first.

  Scenario: The administrator makes a page with a header, shows it and deletes it
    Given I am a logged in user with the "admin" user
    And I open the "Page" module
    And there is no "Congratulations > 404 > A page written by a scenario" page
    When I choose "New subpage" from the context menu of the "Congratulations > 404" page
    And I fill in the "Page Title" record field with "A page written by a scenario"
    And I save the record
    Then I should see the notification "Record saved"
    When I close the record
    Then the "Congratulations > 404 > A page written by a scenario" page should be hidden in the page tree
    When I choose "Enable" from the context menu of the "Congratulations > 404 > A page written by a scenario" page
    Then the "Congratulations > 404 > A page written by a scenario" page should not be hidden in the page tree
    When I select the "Congratulations > 404 > A page written by a scenario" page in the page tree
    And I add a "Header Only" content element to the "Normal" column
    And I fill in the "Header" record field with "A header written by a scenario"
    And I save the record
    And I close the record
    Then I should see the "A header written by a scenario" content element in the page module
    Given I am not logged in
    And I am on "/404/a-page-written-by-a-scenario"
    Then I should not be on the 404 page
    And I should see "A header written by a scenario"
    Given I am a logged in user with the "admin" user
    And I open the "Page" module
    When I choose "Delete" from the context menu of the "Congratulations > 404 > A page written by a scenario" page
    And I confirm the dialog
    Then I should not see the "Congratulations > 404 > A page written by a scenario" page in the page tree

  Scenario: A page needs a title
    Given I am a logged in user with the "admin" user
    And I open the "Page" module
    When I choose "New subpage" from the context menu of the "Congratulations > 404" page
    Then the module heading should be "Create new Page"
    When I save the record
    Then the "Page Title" record field should be marked as invalid
    And I should not see the notification "Record saved"
