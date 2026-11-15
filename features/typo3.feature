Feature: The TYPO3 plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the TYPO3 builder, each
  AI folder lists the items of its kind the plugin ships, and the Plugins page lists the plugin
  with its steps.

  Scenario: The plugin is listed on the Plugins page
    Given I am on "/settings/plugins"
     Then I should see "TYPO3"
      And I should see "@webship.co/workspace-typo3"

  Scenario: A sites folder offers the TYPO3 builder
    Given I am on "/dev"
     Then "option[value='cmd-typo3-project.sh']" should be attached

  Scenario: The AI Agents folder lists the agents the plugin ships
    Given I am on "/ai-agents"
     Then I should see "typo3-site-builder"
      And I should see "typo3-tester"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills"
     Then I should see "typo3-scenarios"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands"
     Then I should see "typo3-test"

  Scenario: The AI Prompts folder lists the prompt the plugin ships
    Given I am on "/ai-prompts"
     Then I should see "typo3-build-and-test"
