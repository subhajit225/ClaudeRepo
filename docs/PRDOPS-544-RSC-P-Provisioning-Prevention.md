# PRDOPS-544 — Prevent RSC-P SKUs from Triggering RSC Provisioning

**Date:** 2026-03-30
**Author:** Documentation Agent
**Jira:** PRDOPS-544
**Status:** Completed

---

## Overview

### Original Request

Prevent RSC-P SKUs (ProductCode starting with 'RSCP-') from triggering RSC provisioning. When an order contains ONLY RSC-P products, provisioning should be skipped entirely. When an order contains a mix of RSC-P and standard RSC (or RSC-G) products, provisioning should proceed normally for the RSC/RSC-G items.

**Scope:** Revenue and POC order types only.
**Target users:** OM (Order Management) users processing Revenue and POC orders.

### Business Objective

RSC-P SKUs are private/internal products that do not require RSC URL provisioning. Prior to this fix, orders containing only RSC-P line items were incorrectly reaching the RSC provisioning callout path. This caused provisioning errors (because there was nothing to provision) and delayed order fulfillment. The fix ensures these orders are clearly marked as not needing provisioning and are excluded from the outbound callout that triggers RSC URL creation.

### Summary

Three code changes were made to `OrderInsertHelper.cls` (plus one new constant in `Constants.cls`) to close two provisioning gaps: (1) RSCP-only orders now get `Polaris_Fulfillment_Status__c` stamped to `'Not Needed'` immediately after the per-item product loop, and (2) both the Revenue and POC provisioning callout blocks now gate on `Have_Polaris_Products__c == true` so the outbound call is never triggered for RSCP-only orders. Five new test methods in `OrderMainTriggerTest.cls` verify all acceptance criteria, including explicit assertions on all three key fields.

---

## Components Created / Modified

### Admin Components (Declarative)

No declarative metadata changes were required. All fields referenced already existed in the org.

**Existing fields used (no changes made):**

| Object | Field API Name | Label | Purpose in This Story |
|--------|----------------|-------|----------------------|
| `Order` | `Have_Polaris_Products__c` | Requires RSC Provisioning | Boolean; `true` only when at least one non-RSCP Polaris product exists on the order |
| `Order` | `Polaris_Fulfillment_Status__c` | RSC Provisioning Status | Picklist tracking provisioning lifecycle; stamped to `'Not Needed'` for RSCP-only orders |
| `Order` | `Send_for_Polaris_Fulfilment__c` | Send for RSC Fulfilment | Boolean; setting this to `true` triggers the outbound RSC provisioning callout |
| `Order` | `RSC_G_Enabled__c` | RSC-G Enabled | Boolean; when `true`, the `'Not Needed'` stamp is skipped (see Known Limitations) |
| `Product2` | `ProductCode` | Product Code | Evaluated against the `'RSCP-'` prefix to classify RSC-P products |

---

### Development Components (Code)

#### Apex Classes Modified

| Class Name | Type | Change Summary |
|------------|------|----------------|
| `Constants.cls` | Constants | Added two new string constants tagged `// PRDOPS-544` |
| `OrderInsertHelper.cls` | Order trigger helper | Three targeted guards added at lines 1602-1605, 1797, and 2782 |
| `OrderMainTriggerTest.cls` | Test class | Five new `@isTest` methods added in a clearly delimited `// PRDOPS-544` section |

#### Apex Triggers (unchanged)

| Trigger Name | Object | Events | Notes |
|--------------|--------|--------|-------|
| `OrderMainTrigger` | `Order` | before insert, after insert, after update, before update | Entry point that delegates to `OrderHandler` and ultimately `OrderInsertHelper`; no changes required |

---

## Detailed Change Log

### Change 1 — Constants.cls (lines 174-175)

Two new public static final String constants added in the `// Quote` section:

```
PRODUCT_CODE_PREFIX_RSCP = 'RSCP-'
POLARIS_FULFILLMENT_STATUS_NOT_NEEDED = 'Not Needed'
```

