---
name: OrderMainTriggerTest patterns
description: Key helper methods, data setup patterns, and field flags needed to write tests in OrderMainTriggerTest for Order trigger / OrderInsertHelper coverage
type: project
---

## Key helper methods (all private/public static on OrderMainTriggerTest)

- `createTestorder(type, quoteId, accountId, opportunityId, shipToName, pricebook2Id, orderSplitType, orderSubType, additionalFields)` — creates an Order with standard defaults (Have_Polaris_Products__c=false, Polaris_Fulfillment_Status__c='Completed', Is_RWD_Polaris_Quote__c=true)
- `createTestProduct(name, productCode, family, applianceModel, productLevel, additionalFields)` — creates a Product2
- `createTestOrderItem(orderId, quantity, pricebookEntryId, unitPrice, additionalFields)` — creates an OrderItem

## @TestSetup data available in every test

- One Account (Partner/Distributor record type, BillingCountryCode='US')
- One Opportunity linked to that Account
- One SBQQ__Quote__c linked to that Opportunity
- ShGl_DisableBusinessLogic__c with most triggers disabled except Order

## Have_Polaris_Products__c / hasPolarisProduct evaluation (OrderInsertHelper ~line 1413)

The flag is driven by `hasPolarisProduct` which is set per-OrderItem. Key controlling factors:
1. `newOrd.Type != 'Revenue Internal'` — Revenue Internal always excluded
2. `isRSCPProduct = prod.ProductCode.startsWith('RSCP-')` — RSCP guard (PRDOPS-544); if true the item can never flip hasPolarisProduct
3. `newOrd.Is_RWD_Polaris_Quote__c`:
   - false → qualifies via `prod.Family == 'POLARIS'`, `Bundle_Features__c` containing 'Polaris'/'Cloud Native Protection'/'SAP HANA', or Perpetual RCDM
   - true → qualifies via `Product_Level__c` in ('Hybrid Software', 'SaaS Software Addon', 'Standalone Software Addon', 'LOD Software', 'PAYGO') or Product_Type__c == 'On Prem CDM'
4. Order_Sub_Type__c of 'GC OnDemand' or 'MSP Overage' excludes items from qualifying

## Pattern for testing hasPolarisProduct / Have_Polaris_Products__c

To test via the non-RWD path (strictest for RSCP guard):
```apex
Order ord = createTestorder('Revenue', null, acctId, oppId, acctId, pricebookId,
  'Not needed', 'Renewal',
  new Map<String, Object>{
    'Is_RWD_Polaris_Quote__c'       => false,
    'Have_Polaris_Products__c'      => false,
    'Polaris_Fulfillment_Status__c' => 'Completed'
  }
);
insert ord;
// insert OrderItems
ord.Order_Status__c = 'Pending';
update ord;  // triggers OrderInsertHelper evaluation
Order result = [SELECT Have_Polaris_Products__c FROM Order WHERE Id = :ord.Id];
```

## PricebookEntry setup

Always use `Test.getStandardPricebookId()` as the pricebook. Both `createTestProduct` insertion AND PricebookEntry insertion must happen before inserting the Order and its items.

**Why:** The Order trigger queries OrderItems with their Product2 fields; product must already exist in the standard pricebook for OrderItem insert to succeed.

## File location

`force-app/main/default/classes/OrderMainTriggerTest.cls` — 7984 lines as of PRDOPS-544 additions
