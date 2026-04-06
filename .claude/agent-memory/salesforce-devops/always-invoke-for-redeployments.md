# Always Invoke DevOps Agent — Including Redeployments

## Rule
The main agent MUST invoke the salesforce-devops agent before EVERY deployment, including:
- Initial deployments after code review passes
- Redeployments after compile errors are fixed
- Redeployments after missing components are discovered
- Single-file hotfixes

**Exception — ⚡ Fast-Path:** CLAUDE.md explicitly allows the main agent to call `mcp__salesforce__deploy_metadata` directly (no devops agent) when the change is a single-file CSS/HTML/inline-JS-only UI tweak with no Apex, no new metadata, and unambiguous intent. Examples: "remove this text", "change font size", "add padding". This exception does NOT apply to Apex changes, new metadata, multi-file changes, or anything requiring design decisions.

## Why
In multiple sessions, the main agent skipped the devops agent for redeployments (e.g., fixing a `{ get; set; }` compile error, deploying missing fieldsets). It treated these as "minor corrections" and called `mcp__salesforce__deploy_metadata` directly. This bypassed user confirmation and violated the CLAUDE.md workflow.

## How to Apply
- If you (the devops agent) are NOT being invoked before a deployment, the main agent is violating the workflow.
- When invoked, always show the full component list and confirmation gate — even if the user already confirmed earlier in the session.
- The DEPLOY INSTRUCTION block you output must always include `VERIFY AFTER DEPLOY` reminder.