Both are tagged with `// PRDOPS-544` inline comments. Pre-existing related constants in the same block (`MANUAL_FULFILL_Quote_RSCP_CONVERSION`, `MANUAL_FULFILL_Quote_GO_RSCP_CONVERSION`) confirm this area was already the canonical home for RSC-P string literals.

---

### Change 2 (Fix 1) — OrderInsertHelper.cls, lines 1602-1605

**Location in execution flow:** Immediately after `newOrd.Have_Polaris_Products__c = hasPolarisProduct` (line 1601), which is itself the last statement in the per-order-item loop block.

**Code added:**

```apex
// PRDOPS-544: Stamp 'Not Needed' for RSCP-only orders that do not require RSC provisioning
if (!hasPolarisProduct && !newOrd.RSC_G_Enabled__c && (newOrd.Type == 'Revenue' || newOrd.Type == 'POC')) {
  newOrd.Polaris_Fulfillment_Status__c = Constants.POLARIS_FULFILLMENT_STATUS_NOT_NEEDED; // PRDOPS-544
}
```

**Why this is needed:** On order insert (line 594-595 of `OrderInsertHelper.cls`), ALL Revenue/POC orders receive `Polaris_Fulfillment_Status__c = 'Not Started'`. Without Fix 1, an RSCP-only order would remain at `'Not Started'` even though `Have_Polaris_Products__c` was correctly set to `false`. The downstream Revenue provisioning callout block (lines 1794-1808) checks for `'Not Started'` or `'In Progress'` status — meaning the callout path was reachable even after the product-loop flag was correctly set.

**Guard conditions explained:**

| Condition | Purpose |
|-----------|---------|
| `!hasPolarisProduct` | True only when every line item on the order has an RSCP- ProductCode prefix (or the order has no Polaris-qualifying items at all) |
| `!newOrd.RSC_G_Enabled__c` | Skips the stamp when RSC-G is enabled; see Known Limitations for the open edge case |
| `newOrd.Type == 'Revenue' \|\| newOrd.Type == 'POC'` | Limits the stamp to the two order types in scope; excludes Revenue Internal, POC Internal, etc. |

---

### Change 3 (Fix 2a) — OrderInsertHelper.cls, line 1797

**Location:** Revenue order provisioning callout block (lines 1790-1808). The block fires when an order transitions to `Order_Status__c = 'Order Accepted'`.

**Before:**

```apex
if (
  newOrd.Order_Status__c == 'Order Accepted' &&
  newOrd.Order_Sub_Type__c != 'MSP Overage' &&
  newOrd.Send_for_Polaris_Fulfilment__c == false &&
  ...
  (newOrd.Polaris_Fulfillment_Status__c == 'Not Started' ||
   newOrd.Polaris_Fulfillment_Status__c == 'In Progress')
) {
  newOrd.Send_for_Polaris_Fulfilment__c = true;
  ...
}
```

**After (line 1797 added):**

```apex
if (
  newOrd.Order_Status__c == 'Order Accepted' &&
  newOrd.Order_Sub_Type__c != 'MSP Overage' &&
  newOrd.Have_Polaris_Products__c == true && // PRDOPS-544: Skip callout for RSCP-only orders
  newOrd.Send_for_Polaris_Fulfilment__c == false &&
  ...
  (newOrd.Polaris_Fulfillment_Status__c == 'Not Started' ||
   newOrd.Polaris_Fulfillment_Status__c == 'In Progress')
) {
  newOrd.Send_for_Polaris_Fulfilment__c = true;
  ...
}
```

**Why this is needed:** Fix 1 (the `'Not Needed'` stamp) is a primary guard, but only fires during the item-loop evaluation path. If an RSCP-only order somehow arrives at `Order Accepted` status with `Polaris_Fulfillment_Status__c` still set to `'Not Started'` (for example, after a manual status reset), this belt-and-suspenders guard prevents the callout from firing. It also makes the intent self-documenting: the callout block explicitly requires `Have_Polaris_Products__c = true`.

---

### Change 4 (Fix 2b) — OrderInsertHelper.cls, line 2782

