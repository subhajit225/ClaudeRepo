---
name: Verify deployment landed in org
description: After deploying metadata, always verify with a Tooling API query — never trust the deploy result summary alone
type: feedback
---

After every metadata deployment, verify that components actually exist in the org using a Tooling API SOQL query before declaring success or moving on.

**Why:** In a prior session, 3 FieldSet components were reported as deployed (deploy result showed success) but a Tooling API query confirmed 0 fieldsets existed in the org. The controller depended on them — without the fieldsets, `getOvfFieldSetMembers()` returned empty and the OVF form rendered with no fields. The gap went unnoticed until the user reported it.

**How to apply:** After deploying any metadata component, immediately run a Tooling API query to confirm the record exists in the org. For example:
- FieldSets: `SELECT DeveloperName, MasterLabel FROM FieldSet WHERE EntityDefinition.QualifiedApiName = 'ObjectName__c'`
- ApexClass: `SELECT Name FROM ApexClass WHERE Name = 'ClassName'`
- ApexPage: `SELECT Name FROM ApexPage WHERE Name = 'PageName'`

Only confirm success to the user after the query returns the expected records. If the query returns 0 records, redeploy immediately and re-verify.
