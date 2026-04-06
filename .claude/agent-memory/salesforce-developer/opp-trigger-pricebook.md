---
name: Opportunity Trigger Pricebook Reassignment
description: OpportunityTrigger changes Pricebook2Id from Standard to CPQ PriceBook (01s1W0000003MzoQAE) on insert; OLI insert scripts must re-query Opportunities after insert to get the actual Pricebook2Id
type: project
---

The `OpportunityTrigger` (via `OpportunityObjectTriggerHandler`) reassigns Opportunity.Pricebook2Id from the Standard Price Book to the "CPQ PriceBook" (Id: 01s1W0000003MzoQAE) during before-insert.

**Why:** CPQ (Salesforce Billing / SBQQ) trigger logic overrides the pricebook to ensure all Opportunities use the CPQ-managed pricebook.

**How to apply:** When inserting OpportunityLineItems via Anonymous Apex or test data scripts:
1. Insert the Opportunity with the Standard Pricebook (required -- Standard PBE must exist first).
2. After insert, re-query the Opportunity to get the actual Pricebook2Id (may differ from what was set).
3. Ensure a PricebookEntry exists in the actual pricebook before inserting OLIs.
4. Use the PricebookEntry matching the Opportunity's actual Pricebook2Id for the OLI.
