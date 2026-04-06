# OrderInsertHelper Guard Condition Coverage Patterns

## General Rule
Guard conditions inside `OrderInsertHelper` only fire on **update** operations (the helper operates on before/after update context). The standard test sequence must be:
1. `insert Order`
2. `insert OrderItem(s)`
3. `update Order` (this triggers the helper evaluation)

Simply inserting an Order and querying is not sufficient to exercise update-time guards.

## Revenue Callout Guard (line ~1797, PRDOPS-544)

```
if (
  newOrd.Order_Status__c == 'Order Accepted' &&
  newOrd.Order_Sub_Type__c != 'MSP Overage' &&
  newOrd.Have_Polaris_Products__c == true &&   // NEW guard
  newOrd.Send_for_Polaris_Fulfilment__c == false &&
  ...
  (newOrd.Polaris_Fulfillment_Status__c == 'Not Started' || 'In Progress')
)
```

To exercise the **blocking direction** (guard prevents callout):
- Start order at status `'Pending'`, transition update TO `'Order Accepted'`
- Set `Polaris_Fulfillment_Status__c = 'Not Started'` so inner conditions are satisfied
- Set `Have_Polaris_Products__c = false` (RSCP-only)
- Assert `Send_for_Polaris_Fulfilment__c` remains `false` after update

To exercise the **positive direction** (guard allows callout) — already covered by pre-existing tests that set `Have_Polaris_Products__c = true`.

## POC ScreenStatus Approved Guard (line ~2782, PRDOPS-544)

```
if (oldOrd.ScreenStatus__c != newOrd.ScreenStatus__c
    && (newOrd.ScreenStatus__c == 'Approved' || 'Approved Bypassed')) {
  if (newOrd.Type == 'POC' && newOrd.Have_Polaris_Products__c == true) {  // NEW guard
    ...
  }
}
```

To exercise the **blocking direction**:
- Create POC order with `ScreenStatus__c = 'Pending'` (any non-Approved value)
- In test update, set `ord.ScreenStatus__c = 'Approved'`
- The `oldOrd != newOrd` diff check gates entry to the outer block
- Set `Have_Polaris_Products__c = false` (RSCP-only)
- Assert `Send_for_Polaris_Fulfilment__c` remains `false` after update

## Not Needed Stamp Guard (line ~1603, PRDOPS-544)

```
if (!hasPolarisProduct && !newOrd.RSC_G_Enabled__c && (Type == 'Revenue' || 'POC')) {
  newOrd.Polaris_Fulfillment_Status__c = Constants.POLARIS_FULFILLMENT_STATUS_NOT_NEEDED;
}
```

Three sub-conditions, each needs a negative test:
1. `hasPolarisProduct == true` → stamp skipped (covered by mixed-product tests)
2. `RSC_G_Enabled__c == true` → stamp skipped; assert `areNotEqual('Not Needed', result.Polaris_Fulfillment_Status__c)`
3. `Type != 'Revenue' && Type != 'POC'` → stamp skipped (other order types)

The `RSC_G_Enabled__c = true` boundary is the easiest to miss — always add a dedicated test for it.

## Test Method Naming Convention for Guards

- `test{ClassName}{Scenario}DoesNotTriggerCallout` — for blocking direction
- `test{ClassName}{Scenario}SetsNotNeededStatus` — for "Not Needed" stamp
- `test{ClassName}WithRSCGEnabledDoesNotStampNotNeeded` — for RSC_G boundary

## Pre-existing Coverage (do not re-create)

- Revenue `Order Accepted` + `Have_Polaris_Products__c = true` → positive callout path: covered at OrderMainTriggerTest line ~3678
- POC `ScreenStatus Approved Bypassed` transition: covered at OrderMainTriggerTest line ~2917
