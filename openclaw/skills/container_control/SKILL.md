---
name: container_control
description: Pull the requested image and execute the blue-green container deployment steps.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["docker"]
      config: []
---

# Container Control

## Purpose

Execute the deployment steps after `deploy_decision` approves a Slack-requested release.
This skill owns image pull, candidate startup, and the final blue-green traffic switch after validation passes.

## Inputs

- Approved target image tag or digest
- Current active environment information
- Blue/green container naming convention
- Deployment context from Slack request

## Responsibilities

1. Pull the requested image from the registry.
2. Start the candidate environment without breaking live traffic.
3. Prepare the blue-green switch context for validation.
4. Promote the healthy candidate to live traffic when validation passes.

## Must Not Do

- Must not decide whether a deploy request is allowed
- Must not declare deployment success before validation
- Must not own rollback analysis or final result reporting

## Outputs

- `candidate_started`: new environment is ready for validation
- `traffic_switched`: healthy candidate has been promoted to live traffic
- `deployment_failed`: startup or image pull failed before health validation

## Handoff

- On candidate start: hand off to `health_checker`
- On healthy result from `health_checker`: switch traffic, then hand off to `log_analyzer`
- On startup failure: hand off to `rollback_handler` with failure context