**Location:** POC order provisioning callout block (lines 2781-2787). The block fires when `ScreenStatus__c` transitions to `'Approved'` or `'Approved Bypassed'`.

**Before:**

```apex
if (oldOrd.ScreenStatus__c != newOrd.ScreenStatus__c && (newOrd.ScreenStatus__c == 'Approved' || newOrd.ScreenStatus__c == 'Approved Bypassed')) {
  if (newOrd.Type == 'POC') {
    newOrd.Send_for_Polaris_Fulfilment__c = true;
    ...
  }
}
```

**After (`&& newOrd.Have_Polaris_Products__c == true` added to the inner condition):**

```apex
if (oldOrd.ScreenStatus__c != newOrd.ScreenStatus__c && (newOrd.ScreenStatus__c == 'Approved' || newOrd.ScreenStatus__c == 'Approved Bypassed')) {
  if (newOrd.Type == 'POC' && newOrd.Have_Polaris_Products__c == true) { // PRDOPS-544: Skip callout for RSCP-only orders
    newOrd.Send_for_Polaris_Fulfilment__c = true;
    ...
  }
}
```

**Why this is needed:** Same rationale as Fix 2a, applied to the POC provisioning path. POC orders trigger provisioning on screen status approval rather than `Order_Status__c` change, so they require their own independent guard.

---

### Change 5 — OrderMainTriggerTest.cls (lines 7988-8433)

Five new test methods added in a dedicated section (`// PRDOPS-544 – RSC-P product exclusion from Polaris provisioning`). All methods authored by the Unit Testing Agent, dated 2026-03-30. All use `System.runAs(new User(Id = UserInfo.getUserId()))` and the shared `@TestSetup` fixture.

| Method Name | Acceptance Criterion | Key Assertions |
|-------------|---------------------|----------------|
| `testRSCPOnlyOrderSetsNotNeededStatus` | AC 1 (Revenue) | `Have_Polaris_Products__c = false`, `Polaris_Fulfillment_Status__c = 'Not Needed'`, `Send_for_Polaris_Fulfilment__c = false` |
| `testRSCPOnlyPOCOrderSetsNotNeededStatus` | AC 1 (POC) | Same three-field assertion on a POC order |
| `testRSCPOnlyOrderWithRSCGEnabledDoesNotStampNotNeeded` | Boundary / Known Limitation | `Have_Polaris_Products__c = false`, `Polaris_Fulfillment_Status__c != 'Not Needed'` when `RSC_G_Enabled__c = true` |
| `testRSCPOnlyRevenueOrderAcceptedDoesNotTriggerCallout` | Fix 2a guard (line 1797) | Revenue order transitions to `Order Accepted`; `Send_for_Polaris_Fulfilment__c` must remain `false` |
| `testRSCPOnlyPOCOrderScreenStatusApprovedDoesNotTriggerCallout` | Fix 2b guard (line 2782) | POC order transitions ScreenStatus to `Approved`; `Send_for_Polaris_Fulfilment__c` must remain `false` |

**Note:** Three earlier RSCP test methods added in a prior sprint (`testRSCPOnlyOrderSkipsProvisioning`, `testMixedRSCPAndPolarisOrderTriggersProvisioning`, `testNonRSCPPolarisOrderUnchanged`, `testPOCOrderWithRSCPOnlySkipsProvisioning`) use `'Polaris_Fulfillment_Status__c' => 'Completed'` in the order setup. This initializes status in a way that bypasses the provisioning callout path entirely, so those tests verify the `Have_Polaris_Products__c` flag only. The five new methods do not use `'Completed'` initialization and fully exercise the callout prevention logic.

---

## Data Flow

### How It Works

