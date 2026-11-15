Feature: A visitor finds their way around the site
  As a visitor
  I want the menu, the breadcrumb, the languages and the search to work
  So that a broken template is caught by the suite

  # For a site built with the Introduction package (the builder's default; not with --bare):
  # the pages, the menu and the translations are the package's.

  Scenario: The main menu leads to a page
    Given I am an anonymous user
    And I am on the homepage
    Then the response status code should be 200
    And I should see the "Features" menu item
    And I should not see the breadcrumb
    When I open the "Features" menu item
    Then I should be on "/features"
    And the "Features" menu item should be active

  Scenario: A content page has its subnavigation and its breadcrumb
    Given I am on "/content-examples/form-elements/forms"
    Then I should see the "Search" subnavigation item
    And I should see the breadcrumb
    And the breadcrumb should contain "Content Examples"
    When I open the "Search" subnavigation item
    Then I should be viewing the "Search" page

  Scenario: A translated page offers its translations
    Given I am on "/content-examples/and-more/any-language-any-character"
    Then the "Deutsch" language should be available
    When I switch to the "Deutsch" language
    Then the page language should be "de-DE"

  Scenario: An address nobody made is the 404 page
    Given I am on "/no-such-page-anywhere"
    Then I should be on the 404 page

  Scenario: A search for a word nobody wrote finds nothing
    Given I am on "/content-examples/form-elements/search"
    When I search the site for "zzzqqqxyz"
    Then I should see no search results
