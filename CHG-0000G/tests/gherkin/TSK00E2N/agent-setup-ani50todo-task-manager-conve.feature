Feature: Agent Setup: Ani50-todo Task Manager Conversational Agent

  Scenario: YAML file exists in CHG-0000G with correct top-level structure
    Given the file CHG-0000G/task_manager_ai_service.yaml exists in the repository root
    When the file is parsed as YAML
    Then all required top-level keys are present: aiService, aiServiceInputs, tasks, agentMappings, taskMappings, tinyChatAgents

  Scenario: Task Manager agent key is registered with correct label and icon
    Given the tinyChatAgents section of task_manager_ai_service.yaml is read
    When the agent with key task_manager is located
    Then its label is Task Manager and its icon is chat

  Scenario: Task prompt references all required runtime input placeholders
    Given the task description field in the YAML tasks section is read
    When the prompt text is scanned for template placeholders
    Then the placeholders conversation contextType and contextId are all present

  Scenario: drakkar content.list references the agent YAML file path
    Given the file drakkar/content.list exists in the repository root
    When its contents are read
    Then it contains the entry CHG-0000G/task_manager_ai_service.yaml