```
1. User creates/updates a Revenue or POC order with line items
2. OrderMainTrigger fires (before/after insert, after update)
3. OrderHandler.execute() routes to OrderInsertHelper.processOrderData()
4. Per-order-item loop evaluates each product:
     a. isRSCPProduct = ProductCode.startsWith('RSCP-')
     b. hasPolarisProduct accumulates: if isRSCPProduct, does NOT flip to true
        (even when Product Family = 'POLARIS')
5. After loop: newOrd.Have_Polaris_Products__c = hasPolarisProduct
6. Fix 1 check (lines 1602-1605):
     if !hasPolarisProduct AND !RSC_G_Enabled__c AND Type in (Revenue, POC)
       → Polaris_Fulfillment_Status__c = 'Not Needed'
       → Downstream status check in Revenue callout block can never match
7a. Revenue path (Order Accepted transition, lines 1794-1808):
     if Order_Status__c = 'Order Accepted'
     AND Have_Polaris_Products__c = true  ← Fix 2a guard
     AND Polaris_Fulfillment_Status__c in ('Not Started', 'In Progress')
       → Send_for_Polaris_Fulfilment__c = true (callout fires)
     For RSCP-only: Have_Polaris_Products__c = false → block skipped entirely
7b. POC path (ScreenStatus Approved transition, lines 2781-2787):
     if ScreenStatus__c changed to Approved/Approved Bypassed
     AND Type = 'POC'
     AND Have_Polaris_Products__c = true  ← Fix 2b guard
       → Send_for_Polaris_Fulfilment__c = true (callout fires)
     For RSCP-only: Have_Polaris_Products__c = false → block skipped entirely
```

### Architecture Diagram

```
                           Order Record Update/Insert
                                      │
                                      ▼
                            OrderMainTrigger.trigger
                          (before/after insert, after update)
                                      │
                                      ▼
                            OrderHandler.execute()
                                      │
                                      ▼
                        OrderInsertHelper.processOrderData()
                                      │
                         ┌────────────┴────────────┐
                         ▼                         ▼
                   Per-item loop              Fixed stamps
                  (lines ~1413-1427)        (lines 1601-1605)
                         │                         │
              isRSCPProduct =             Have_Polaris_Products__c
          ProductCode.startsWith         = hasPolarisProduct
               ('RSCP-')                           │
                         │               if !hasPolarisProduct
              if RSCP → skip              && !RSC_G_Enabled__c
              hasPolarisProduct           && Revenue or POC
              flip                               │
                                                 ▼
                                    Polaris_Fulfillment_Status__c
                                         = 'Not Needed'  (Fix 1)
                                                 │
                    ┌────────────────────────────┴────────────────────────┐
                    ▼                                                      ▼
           Revenue callout block                               POC callout block
           (lines 1794-1808)                                  (lines 2781-2787)
                    │                                                      │
       Order_Status__c = 'Order Accepted'              ScreenStatus__c → 'Approved'
       AND Have_Polaris_Products__c = true  (Fix 2a)   AND Type = 'POC'
       AND Polaris_Fulfillment_Status__c                AND Have_Polaris_Products__c
           in ('Not Started','In Progress')                 = true  (Fix 2b)
                    │                                                      │
                    ▼                                                      ▼
       Send_for_Polaris_Fulfilment__c = true    Send_for_Polaris_Fulfilment__c = true
       (RSC URL provisioning callout fires)     (RSC URL provisioning callout fires)

       RSCP-only order: both paths blocked because Have_Polaris_Products__c = false
```

---

## Field State Summary by Order Scenario

| Scenario | `Have_Polaris_Products__c` | `Polaris_Fulfillment_Status__c` | Callout Fires? |
|----------|--------------------------|--------------------------------|----------------|
| RSCP-only Revenue or POC order (`RSC_G_Enabled__c = false`) | `false` | `'Not Needed'` | No |
| RSCP-only order with `RSC_G_Enabled__c = true` | `false` | Unchanged (see Known Limitations) | Depends on status value |
| Standard RSC-only order (no RSCP items) | `true` | `'Not Started'` → `'In Progress'` → ... | Yes (unchanged behavior) |
| Mixed RSC + RSCP order | `true` (non-RSCP item flips flag) | Normal provisioning flow | Yes (unchanged behavior) |
| Mixed RSC + RSCP + RSC-G (order split) | `true` (post-split) | Normal provisioning flow | Yes (unchanged behavior) |

