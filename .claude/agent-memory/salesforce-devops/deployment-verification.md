# Deployment Verification

## Rule
After every deployment, the main agent MUST run a Tooling API query to confirm the deployed components actually exist in the org before declaring success to the user.

## Why
In a prior session, 3 FieldSet components showed a successful deploy result but a Tooling API query confirmed 0 fieldsets existed in the org. The controller (`getOvfFieldSetMembers()`) depended on them — with missing fieldsets, the OVF form rendered with no fields. The gap went unnoticed until the user manually reported it.

## How to Apply
After the main agent executes `mcp__salesforce__deploy_metadata`, it must immediately verify with a Tooling API query:

| Component Type | Verification Query |
|----------------|--------------------|
| FieldSet | `SELECT DeveloperName, MasterLabel FROM FieldSet WHERE EntityDefinition.QualifiedApiName = 'Object__c'` |
| ApexClass | `SELECT Name FROM ApexClass WHERE Name = 'ClassName'` |
| ApexPage | `SELECT Name FROM ApexPage WHERE Name = 'PageName'` |
| CustomObject | `SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'ObjectName'` |

If the query returns 0 records, redeploy immediately and re-verify before confirming success to the user.

## Include in DEPLOY INSTRUCTION Block
Always remind the main agent to verify after deploying by appending to the DEPLOY INSTRUCTION block:

```
VERIFY AFTER DEPLOY: Run Tooling API query to confirm all components exist in org before reporting success.
```
