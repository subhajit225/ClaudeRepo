How We Develop — the AI-Assisted Workflow
Every non-trivial change goes through a 7-agent pipeline. You provide the requirement; Claude Code coordinates the agents.

The only exception is the Fast-Path: if a change touches exactly one existing file, is purely CSS/HTML/JS (no Apex, no new metadata), and the intent is completely unambiguous (e.g., "change this button color"), the main agent may do it directly without invoking agents.

Fast-path examples: "remove this text", "add padding", "hide on mobile" Everything else → full 7-agent workflow.

The Agents and What They Do
Agent	Model	Color	Role	When It Runs
salesforce-design	Opus	Orange	Requirements analyst. Scans the codebase, asks clarifying questions, separates admin vs development work, writes a structured requirements doc. Never adds scope — only clarifies and organizes.	Always first, before any implementation
salesforce-admin	Sonnet	Blue	Declarative config specialist. Creates custom objects, fields, validation rules, page layouts, permission sets, flows, and all metadata XML. Never writes Apex. Never deploys — just creates files.	When Design identifies clicks-not-code work
salesforce-developer	Opus	Green	Code specialist. Writes Apex classes, triggers, LWC components, integrations, batch/queueable jobs, and REST APIs. Follows the project trigger handler pattern strictly. Never does admin config.	When Design identifies programmatic work
salesforce-unit-testing	Sonnet	Yellow	Test coverage specialist. Reads what the Developer wrote, checks if test classes exist, creates or updates them to achieve 90%+ coverage. Uses @TestSetup, Arrange-Act-Assert, and always includes a 200-record bulk scenario.	After any Apex is written
salesforce-code-review	Sonnet	Purple	Quality gate. Reads all code produced by Developer and Unit Testing agents. Checks for SOQL in loops, DML in loops, missing null checks, security violations, missing with sharing, etc. Issues one of three verdicts (see Gates below). Never modifies code — review only.	Before any deployment
salesforce-devops	Opus	Red	Deployment coordinator. Discovers all components to deploy, shows them to you for confirmation, then outputs a structured DEPLOY INSTRUCTION block. The main agent (not this agent) executes the actual deployment via mcp__salesforce__deploy_metadata.	After code review passes — parallel with documentation
salesforce-documentation	Sonnet	Cyan	Technical writer. Creates a complete markdown doc in docs/ explaining the original request, all components built, data flow, file locations, testing summary, and security notes.	After code review passes — parallel with devops
The Gates (Where Human Approval Is Required)
Gate 1 — After Design

The design agent outputs a structured plan showing admin work, development work, and execution order. You review it and respond:

yes → proceed with the plan as-is
no → cancel
changes: [describe what to change] → design agent revises
Gate 2 — After Code Review

The review agent issues one of three verdicts:

APPROVED → proceed to DevOps + Docs (both in parallel)
APPROVED WITH WARNINGS → minor issues found; you choose: deploy now or fix first
CHANGES REQUIRED → critical issues (SOQL in loops, missing security, etc.); you choose: send back to developer, skip deployment, or cancel
At Gate 2, the main agent shows you actual code diffs/snippets before asking for confirmation — not just component names.

Gate 3 — Inside the DevOps Agent

The devops agent shows a numbered table of every component it plans to deploy. You confirm:

A → deploy all
P 1,3,5 → deploy only selected components
C → cancel
For production deployments, an additional CONFIRM PRODUCTION phrase is required.

Full Workflow Sequence
User request
    │
    ├── Question only? → Answer directly
    │
    ├── Single-file CSS/HTML tweak, no Apex, no new metadata?
    │       → Fast-path: Read → Edit → Deploy direct
    │
    └── Everything else → 7-agent workflow:
        1. salesforce-design
              ↓ Gate 1 (user approves plan)
        2. salesforce-admin (if declarative work)
        3. salesforce-developer (if code work)
        4. salesforce-unit-testing (after any Apex)
        5. salesforce-code-review
              ↓ Gate 2 (user approves or requests fixes)
        6. salesforce-devops ──┐  (parallel)
        7. salesforce-documentation ─┘
              ↓ Gate 3 (user confirms component list)
           Main agent executes mcp__salesforce__deploy_metadata
              ↓
           Verify deployment via Tooling API query
              ↓ (if Jira key present)
           Attach doc to Jira + add comment
           


           