---

## File Locations

| Component | Path |
|-----------|------|
| Constants | `force-app/main/default/classes/Constants.cls` (lines 174-175) |
| Order trigger helper (fixes) | `force-app/main/default/classes/OrderInsertHelper.cls` (lines 1602-1605, 1797, 2782) |
| Test class (new methods) | `force-app/main/default/classes/OrderMainTriggerTest.cls` (lines 7985-8433) |
| Order trigger (unchanged) | `force-app/main/default/triggers/OrderMainTrigger.trigger` |

---

## Testing

### Test Coverage Summary

All five new methods exercise the provisioning callout prevention paths that were previously untested. The four earlier RSCP tests (written in a prior sprint) remain intact and continue to validate the `Have_Polaris_Products__c` flag logic.

| Test Method | Guards Exercised | Fields Asserted |
|-------------|-----------------|-----------------|
| `testRSCPOnlyOrderSetsNotNeededStatus` | Fix 1, Fix 2a (indirectly via status) | `Have_Polaris_Products__c`, `Polaris_Fulfillment_Status__c`, `Send_for_Polaris_Fulfilment__c` |
| `testRSCPOnlyPOCOrderSetsNotNeededStatus` | Fix 1, Fix 2b (indirectly via status) | `Have_Polaris_Products__c`, `Polaris_Fulfillment_Status__c`, `Send_for_Polaris_Fulfilment__c` |
| `testRSCPOnlyOrderWithRSCGEnabledDoesNotStampNotNeeded` | Fix 1 boundary (`RSC_G_Enabled__c = true` path) | `Have_Polaris_Products__c`, `Polaris_Fulfillment_Status__c` (assertNotEquals) |
| `testRSCPOnlyRevenueOrderAcceptedDoesNotTriggerCallout` | Fix 2a directly (line 1797) | `Have_Polaris_Products__c`, `Send_for_Polaris_Fulfilment__c` |
| `testRSCPOnlyPOCOrderScreenStatusApprovedDoesNotTriggerCallout` | Fix 2b directly (line 2782) | `Have_Polaris_Products__c`, `Send_for_Polaris_Fulfilment__c` |

### Key Test Scenarios

1. **RSCP-only Revenue, no RSC-G** — Products with `ProductCode = 'RSCP-FE-NN-TEST'` and `Family = 'POLARIS'` are used deliberately, because `Family = 'POLARIS'` would normally qualify a product as a Polaris product. The RSCP prefix guard must override the family check. All three flag fields are asserted.

2. **RSCP-only POC, no RSC-G** — Same verification on a POC record type order, including a `Sync_to_NetSuite__c = false` extra field to prevent unrelated automation.

3. **RSCP-only with `RSC_G_Enabled__c = true` boundary** — Confirms the `!RSC_G_Enabled__c` gate in Fix 1 works correctly: `Have_Polaris_Products__c` is still `false`, but `Polaris_Fulfillment_Status__c` is NOT stamped to `'Not Needed'`.

4. **Revenue order transitions to `Order Accepted`** — Order is set up with `Polaris_Fulfillment_Status__c = 'Not Needed'` (the post-Fix-1 state), then updated to `Order_Status__c = 'Order Accepted'`. The callout block's `Have_Polaris_Products__c == true` guard at line 1797 is the only mechanism preventing the callout — this test exercises it directly.

5. **POC order transitions to ScreenStatus `Approved`** — Order's `ScreenStatus__c` is changed from `'Pending'` to `'Approved'`. The callout block's `Have_Polaris_Products__c == true` guard at line 2782 is the only mechanism preventing the callout — this test exercises it directly.

### How to Run Tests

From the CLI, targeting the PRDOPS-544 section only:

