Feature: The TYPO3 plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the TYPO3 builder, the
  AI Agents folder lists the TYPO3 agents, and the Plugins page lists the plugin with its steps.

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
