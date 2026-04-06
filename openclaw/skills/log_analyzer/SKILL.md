---
name: log_analyzer
description: Summarize deployment or rollback results, inspect logs, and prepare the final operator-facing outcome.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["docker"]
      config: []
---

# Log Analyzer

## Purpose

Provide the final diagnosis and result summary after a deployment succeeds or fails.
This skill closes the loop by turning runtime evidence into a concise outcome for Slack and state/history recording.

## Inputs

- Success context from `container_control` after live traffic promotion, or failure context from `rollback_handler`
- Relevant container logs
- Target image information
- Final deployment state

## Responsibilities

1. Gather the log snippets and state needed to explain the outcome.
2. Distinguish between successful deploy, failed deploy, and failed rollback.
3. Distinguish a failed deploy with successful rollback from a failed rollback.
4. Produce a concise operator-facing summary for Slack.
5. Record the final deployment result or rollback result in the state/history layer.

## Must Not Do

- Must not start, stop, or switch containers
- Must not decide whether deployment should proceed
- Must not replace the dedicated rollback or health-check steps

## Outputs

- `deploy_success_summary`
- `deploy_failure_summary`
- `rollback_success_summary`
- `rollback_failure_summary`

## Handoff

- Final step in the skill flow; return the summarized result to OpenClaw for Slack response and state persistence