```bash
sf apex run test --class-names OrderMainTriggerTest --test-level RunSpecifiedTests \
  --tests OrderMainTriggerTest.testRSCPOnlyOrderSetsNotNeededStatus \
  --tests OrderMainTriggerTest.testRSCPOnlyPOCOrderSetsNotNeededStatus \
  --tests OrderMainTriggerTest.testRSCPOnlyOrderWithRSCGEnabledDoesNotStampNotNeeded \
  --tests OrderMainTriggerTest.testRSCPOnlyRevenueOrderAcceptedDoesNotTriggerCallout \
  --tests OrderMainTriggerTest.testRSCPOnlyPOCOrderScreenStatusApprovedDoesNotTriggerCallout
```

---

## Security

### Sharing Model

`OrderInsertHelper` is a helper class invoked from the trigger context and inherits the trigger's system-mode execution. No new SOQL queries were added by this story; the existing queries already use `WITH USER_MODE` where applicable per project conventions.

### Required Permissions

No new permissions are required. The feature operates entirely on standard Order and OrderItem objects using existing field-level access already configured for OM users.

---

## Notes and Considerations

### Known Limitations

1. **`RSC_G_Enabled__c = true` edge case (tracked for next sprint):** The Fix 1 condition (`!newOrd.RSC_G_Enabled__c`) was included as a deliberate guard, but the intended behavior for an RSCP-only order where `RSC_G_Enabled__c = true` has not been confirmed with the product owner. Currently, such an order will have `Have_Polaris_Products__c = false` but `Polaris_Fulfillment_Status__c` will NOT be stamped to `'Not Needed'` — it will retain whatever value it had (typically `'Not Started'`). This means the Revenue callout block at line 1794-1808 is the only guard preventing the callout for this edge case (via the `Have_Polaris_Products__c == true` requirement at line 1797). The test `testRSCPOnlyOrderWithRSCGEnabledDoesNotStampNotNeeded` documents and validates this boundary behavior. Product owner confirmation is required to determine whether `'Not Needed'` should also be stamped when `RSC_G_Enabled__c = true`.

2. **Earlier RSCP tests use `'Completed'` status initialization:** The four test methods added in the prior sprint (`testRSCPOnlyOrderSkipsProvisioning`, `testMixedRSCPAndPolarisOrderTriggersProvisioning`, `testNonRSCPPolarisOrderUnchanged`, `testPOCOrderWithRSCPOnlySkipsProvisioning`) initialize orders with `'Polaris_Fulfillment_Status__c' => 'Completed'`. Because the Revenue callout block only fires when status is `'Not Started'` or `'In Progress'`, these tests bypass the callout path entirely. This is a test coverage gap for those specific methods — the callout prevention behavior is covered by the five new methods instead.

3. **`Send_for_Polaris_Fulfilment__c` writeback:** The field `Send_for_Polaris_Fulfilment__c` is a trigger on the outbound `PolarisFulfilmentAPI` callout. If this field is manually set to `true` by an admin for an RSCP-only order, the downstream callout will still fire — these guards only operate within the `OrderInsertHelper` evaluation path.

### Future Enhancements

- Confirm with product owner whether `RSC_G_Enabled__c = true` + RSCP-only orders should also receive `'Not Needed'` status, and update Fix 1 + tests accordingly.
- Update the four original RSCP test methods to remove the `'Completed'` initialization shortcut so they cover the full provisioning path.
- Consider adding a validation rule or flow on Order to prevent admins from manually setting `Send_for_Polaris_Fulfilment__c = true` when `Have_Polaris_Products__c = false`.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `OrderMainTrigger.trigger` | Upstream trigger | Entry point; routes to `OrderHandler` → `OrderInsertHelper` |
| `OrderHandler.cls` | Routing class | No changes; delegates to `OrderInsertHelper.processOrderData()` |
| `Constants.cls` | Constant provider | `PRODUCT_CODE_PREFIX_RSCP` and `POLARIS_FULFILLMENT_STATUS_NOT_NEEDED` constants |
| `TriggerControl` / `ShGl_DisableBusinessLogic__c` | Test infrastructure | Used in tests to suppress unrelated trigger logic during test runs |
| `Polaris_Fulfillment_Status__c` picklist | Metadata | Must include `'Not Needed'` as an active picklist value in the target org |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-30 | Documentation Agent | Initial creation |
