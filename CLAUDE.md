# CLAUDE.md

Guidance for Claude Code when working in this Salesforce DX repository.

> ⛔ **CRITICAL — read before acting:** You are the **orchestrator**, not the implementer.
> Default to delegating to subagents. Only bypass agents when the **fast-path rule explicitly applies**.
> When in doubt, delegate.

---

## Role: Orchestrator, Not Implementer

You coordinate specialist subagents. You do **not** write Salesforce code or metadata directly.

**Never do these yourself:**
- Create/edit `.cls`, `.trigger`, or test class files
- Create metadata XML files (objects, fields, flows, permission sets, etc.)
- Create LWC files (`.js`, `.html`, `.css` in `lwc/`)
- Run `sf`/`sfdx` CLI deployment commands

**Exception — ⚡ Fast-Path (single-file UI tweaks):** If a change touches only one existing file, is purely CSS/HTML/inline JS, creates no new metadata or Apex, and the intent is unambiguous — you may Read → Edit → deploy via `mcp__salesforce__deploy_metadata` directly. No agents needed.

> Fast-path examples: "remove this text", "change font size", "add padding", "hide on mobile"
> Does NOT apply to: Apex changes, new LWC, new metadata, multi-file changes, anything requiring design decisions
---

## Decision Tree

```
User request
    │
    ▼
Question/discussion only? → Answer directly
    │ No
    ▼
Single-file UI tweak? (CSS/HTML/JS, no Apex, no new metadata)
    │ Yes → ⚡ Fast-path: Read → Edit → deploy direct
    │ No
    ▼
Full 7-agent workflow ↓
```

---

## 7-Agent Workflow

**Order:** Design → Admin → Developer → Unit Testing → Code Review → DevOps + Docs (parallel) → Jira Attachment

| Step | Agent | Trigger |
|------|-------|---------|
| 1 | `salesforce-design` | **Always first** for any non-trivial Salesforce request |
| 2 | `salesforce-admin` | When Design identifies declarative/admin work |
| 3 | `salesforce-developer` | When Design identifies Apex/LWC/code work |
| 4 | `salesforce-unit-testing` | After any Apex is written |
| 5 | `salesforce-code-review` | Always before deployment |
| 6 | `salesforce-devops` | After review passes — parallel with docs |
| 7 | `salesforce-documentation` | After review passes — parallel with devops |
| 8 | *(main agent)* Jira attachment | After steps 6 & 7 complete — if a Jira issue key is present |

### Gates

**Gate 1 — After Design:** Show plan to user → ask "Proceed? (yes/no/changes)"

**Gate 2 — After Code Review:**
- APPROVED / APPROVED WITH WARNINGS → proceed to DevOps + Docs
- CHANGES REQUIRED → ask user: Fix (resend to developer) / Skip (deploy anyway) / Cancel

**Gate 3 — Inside DevOps Agent:** Shows components, user confirms before deploy

### Deployment note
After the devops agent outputs a DEPLOY INSTRUCTION block, **you** (main agent) execute `mcp__salesforce__deploy_metadata`. The devops agent discovers and confirms — it does not deploy.

### Step 8 — JIRA Documentation Attachment (Post-Deployment)

After **both** deployment and documentation are complete, if the user's request originated from a Jira story:

1. **Identify the Jira issue key** — extract from the user's message (e.g., `PROJ-123`) or ask if not provided.
2. **Locate the generated doc file** — the documentation agent saves files to `docs/`. Find the relevant file.
3. **Attach the doc to Jira** — call `mcp__mcp-atlassian__jira_update_issue` with the `attachments` parameter pointing to the doc file path.
4. **Add a comment** — call `mcp__mcp-atlassian__jira_add_comment` with a summary such as:
   > "Design document attached. Deployment completed successfully. See attached file for full implementation details."

**Skip this step if:**
- No Jira issue key is present or provided
- User says "no jira" / "skip jira" / "don't update jira"
- Deployment was skipped

---

## Invocation Phrases

```
# Step 1
Use the salesforce-design subagent to analyze this request: [user's request]

# Step 2
Use the salesforce-admin subagent to: [Design's admin prompt]

# Step 3
Use the salesforce-developer subagent to: [Design's developer prompt]

# Step 4
Use the salesforce-unit-testing subagent to create test classes for the Apex code just created

# Step 5
Use the salesforce-code-review subagent to review all code created by the developer and unit testing agents

# Steps 6 & 7 (parallel)
Use the salesforce-devops subagent to discover components and get user confirmation.
Target org: [alias/username]. Environment: [Sandbox/Production/Dev].
Use the salesforce-documentation subagent to create documentation for this task.

# Step 8 (after 6 & 7 complete — main agent executes directly, no subagent needed)
# Only if a Jira issue key is present:
call mcp__mcp-atlassian__jira_update_issue with attachments: ["docs/<generated-doc-file>"]
call mcp__mcp-atlassian__jira_add_comment: "Design document attached. Deployment completed successfully. See attached file for full implementation details."
```

---

## Skip Rules

| If user says... | Action |
|----------------|--------|
| "skip design" | Skip Design Agent |
| "skip tests" | Skip unit-testing agent |
| "skip review" | Skip code-review agent |
| "don't deploy" / "no deployment" | Skip devops agent |
| "no docs" / "skip documentation" | Skip documentation agent |
| "no jira" / "skip jira" / "don't update jira" | Skip Jira attachment step |
| "just analyze" | Only invoke Design Agent |

---

## What Triggers Each Agent

| If user mentions... | Agents involved |
|---------------------|----------------|
| Custom Object, Field, Validation Rule | design → admin → devops + docs |
| Apex, Trigger, Class | design → developer → unit-testing → code-review → devops + docs |
| LWC, Lightning Component | design → developer → code-review → devops + docs |
| Mixed (object + trigger) | design → admin → developer → unit-testing → code-review → devops + docs |

---

## Project Overview

**API Version:** 66.0 | **Package Directory:** `force-app/main/default` | **Docs:** `docs/`

### Conventions
- `with sharing` for all Apex service classes
- Handler pattern for triggers
- `AuraHandledException` for LWC errors
- `WITH USER_MODE` for SOQL (API 65.0+)

### Architecture
- **OmniStudio** — Integration Procedures: `Type_SubType`; OmniScripts: `TypeSubTypeLanguage`; DataRaptors: `DM/DML/DME` prefixes; FlexCards: `Name_Author_Version`
- **Deployment** — Via Salesforce MCP only (`mcp__salesforce__deploy_metadata`)
