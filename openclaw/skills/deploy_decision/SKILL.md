---
name: deploy_decision
description: Decide whether a Slack-invoked deployment should proceed now or require confirmation.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: []
      config: ["channels.slack"]
---

# Deploy Decision

## Purpose

Handle the first decision point after a human asks OpenClaw to deploy from Slack.
This skill only starts from Slack conversation context; image publication alone is not a deployment trigger.

## Trigger

- A Slack message handled by the native `channels.slack` integration
- Example intents:
  - `@OpenClaw deploy latest`
  - `@OpenClaw deploy <image-tag>`

## Inputs

- Requested action from Slack
- Target image tag, digest, or alias such as `latest`
- Current deployment state
- Optional approval policy or environment guardrails

## Responsibilities

1. Parse the deploy request and identify the requested target image.
2. Check whether the request can proceed immediately or needs confirmation.
3. Ask for confirmation in Slack when the request is high risk or ambiguous.
4. Produce a clear handoff to `container_control` once deployment is approved.

## Must Not Do

- Must not treat a new registry image as a deploy trigger by itself
- Must not perform container changes directly
- Must not duplicate health check or rollback logic

## Outputs

- `approved_deploy`: continue with target image and deployment context
- `needs_confirmation`: respond in Slack and wait for user confirmation
- `rejected_request`: explain why deployment did not proceed

## Handoff

- On approval: hand off to `container_control`
- On blocked or ambiguous request: stay in Slack conversation until resolved
