#!/usr/bin/env bash
# Static YAML structure validation for task_manager_ai_service.yaml
# Run from /workspace (repo root)

set -uo pipefail

PASS=0
FAIL=0
RESULTS=()

run_scenario() {
  local name="$1"
  local result="$2"
  local message="$3"
  if [ "$result" = "pass" ]; then
    PASS=$((PASS + 1))
    echo "  PASS: $name"
    RESULTS+=("{\"name\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$name"),\"status\":\"passed\",\"duration\":0}")
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $name -- $message"
    RESULTS+=("{\"name\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$name"),\"status\":\"failed\",\"duration\":0}")
  fi
}

echo "Feature: Agent Setup: Ani50-todo Task Manager Conversational Agent"
echo ""

# Scenario 1: YAML structure
echo "Scenario: YAML file exists in CHG-0000G with correct top-level structure"
if python3 - <<'EOF'
import yaml, sys
try:
    with open("CHG-0000G/task_manager_ai_service.yaml") as f:
        doc = yaml.safe_load(f)
    required = ["aiService", "aiServiceInputs", "tasks", "agentMappings", "taskMappings", "tinyChatAgents"]
    missing = [k for k in required if k not in doc]
    if missing:
        print(f"Missing keys: {missing}", file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(str(e), file=sys.stderr)
    sys.exit(1)
EOF
then
  run_scenario "YAML file exists in CHG-0000G with correct top-level structure" "pass" ""
else
  run_scenario "YAML file exists in CHG-0000G with correct top-level structure" "fail" "Missing required top-level keys"
fi

# Scenario 2: tinyChatAgents key, label, icon
echo "Scenario: Task Manager agent key is registered with correct label and icon"
if python3 - <<'EOF'
import yaml, sys
with open("CHG-0000G/task_manager_ai_service.yaml") as f:
    doc = yaml.safe_load(f)
agents = doc.get("tinyChatAgents", [])
match = next((a for a in agents if a.get("key") == "task_manager"), None)
if not match:
    print("No agent with key 'task_manager'", file=sys.stderr); sys.exit(1)
if match.get("label") != "Task Manager":
    print(f"Expected label 'Task Manager', got '{match.get('label')}'", file=sys.stderr); sys.exit(1)
if match.get("icon") != "chat":
    print(f"Expected icon 'chat', got '{match.get('icon')}'", file=sys.stderr); sys.exit(1)
EOF
then
  run_scenario "Task Manager agent key is registered with correct label and icon" "pass" ""
else
  run_scenario "Task Manager agent key is registered with correct label and icon" "fail" "Agent key/label/icon mismatch"
fi

# Scenario 3: required placeholders in task prompt
echo "Scenario: Task prompt references all required runtime input placeholders"
if python3 - <<'EOF'
import yaml, sys
with open("CHG-0000G/task_manager_ai_service.yaml") as f:
    doc = yaml.safe_load(f)
tasks = doc.get("tasks", [])
if not tasks:
    print("No tasks defined", file=sys.stderr); sys.exit(1)
desc = tasks[0].get("task", {}).get("description", "")
missing = [p for p in ["{conversation}", "{contextType}", "{contextId}"] if p not in desc]
if missing:
    print(f"Missing placeholders: {missing}", file=sys.stderr); sys.exit(1)
EOF
then
  run_scenario "Task prompt references all required runtime input placeholders" "pass" ""
else
  run_scenario "Task prompt references all required runtime input placeholders" "fail" "Missing prompt placeholders"
fi

# Scenario 4: drakkar/content.list entry
echo "Scenario: drakkar content.list references the agent YAML file path"
if grep -qF "CHG-0000G/task_manager_ai_service.yaml" "drakkar/content.list" 2>/dev/null; then
  run_scenario "drakkar content.list references the agent YAML file path" "pass" ""
else
  run_scenario "drakkar content.list references the agent YAML file path" "fail" "Path not found in drakkar/content.list"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

TOTAL=$((PASS + FAIL))
RESULTS_JSON=$(IFS=,; echo "${RESULTS[*]}")

mkdir -p ".gherkin-results/CHG-0000G"

cat > ".gherkin-results/CHG-0000G/TSK00E2N.summary.json" <<SUMMARY
{"total": $TOTAL, "passed": $PASS, "failed": $FAIL}
SUMMARY

cat > ".gherkin-results/CHG-0000G/TSK00E2N.ctrf.json" <<CTRF
[$RESULTS_JSON]
CTRF

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
