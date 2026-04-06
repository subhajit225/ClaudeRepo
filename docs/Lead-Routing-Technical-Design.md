# Lead Routing Revamp - Technical Design Document

| Field | Value |
|-------|-------|
| **Project** | Lead Routing: Phase 1 |
| **Source BRD** | Lead Routing Revamp Project - Approved.md (v1.1, Dec 15 2025, Rashmi Aurora) |
| **TDD Author** | Marketing IT |
| **Date** | March 27, 2026 |
| **Status** | Draft |
| **API Version** | 66.0 |

---

## 1. Executive Summary

This document translates the approved Lead Routing Phase 1 BRD into a Salesforce-native technical design. The system replaces a rigid, code-dependent lead routing engine with a metadata-driven, configurable routing framework. Business users (MOPs/ISOPs) will be able to create, prioritize, and manage routing rules through a self-service UI without IT intervention.

**Key technical pillars:**
- Custom metadata / custom objects for rule storage
- **Platform Event-driven Apex engine** — trigger publishes a `Lead_Routing_Event__e` platform event; a dedicated platform event trigger subscriber performs the heavy rule evaluation, target resolution, and assignment in a completely separate transaction with its own governor limits
- LWC-based rule builder UI
- Routing history and fallback audit trail
- Approval process for rule governance

**Execution strategy:** The routing engine uses a **Platform Event pattern** to decouple the heavy rule evaluation from the trigger transaction. Platform Events are the preferred long-term approach because they provide: built-in retry via `EventBus.RetryableException`, automatic batching by the platform, independent transaction boundaries, high-volume event delivery, and no chaining or chunking logic needed — the platform handles it natively.

---

## 2. Architecture Overview

### 2.1 High-Level Component Diagram

```
+-------------------------------+
|     LWC Rule Builder UI       |  <-- MOPs/ISOPs Users
|  (Create / Edit / Deactivate) |
+-------------------------------+
              |
              v
+-------------------------------+
|   Routing Rule Object Model   |  <-- Custom Objects storing rules
|  (Rules, Conditions, Targets) |
+-------------------------------+
              |
              v
+-------------------------------+
|  Lead/Contact Trigger         |  <-- After Insert / After Update
|  (Lightweight - Publisher)    |
|  - Stamp Routing_Status__c    |
|    = 'Pending'                |
|  - Publish                    |
|    Lead_Routing_Event__e      |
+-------------------------------+
              |
              v  (Platform Event Bus — async boundary)
+-------------------------------+
|  LeadRoutingEventTrigger      |  <-- Platform Event Trigger (Subscriber)
|  (on Lead_Routing_Event__e)   |
|  Runs in separate transaction |
|  with own governor limits     |
|  - Load Active Rules          |
|  - Evaluate Conditions        |
|  - Resolve Targets            |
|  - Fallback Cascade           |
|  - Round Robin Assignment     |
|  - Assign OwnerId             |
|  - Built-in retry via         |
|    EventBus.RetryableException|
+-------------------------------+
              |
              v
+-------------------------------+
|  Routing History & Audit      |  <-- Custom Object for audit trail
|  (Decision log, Fallback log) |
+-------------------------------+
```

> **Why Platform Events over Queueable?** The routing engine performs multiple SOQL-heavy operations per record (ETM lookups, queue membership checks, user active-status validation, fallback cascades). Both patterns decouple from the trigger transaction, but Platform Events are the superior long-term choice:
>
> | Capability | Queueable | Platform Event |
> |------------|-----------|----------------|
> | Transaction isolation | Yes | Yes |
> | Built-in retry on failure | No (manual retry handler needed) | Yes (`EventBus.RetryableException` — up to 9 retries with backoff) |
> | Batching | Manual chunking + chaining | Automatic — platform batches up to 2,000 events per trigger invocation |
> | Chaining complexity | Must manage chain depth, test limits | None — platform handles delivery |
> | High-volume support | Limited by async queue depth | Native high-volume event delivery |
> | Monitoring | Query `AsyncApexJob` | EventBus metrics, `EventBusSubscriber` entity, Setup UI |
> | Replay / recovery | Not possible | `ReplayId` allows event replay from retained events |
> | Test pattern | `Test.startTest()`/`stopTest()` forces sync | `Test.startTest()` + `EventBus.deliver()` for controlled delivery |

### 2.2 Execution Flow

```
Lead/Contact Insert or Update (Trigger fires)
        |
        v
  ┌─────────────────────────────────────────────────────┐
  │  TRIGGER CONTEXT (Lightweight Publisher)             │
  │                                                     │
  │  1. Stamp Routing_Status__c = 'Pending'             │
  │  2. Build Lead_Routing_Event__e for each record:    │
  │       - Record_Id__c = record.Id                    │
  │       - Object_Type__c = 'Lead' or 'Contact'       │
  │  3. EventBus.publish(events)                        │
  │                                                     │
  │  NOTE: publish() is fire-and-forget. Events are     │
  │  committed even if the outer transaction rolls back │
  │  (unless publish is called after a savepoint).      │
  └─────────────────────────────────────────────────────┘
        |
        v  ~~~ Platform Event Bus (Async Boundary) ~~~
        |
        |  Salesforce batches events automatically
        |  (up to 2,000 per trigger invocation)
        |
  ┌─────────────────────────────────────────────────────┐
  │  PLATFORM EVENT TRIGGER (Subscriber)                │
  │  trigger LeadRoutingEventTrigger                    │
  │      on Lead_Routing_Event__e (after insert)        │
  │                                                     │
  │  Runs in its OWN transaction with fresh limits:     │
  │  - 60s CPU, 100 SOQL, 150 DML                      │
  │                                                     │
  │  1. Extract record IDs + object types from events   │
  │  2. Re-query records (fresh data)                   │
  │  3. Load Active Rules (ORDER BY Sequence__c ASC)    │
  │  4. Pre-cache resolution data (ETM, Users, Queues)  │
  │  5. FOR each record:                                │
  │       FOR each rule in priority order:              │
  │         +-> Evaluate Conditions                     │
  │         |     +-- Match? YES --> Resolve Target     │
  │         |     |    +-- Available? --> Assign & STOP  │
  │         |     |    +-- Unavailable --> Fallback      │
  │         |     +-- Match? NO --> NEXT RULE           │
  │       END FOR                                       │
  │  6. Stamp Routing_Status__c = Routed/Fallback       │
  │  7. Update records (OwnerId + status fields)        │
  │  8. Insert Lead_Routing_History__c records           │
  │                                                     │
  │  ON FAILURE:                                        │
  │    throw EventBus.RetryableException(msg)           │
  │    → Platform retries automatically (up to 9x)      │
  │    → setResumeCheckpoint() for partial progress     │
  └─────────────────────────────────────────────────────┘
```

### 2.3 Async Lifecycle & Status Transitions

```
Routing_Status__c state machine:

  [null / blank]
       |
       |  Lead/Contact trigger fires (insert/update)
       |  → publishes Lead_Routing_Event__e
       v
   [Pending]  ──── Event published to EventBus
       |
       |  Platform Event trigger picks it up
       v
   ┌───────┐
   │Routed │  ──── Primary target resolved and assigned
   └───────┘
       OR
   ┌──────────┐
   │ Fallback │  ──── Primary unavailable; fallback target assigned
   └──────────┘
       OR
   ┌────────────┐
   │ Unroutable │  ──── No rule matched or all targets exhausted
   └────────────┘

  On EventBus.RetryableException:
   [Pending] ──── Platform auto-retries (up to 9 attempts with backoff)
       |
       |  Retries exhausted
       v
   ┌────────────┐
   │ Unroutable │  ──── Caught by LeadRoutingRetryHandler safety net
   └────────────┘
```

**User experience:** Records briefly show `Routing_Status__c = 'Pending'` (typically < 2 seconds under normal load). The LWC history component reflects the final assignment once the platform event subscriber completes.

### 2.4 Platform Event Delivery Guarantees

| Behavior | Detail |
|----------|--------|
| **Delivery** | At-least-once (events may be delivered more than once in rare cases) |
| **Ordering** | Events are delivered in publish order within a single publish call |
| **Retry** | `EventBus.RetryableException` triggers up to 9 automatic retries with exponential backoff |
| **Resume checkpoint** | `setResumeCheckpoint()` marks the last successfully processed event so retries skip already-processed events |
| **Idempotency** | Engine must be idempotent — re-processing a record that is already `Routed` is a no-op (checked via `Routing_Status__c`) |
| **Retention** | Platform events are retained for 72 hours (configurable up to 72h) enabling replay |
| **Monitoring** | `EventBusSubscriber` entity tracks subscriber position, retries, and failures in Setup |

---

## 3. Data Model

### 3.1 Lead_Routing_Rule__c (Primary Rule Object)

Stores each routing rule configured by business users.

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Name` | Auto Number | Rule identifier (e.g., LRR-0001) |
| `Rule_Name__c` | Text(255) | User-friendly rule name |
| `Status__c` | Picklist | `Draft`, `Pending Approval`, `Active`, `Inactive`, `Rejected` |
| `Sequence__c` | Number(5,0) | Priority / evaluation order (lower = higher priority) |
| `Object_Type__c` | Picklist | `Lead`, `Contact`, `Both` |
| `Description__c` | Long Text Area | Rule description / notes |
| `Is_Round_Robin__c` | Checkbox | Whether assignment uses Round Robin |
| `Round_Robin_Queue_Id__c` | Text(18) | Queue ID for Round Robin assignment |
| `Created_By_User__c` | Lookup(User) | Submitter for approval tracking |
| `Approved_By__c` | Lookup(User) | Approver reference |
| `Approved_Date__c` | DateTime | Timestamp of approval |
| `Last_Evaluated__c` | DateTime | Last time the rule was evaluated by the engine |

**Record Types:** None required (Status__c picklist governs lifecycle).

### 3.2 Lead_Routing_Condition__c (Rule Conditions - Child)

Each rule can have one or more conditions. All conditions within a rule are evaluated with AND logic (Phase 1). Conditions reference fields on Lead, Contact, or related objects (Account, Campaign).

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Name` | Auto Number | Condition ID |
| `Routing_Rule__c` | Master-Detail(Lead_Routing_Rule__c) | Parent rule |
| `Source_Object__c` | Picklist | `Lead`, `Contact`, `Account`, `Campaign` |
| `Field_API_Name__c` | Text(255) | API name of the field to evaluate |
| `Operator__c` | Picklist | `Equals`, `Not Equals`, `Contains`, `In`, `Not In`, `Is Null`, `Is Not Null`, `Greater Than`, `Less Than` |
| `Value__c` | Long Text Area | Comparison value (supports comma-separated for `In` operator) |
| `Sequence__c` | Number(3,0) | Evaluation order within the rule |

### 3.3 Lead_Routing_Target__c (Assignment Targets - Child)

Defines the primary and fallback targets for a rule. Ordered by `Priority__c` to form the fallback cascade.

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Name` | Auto Number | Target ID |
| `Routing_Rule__c` | Master-Detail(Lead_Routing_Rule__c) | Parent rule |
| `Priority__c` | Number(3,0) | 1 = Primary, 2 = First Fallback, etc. |
| `Target_Type__c` | Picklist | `Account Owner`, `SDR (ETM)`, `SDR Manager (ETM)`, `Account Executive (ETM)`, `Regional Director (ETM)`, `CDM (ETM)`, `Rubrik X SDR (ETM)`, `Queue`, `Direct User`, `Field Reference`, `Round Robin Pool` |
| `Target_Field__c` | Text(255) | Field API name for `Field Reference` type (e.g., `Direct_Routing_AE__c`) |
| `Target_Queue_Id__c` | Text(18) | Queue ID for `Queue` type |
| `Target_User_Id__c` | Lookup(User) | Specific user for `Direct User` type |
| `Fallback_Reason__c` | Picklist | Pre-defined fallback reasons (see Section 3.7) |

### 3.4 Lead_Routing_History__c (Audit Trail)

Captures every routing decision for reporting and troubleshooting. Retention: rolling 6 months.

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Name` | Auto Number | History ID |
| `Record_Id__c` | Text(18) | Lead or Contact ID that was routed |
| `Record_Type__c` | Picklist | `Lead`, `Contact` |
| `Rule_Applied__c` | Lookup(Lead_Routing_Rule__c) | The rule that matched |
| `Rule_Name__c` | Text(255) | Denormalized rule name for reporting |
| `Rule_Sequence__c` | Number(5,0) | Denormalized sequence for reporting |
| `Assigned_To__c` | Text(255) | User or Queue the record was assigned to |
| `Target_Type_Used__c` | Text(100) | Which target type was used (primary or fallback) |
| `Is_Fallback__c` | Checkbox | Whether fallback was invoked |
| `Fallback_Reason__c` | Text(255) | Reason the primary target was skipped |
| `Routing_Timestamp__c` | DateTime | When routing occurred |
| `Previous_Owner__c` | Text(255) | Owner before rerouting |

### 3.5 Fields on Lead Object

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Routing_Status__c` | Picklist | `Pending`, `Routed`, `Fallback`, `Unroutable` |
| `Routing_Fallback__c` | Checkbox | Whether a fallback was used |
| `Routing_Fallback_Reason__c` | Picklist | See Section 3.7 |
| `Last_Routed_Date__c` | DateTime | Timestamp of last routing |
| `Last_Routing_Rule__c` | Text(255) | Name of the last rule that routed this record |
| `Routing_Retry_Count__c` | Number(2,0) | Tracks retry attempts by `LeadRoutingRetryHandler`. Reset to 0 on successful routing. Max 3 before `Unroutable`. |

### 3.6 Fields on Contact Object

Mirror the same fields as Lead (Section 3.5) on Contact.

### 3.7 Fallback Reason Values

Per BRD, the following picklist values for `Routing_Fallback_Reason__c` and `Lead_Routing_Target__c.Fallback_Reason__c`:

| Value | Description |
|-------|-------------|
| `No SDR on ETM` | No SDR found on the Enterprise Territory record |
| `No SDR Manager on ETM` | No SDR Manager on ETM |
| `No RD on ETM` | No Regional Director on ETM |
| `No AE on ETM` | No Account Executive on ETM |
| `No user in the Queue` | Target queue has no active members |
| `No ETM on Account` | Account has no territory assignment |
| `Placeholder TBH Account` | Account is a TBH placeholder |
| `Whitespace Account` | Account is a whitespace account |
| `No CDM on ETM` | No CDM found on ETM |
| `No Rubrik X on ETM` | No Rubrik X SDR on ETM |
| `Direct Route to user - Inactive` | Target user is inactive in Salesforce |

---

## 4. Apex Architecture (Platform Event Pattern)

### 4.1 Design Rationale

The routing engine is **decoupled from the trigger transaction** using Platform Events (`Lead_Routing_Event__e`). This is the core architectural decision for Phase 1.

| Concern | Synchronous (rejected) | Queueable (rejected) | Platform Event (chosen) |
|---------|----------------------|---------------------|------------------------|
| Governor limits | Shared with trigger | Fresh per Queueable | Fresh per event trigger invocation |
| CPU time | 10s shared | 60s dedicated | 60s dedicated |
| SOQL queries | 100 shared | 100 dedicated | 100 dedicated |
| Retry on failure | N/A | Manual (scheduled job) | **Built-in** — `EventBus.RetryableException` (up to 9 retries with backoff) |
| Batching / chunking | N/A | Manual chaining logic | **Automatic** — platform batches up to 2,000 events per invocation |
| High-volume scalability | Poor | Async queue can back up | Native high-volume event delivery |
| Replay / recovery | N/A | Not possible | 72-hour event retention + `ReplayId` |
| Monitoring | N/A | Query `AsyncApexJob` | `EventBusSubscriber` entity + Setup UI |
| Patch Manager impact | Same transaction | Isolated | Isolated |
| User experience | Instant | ~1-3s delay | ~1-3s delay |
| Testability | Simple | `Test.startTest()`/`stopTest()` | `Test.startTest()` + `EventBus.deliver()` |
| Long-term maintainability | Poor | Chaining/retry code adds complexity | Platform handles orchestration — less custom code |

### 4.2 Platform Event Definition: Lead_Routing_Event__e

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Record_Id__c` | Text(18) | The Lead or Contact ID to be routed |
| `Object_Type__c` | Text(20) | `Lead` or `Contact` |
| `Publish Behavior` | `Publish After Commit` | Events publish only after the originating transaction commits successfully |

**Publish Behavior = Publish After Commit** ensures that if the Lead/Contact insert rolls back (e.g., validation rule failure), no orphan routing event is published.

### 4.3 Class Overview

| Class | Type | Description |
|-------|------|-------------|
| `LeadRoutingTriggerHandler` | Trigger Handler | **Lightweight publisher.** Stamps `Routing_Status__c = 'Pending'`, builds and publishes `Lead_Routing_Event__e` events. Zero SOQL. |
| `LeadRoutingEventHandler` | Event Trigger Handler | **Core async orchestrator.** Called by `LeadRoutingEventTrigger`. Re-queries records, invokes engine, persists results. Handles `EventBus.RetryableException` and `setResumeCheckpoint()`. |
| `LeadRoutingEngine` | Service Class | Pure rule evaluation logic. Stateless, `with sharing`. Accepts records + rules, returns assignment results. No DML — caller handles persistence. |
| `LeadRoutingConditionEvaluator` | Utility | Evaluates individual conditions against record field values. |
| `LeadRoutingTargetResolver` | Utility | Resolves target user/queue from `Lead_Routing_Target__c` records. Handles ETM lookups, queue membership checks, user active status. Pre-caches all lookups in maps before iteration. |
| `LeadRoutingRoundRobin` | Utility | Round Robin assignment logic using `Group`/`GroupMember` queries. |
| `LeadRoutingHistoryService` | Service Class | Creates `Lead_Routing_History__c` records. Bulkified — single DML per batch. |
| `LeadRoutingFallbackTracker` | Utility | Stamps fallback fields on Lead/Contact. |
| `LeadRoutingBulkReroute` | Invocable / Batchable | Supports bulk rerouting from UI or Flow. Publishes `Lead_Routing_Event__e` events internally. |
| `LeadRoutingHistoryCleanup` | Schedulable + Batchable | Purges history records older than 6 months. Runs nightly. |
| `LeadRoutingRetryHandler` | Schedulable | **Safety net only.** Catches records stuck in `Pending` after EventBus retries are exhausted (edge case). Runs every 30 minutes. |

### 4.4 Trigger Design (Lightweight Publisher)

```apex
// LeadRoutingTrigger.trigger
trigger LeadRoutingTrigger on Lead (after insert, after update) {
    LeadRoutingTriggerHandler handler = new LeadRoutingTriggerHandler();
    handler.run();
}

// ContactRoutingTrigger.trigger
trigger ContactRoutingTrigger on Contact (after insert, after update) {
    LeadRoutingTriggerHandler handler = new LeadRoutingTriggerHandler();
    handler.run();
}
```

**What the handler does (and does NOT do):**

```apex
public class LeadRoutingTriggerHandler {

    public void run() {
        // Guard: skip if this update was caused by the routing engine itself
        if (LeadRoutingContext.isRoutingInProgress) {
            return;
        }

        List<Lead_Routing_Event__e> events = new List<Lead_Routing_Event__e>();
        String objectType = Trigger.new[0].getSObjectType().getDescribe().getName();

        for (SObject record : Trigger.new) {
            if (shouldRoute(record, Trigger.oldMap)) {
                events.add(new Lead_Routing_Event__e(
                    Record_Id__c = record.Id,
                    Object_Type__c = objectType
                ));
            }
        }

        if (!events.isEmpty()) {
            // Stamp Pending status
            stampPendingStatus(events);

            // Publish events — fire-and-forget
            List<Database.SaveResult> results = EventBus.publish(events);
            handlePublishErrors(results);
        }
    }

    private Boolean shouldRoute(SObject record, Map<Id, SObject> oldMap) {
        // Skip records already pending routing
        if ((String) record.get('Routing_Status__c') == 'Pending') {
            return false;
        }
        // Add other entry criteria checks here
        return true;
    }
}
```

**Key points:**
- Zero SOQL in the trigger handler (only field checks on `Trigger.new`)
- Uses `EventBus.publish()` instead of `System.enqueueJob()` — no async queue depth concerns
- `shouldRoute()` prevents duplicate events for records already in `Pending` status
- `LeadRoutingContext.isRoutingInProgress` static flag prevents re-publishing when the event subscriber updates `OwnerId`

### 4.5 Platform Event Trigger (Subscriber — Heavy Lifting)

```apex
// LeadRoutingEventTrigger.trigger
trigger LeadRoutingEventTrigger on Lead_Routing_Event__e (after insert) {
    LeadRoutingEventHandler handler = new LeadRoutingEventHandler();
    handler.execute(Trigger.new);
}
```

```apex
public class LeadRoutingEventHandler {

    public void execute(List<Lead_Routing_Event__e> events) {
        // 1. Extract record IDs grouped by object type
        Map<String, List<Id>> recordsByType = groupByObjectType(events);

        // 2. Process each object type
        for (String objectType : recordsByType.keySet()) {
            List<Id> recordIds = recordsByType.get(objectType);

            // 3. Re-query records with fresh data
            List<SObject> records = queryRecords(recordIds, objectType);

            // 4. Idempotency check — skip records no longer in 'Pending'
            records = filterPendingOnly(records);
            if (records.isEmpty()) {
                continue;
            }

            // 5. Load active rules
            List<Lead_Routing_Rule__c> rules =
                LeadRoutingEngine.loadActiveRules(objectType);

            // 6. Pre-cache resolution data
            LeadRoutingTargetResolver resolver =
                new LeadRoutingTargetResolver(records, rules);

            // 7. Run the engine
            List<LeadRoutingEngine.RoutingResult> results =
                LeadRoutingEngine.evaluate(records, rules, resolver);

            // 8. Apply assignments
            List<SObject> toUpdate = new List<SObject>();
            List<Lead_Routing_History__c> historyRecords =
                new List<Lead_Routing_History__c>();

            for (LeadRoutingEngine.RoutingResult result : results) {
                toUpdate.add(result.buildUpdateRecord());
                historyRecords.addAll(result.buildHistoryRecords());
            }

            // 9. Persist with re-entry guard
            LeadRoutingContext.isRoutingInProgress = true;
            try {
                if (!toUpdate.isEmpty()) {
                    update toUpdate;
                }
                if (!historyRecords.isEmpty()) {
                    insert historyRecords;
                }
            } catch (Exception e) {
                // Set checkpoint so retry skips already-processed events
                EventBus.TriggerContext.currentContext()
                    .setResumeCheckpoint(
                        events[events.size() - 1].ReplayId
                    );
                // Platform will retry automatically
                throw new EventBus.RetryableException(
                    'Routing failed, retrying: ' + e.getMessage()
                );
            } finally {
                LeadRoutingContext.isRoutingInProgress = false;
            }
        }
    }

    private List<SObject> filterPendingOnly(List<SObject> records) {
        List<SObject> pending = new List<SObject>();
        for (SObject record : records) {
            if ((String) record.get('Routing_Status__c') == 'Pending') {
                pending.add(record);
            }
        }
        return pending;
    }
}
```

### 4.6 Re-Entry Prevention

When the event subscriber updates `OwnerId` on Lead/Contact, it re-fires the `after update` trigger on those objects. This must NOT re-publish events.

```
Lead trigger fires (insert) → stamps Pending → publishes Lead_Routing_Event__e
    ~~~ Event Bus ~~~
    Event trigger fires → re-queries → evaluates → updates OwnerId + Status = 'Routed'
        Lead trigger fires again (update from OwnerId change)
            → LeadRoutingContext.isRoutingInProgress = true → EXIT (no re-publish)
            → Also: shouldRoute() checks Routing_Status__c != 'Pending' → EXIT
```

**Double guard:** Both `LeadRoutingContext.isRoutingInProgress` (static flag within the same transaction) AND `shouldRoute()` checking `Routing_Status__c != 'Pending'` (data-level guard across transactions) prevent re-entry. The static flag handles the within-transaction re-fire; the status check handles edge cases where a separate transaction modifies the record.

### 4.7 Retry & Error Handling (Built-In + Safety Net)

**Primary retry: EventBus (automatic, no custom code):**

| Retry | Behavior |
|-------|----------|
| Mechanism | `EventBus.RetryableException` thrown from event trigger |
| Max retries | Up to 9 automatic retries |
| Backoff | Exponential backoff managed by the platform |
| Resume | `setResumeCheckpoint(ReplayId)` skips already-processed events on retry |
| Monitoring | `EventBusSubscriber` entity shows position, retries, errors in Setup |

**Safety net: `LeadRoutingRetryHandler` (Scheduled Apex, runs every 30 minutes):**

This is a lightweight fallback for the rare case where all 9 EventBus retries are exhausted.

```
Query: SELECT Id FROM Lead
       WHERE Routing_Status__c = 'Pending'
       AND LastModifiedDate < :DateTime.now().addMinutes(-10)

If results > 0:
    Publish Lead_Routing_Event__e for each record (re-triggers the subscriber)

If retry count > 3 (tracked via Routing_Retry_Count__c):
    Stamp Routing_Status__c = 'Unroutable'
    Create Lead_Routing_History__c with reason = 'Routing engine retry exhausted'
    Alert via Custom Notification / Email
```

**Note:** The safety net threshold is 10 minutes (not 5) because the EventBus retry backoff can take several minutes to exhaust all 9 attempts. This avoids the safety net conflicting with in-progress EventBus retries.

### 4.8 Idempotency

Because Platform Events provide at-least-once delivery, the subscriber **must be idempotent**:

1. **Before processing:** `filterPendingOnly()` skips records that are already `Routed`/`Fallback`/`Unroutable`
2. **During retry:** `setResumeCheckpoint()` ensures already-processed events in the same batch are not reprocessed
3. **Across transactions:** `Routing_Status__c` serves as a data-level idempotency key — once set to `Routed`, no further processing occurs even if a duplicate event arrives

### 4.9 Engine Core (Stateless, Testable)

`LeadRoutingEngine` is a **pure evaluation class** — no DML, no Platform Event awareness. This makes it independently unit-testable.

```
class LeadRoutingEngine:

    static method loadActiveRules(objectType) -> List<Rule>:
        SOQL: Lead_Routing_Rule__c WHERE Status__c = 'Active'
              AND (Object_Type__c = :objectType OR Object_Type__c = 'Both')
              ORDER BY Sequence__c ASC
              (include child Conditions and Targets via subqueries)

    static method evaluate(records, rules, resolver) -> List<RoutingResult>:
        results = []

        for each record in records:
            result = new RoutingResult(record)

            for each rule in rules:
                if LeadRoutingConditionEvaluator.evaluate(record, rule.conditions):
                    for each target in rule.targets (ORDER BY Priority__c ASC):
                        resolvedId = resolver.resolve(record, target)

                        if resolvedId != null:
                            result.assignedTo = resolvedId
                            result.ruleApplied = rule
                            result.targetUsed = target
                            result.isFallback = (target.Priority__c > 1)
                            result.status = result.isFallback ? 'Fallback' : 'Routed'
                            break
                        else:
                            result.addFallbackLog(rule, target)

                    if result.isAssigned():
                        break

            if not result.isAssigned():
                result.status = 'Unroutable'

            results.add(result)

        return results
```

### 4.10 Bulkification Strategy

- **Trigger layer (publisher):** Zero SOQL, one DML (`EventBus.publish()` — does not count against DML limits)
- **Event trigger layer (subscriber):** All SOQL runs BEFORE the evaluation loop
  - Rules + Conditions + Targets: 1 query with subqueries
  - ETM records for all Accounts in the batch: 1 query, stored in `Map<Id, UserTerritory2Association>`
  - User active status: 1 query, stored in `Map<Id, Boolean>`
  - Queue membership: 1 query per unique queue, stored in `Map<Id, List<GroupMember>>`
- **DML:** Exactly 2 DML operations per batch (update records + insert history)
- **Batching:** Handled automatically by the platform — no manual chunk/chain logic. Platform delivers up to 2,000 events per trigger invocation.
- **Known constraint (per BRD):** Patch Manager is not bulkified, but this is now fully isolated — Patch Manager runs in the Lead/Contact trigger transaction, routing runs in a completely separate Platform Event trigger transaction

### 4.11 SOQL Security

All queries use `WITH USER_MODE` per API 65.0+ standards (project uses API 66.0).

---

## 5. Round Robin Implementation

### 5.1 Approach

- When a rule has `Is_Round_Robin__c = true`, the engine uses `LeadRoutingRoundRobin` to assign.
- Uses a custom object `Round_Robin_State__c` to track the last assigned member index per queue.
- Queries `GroupMember` to get active queue members.
- Increments the index and wraps around.

### 5.2 Round_Robin_State__c

| Field | Type | Description |
|-------|------|-------------|
| `Queue_Id__c` | Text(18), Unique, External ID | The Queue being tracked |
| `Last_Assigned_Index__c` | Number(5,0) | Index of the last assigned member |
| `Last_Assigned_User__c` | Lookup(User) | Last user who received assignment |
| `Last_Assigned_Date__c` | DateTime | Timestamp |

### 5.3 Concurrency

- Uses `FOR UPDATE` on `Round_Robin_State__c` to prevent race conditions in simultaneous assignments.

---

## 6. LWC Rule Builder UI

### 6.1 Components

| Component | Description |
|-----------|-------------|
| `leadRoutingRuleList` | Main list view showing all rules with columns: Name, Status, Sequence, Object Type, Last Modified. Supports sorting and filtering. |
| `leadRoutingRuleBuilder` | Form for creating/editing a rule. Includes: rule metadata, condition builder (dynamic rows), target builder (ordered list with fallback cascade). |
| `leadRoutingConditionRow` | Reusable row component: Object picker -> Field picker -> Operator picker -> Value input. Field picker dynamically loads fields from `getObjectInfo` wire adapter. |
| `leadRoutingTargetRow` | Reusable row component: Priority, Target Type picker, conditional inputs (Queue, User, Field Reference). Drag-and-drop reordering for fallback priority. |
| `leadRoutingBulkReroute` | Action component for mass rerouting selected Lead/Contact records. |
| `leadRoutingHistory` | Related list / tab showing routing history for a specific record. |

### 6.2 Field Picker - Formula Field Constraint

Per BRD constraints:
- Formula fields referencing other formulas: supported to a limited extent.
- Formula fields referencing Custom Labels: **blocked** with a user-facing error message in the UI.

**Implementation:** The field picker component will call an Apex method that inspects `FieldDescribeResult` to detect formula fields. A secondary check queries `FieldDefinition` to inspect the formula body for `$Label` references. If found, the UI shows an inline error: _"This formula field references Custom Labels and cannot be used in routing conditions."_

### 6.3 Access Control

| Profile / Permission Set | Access |
|--------------------------|--------|
| `Lead_Routing_Admin` (Permission Set) | Full CRUD on all routing objects. Access to Rule Builder LWC. |
| Inside Sales Ops | Assigned `Lead_Routing_Admin` |
| Marketing Ops | Assigned `Lead_Routing_Admin` |
| Standard Users | Read-only on `Lead_Routing_History__c` via related list |

---

## 7. Approval Process

### 7.1 Process: Lead_Routing_Rule_Approval

| Setting | Value |
|---------|-------|
| **Object** | `Lead_Routing_Rule__c` |
| **Entry Criteria** | `Status__c = 'Draft'` AND all required fields populated |
| **Initial Submitter** | Record Creator |
| **Approver** | Queue: `Lead_Routing_Approvers` |
| **Queue Members** | Brandi Hennington, Daniel Chamberlin, Michelle Lee |
| **Approval Action** | Set `Status__c = 'Active'`, stamp `Approved_By__c`, `Approved_Date__c` |
| **Rejection Action** | Set `Status__c = 'Rejected'` |
| **Email Alert (Submit)** | Template per BRD (Rule Name, Sequence, Submitter) sent to approver queue |
| **Email Alert (Approve/Reject)** | Template per BRD (Rule Name, Sequence, Status) sent to submitter |

### 7.2 Decommission Rules

- Active rules **cannot** be deleted (validation rule blocks delete when `Status__c = 'Active'`).
- Users set `Status__c = 'Inactive'` to stop routing. The engine skips inactive rules.

---

## 8. Routing History & Cleanup

### 8.1 Retention Policy

- Rolling 6-month retention.
- `LeadRoutingHistoryCleanup` batch job runs nightly via Scheduled Apex.
- Deletes `Lead_Routing_History__c` records where `Routing_Timestamp__c < TODAY - 180`.

### 8.2 Reporting

- Custom Report Type: `Lead_Routing_History__c` with lookup to `Lead_Routing_Rule__c`.
- Key reports:
  - Fallback frequency by reason
  - Rules triggered per day/week
  - Average routing hops per record
  - Unroutable records

---

## 9. Bulk Reroute Capability

### 9.1 Approach

- `LeadRoutingBulkReroute` is an `@InvocableMethod` (callable from Flow and LWC).
- Accepts a list of Lead/Contact IDs.
- Stamps `Routing_Status__c = 'Pending'` on all selected records.
- **Small batches (< 200):** Publishes `Lead_Routing_Event__e` events directly via `EventBus.publish()`. The platform delivers them to the event subscriber trigger automatically.
- **Large batches (200+):** Uses `Database.Batchable` with a batch size of 200. Each `execute()` method publishes `Lead_Routing_Event__e` events for that batch scope. The platform's event delivery handles batching/scaling from there.

### 9.2 UI Access

- `leadRoutingBulkReroute` LWC placed as a List View action or Quick Action.
- User selects records -> clicks "Reroute" -> confirmation dialog -> records stamped as `Pending` -> events published.
- UI shows a progress indicator while `Routing_Status__c` transitions from `Pending` to `Routed`/`Fallback`.

---

## 10. Specific Rule Implementations (BRD Mapping)

### 10.1 Account Status Routing

| Condition | Target | Fallback Cascade |
|-----------|--------|-----------------|
| `Account_Status__c = 'Active Opp / Customer w/Opp'` | Account Owner | SDR (ETM) -> SDR Manager (ETM) -> AE (ETM) -> RD (ETM) |
| `Account_Status__c = 'Existing Customer'` | Account Owner | SDR (ETM) -> SDR Manager (ETM) -> AE (ETM) -> RD (ETM) |
| `Account_Status__c IN ('Prospect', 'Lost')` | SDR (ETM) | SDR Manager (ETM) -> AE (ETM) -> RD (ETM) |

**Applies to:** Both Lead and Contact.

### 10.2 CXO Routing

| Condition | Target | Fallback |
|-----------|--------|----------|
| Contact: `CXO__c = 'Yes'` / Lead: `Title` matches CXO pattern | Account Executive (ETM) | Next Rule |

### 10.3 Campaign-Based Routing

| Campaign_Routing_Method__c | Target | Fallback |
|---------------------------|--------|----------|
| `Partner Queue` | Partner Queue | Next Rule |
| `Direct to User` | User in `Direct_Routing_AE__c` | Next Rule |
| `Federal` | Federal Queue | Next Rule |
| `Partner of Record` | User in `Partner_of_Record__c` | Next Rule |

### 10.4 Rubrik X Routing

| Object | Target | Fallback |
|--------|--------|----------|
| Lead | Round Robin Pool (Queue: `00GVN000003bwg1`) | Next Rule |
| Contact | Rubrik X SDR via ETM | Next Rule |

### 10.5 ETM Routing

Standard ETM resolution with fallback cascade: SDR -> SDR Manager -> AE -> RD.

---

## 11. Phase 2 Items (Out of Scope - Phase 1)

These are documented for awareness but are **not** part of the Phase 1 build:

| Item | Notes |
|------|-------|
| Patch Key Migration | Domain, Industry, Geography matching via Patch Keys |
| Fair Distribution / Skill-Based | Advanced assignment algorithms beyond Round Robin |
| PTO Calendar Integration | User availability / Out-of-Office checks |
| Rule Expiration / Decay | Automatic rule deactivation after a set period |
| Cross-Object Rules | Rules on objects not directly related to Lead/Contact |

---

## 12. Constraints & Limitations

| # | Constraint | Mitigation |
|---|-----------|------------|
| 1 | No automatic conflict detection between rules | Approver (human) is responsible for reviewing rule conflicts during approval |
| 2 | No auto-expiration for rules | Users must manually set Status to Inactive |
| 3 | Cannot create a single rule for both Lead AND Contact | `Object_Type__c = 'Both'` creates two internal evaluation paths but stored as one rule |
| 4 | Formula fields referencing Custom Labels cannot be used | UI blocks selection with error message |
| 5 | Patch Manager is not bulkified | Fully isolated — routing runs in Platform Event trigger transaction, Patch Manager stays in Lead/Contact trigger transaction. Zero shared governor pressure. |
| 6 | Formula-to-formula field references | Limited support; tested on case-by-case basis |
| 7 | Routing is not instantaneous (async pattern) | ~1-3 second delay. Records show `Routing_Status__c = 'Pending'` briefly. Acceptable per stakeholder review. |
| 8 | Platform Event at-least-once delivery | Duplicate events possible in rare cases | Engine is idempotent — `filterPendingOnly()` skips records already routed. `Routing_Status__c` acts as a data-level idempotency key. |
| 9 | Platform Event trigger testing | `EventBus.deliver()` required in test context to deliver events synchronously | Tests use `Test.startTest()` + `EventBus.deliver()` pattern. Engine is independently testable without events. |
| 10 | EventBus retry exhaustion / stuck records | `LeadRoutingRetryHandler` safety net scheduled job re-publishes events for stuck `Pending` records every 30 min. Max 3 safety-net retries before marking `Unroutable`. |

---

## 13. Testing Strategy

| Test Area | Approach | Coverage Target |
|-----------|----------|-----------------|
| Unit Tests | Apex test classes for all service/utility classes | 90%+ |
| Engine (stateless) | Test `LeadRoutingEngine.evaluate()` directly with mock records/rules — no Platform Event needed | All operators, multi-condition, edge cases |
| Platform Event Integration | Insert records in `Test.startTest()` block → call `EventBus.deliver()` to force synchronous event delivery → assert OwnerId + Routing_Status | End-to-end routing verified |
| Re-entry Prevention | Insert record → deliver events → verify Lead/Contact trigger does NOT re-publish events on OwnerId update | Both `LeadRoutingContext` flag and `Routing_Status__c` guard validated |
| Idempotency | Publish duplicate events for same record → verify only one routing occurs, second event is a no-op | At-least-once delivery resilience |
| Fallback Cascade | Verify each fallback reason is logged correctly in `Lead_Routing_History__c` | All 11 fallback reasons |
| Round Robin | Verify fair distribution, index wrapping, concurrency | Concurrent assignment scenarios |
| EventBus Retry | Force `EventBus.RetryableException` in test → verify `setResumeCheckpoint()` behavior and event redelivery | Retry + partial progress path |
| Safety Net Handler | Insert records, stamp `Pending`, set `LastModifiedDate` backdated → run `LeadRoutingRetryHandler` → verify re-publish or `Unroutable` after 3 retries | Retry exhaustion path |
| Bulk Reroute | Call `LeadRoutingBulkReroute` invocable with 500+ record IDs → verify Batchable publishes events | Large batch path |
| LWC | Jest tests for all components, including `Pending` status indicator | Component interaction and validation |
| UAT | MOPs/ISOPs create real rules and validate routing, including async delay acceptance | Per BRD: Jun 11-24, 2026 |

---

## 14. Deployment Plan

| Phase | Timeline | Components |
|-------|----------|------------|
| Sprint 1-2 | Mar 30 - Apr 10 | Custom Objects, Fields, Permission Sets |
| Sprint 3-4 | Apr 13 - Apr 24 | Platform Event definition, Event Trigger/Handler, Routing Engine Apex, Lead/Contact Triggers, Safety Net Handler |
| Sprint 5-6 | Apr 27 - May 8 | LWC Rule Builder UI |
| Sprint 7 | May 11 - May 15 | Round Robin, Bulk Reroute |
| Sprint 8 | May 18 - May 22 | Approval Process, Email Templates |
| Sprint 9 | May 25 - May 29 | History, Cleanup Job, Reports |
| QA | Apr 6 - Jun 5 | Rolling QA as sprints complete |
| UAT | Jun 11 - Jun 24 | Business validation |
| GA | Jun 30 | CAB approval, Stage + Prod deployment |
| Hypercare | Jul 6 | Post-deploy monitoring |

---

## 15. Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Platform Event subscriber failure | Records stuck in `Pending` status | `EventBus.RetryableException` provides up to 9 automatic retries with backoff. `setResumeCheckpoint()` enables partial-batch recovery. `LeadRoutingRetryHandler` safety net catches anything that falls through after 10 minutes. |
| 2 | At-least-once delivery / duplicate events | Same record could be processed twice | Engine is idempotent: `filterPendingOnly()` skips records not in `Pending` status. `Routing_Status__c` is the data-level idempotency key. |
| 3 | Event delivery delay under high org event volume | Routing takes longer than expected during peak hours | Monitor `EventBusSubscriber` entity for subscriber lag. Platform Events scale better than async Apex queue. Alert if lag exceeds 10 seconds. |
| 4 | Rapid duplicate updates to same record | Two events published for one record | `shouldRoute()` checks `Routing_Status__c != 'Pending'` before publishing. Subscriber's `filterPendingOnly()` provides second guard. Re-query ensures fresh data. |
| 5 | Formula field evaluation complexity | Some formula fields may not be evaluable in Apex | Pre-validate formula fields in UI; maintain blocklist |
| 6 | Rule ordering conflicts | Incorrect sequencing leads to wrong assignments | Approval process + UI displays active rule priority list |
| 7 | ETM data quality | Missing territory assignments cause cascading fallbacks | Fallback tracking + dashboard alerting on high fallback rates |
| 8 | Concurrent Round Robin assignments | Race conditions under high load | `FOR UPDATE` locking on `Round_Robin_State__c` |
| 9 | Patch Manager interaction | Patch Manager runs in Lead/Contact trigger, routing runs in separate event trigger transaction | Event subscriber re-queries records with fresh data, so all Patch Manager changes are visible. Complete transaction isolation — no timing risk. |

---

## Appendix A: Object Relationship Diagram

```
Lead_Routing_Rule__c (Parent)
    |
    +-- Lead_Routing_Condition__c (Master-Detail, 1:Many)
    |
    +-- Lead_Routing_Target__c (Master-Detail, 1:Many)

Lead_Routing_History__c (Standalone, Lookup to Rule)

Round_Robin_State__c (Standalone, keyed by Queue ID)

Lead_Routing_Event__e (Platform Event)
    +-- Record_Id__c               (Text 18 — Lead or Contact ID)
    +-- Object_Type__c             (Text 20 — 'Lead' or 'Contact')
    +-- Publish Behavior:          Publish After Commit

Lead / Contact
    +-- Routing_Status__c          (Pending → Routed/Fallback/Unroutable)
    +-- Routing_Fallback__c
    +-- Routing_Fallback_Reason__c
    +-- Last_Routed_Date__c
    +-- Last_Routing_Rule__c
    +-- Routing_Retry_Count__c     (0-3, used by safety net RetryHandler)
```

---

## Appendix B: Email Templates

### Approval Request Template

```
Subject: Lead Routing Rule Submitted for Approval: {!Lead_Routing_Rule__c.Rule_Name__c}

Hi Team,

Please review and approve the Lead Routing Rule with the below details:

Lead Routing Rule Name: {!Lead_Routing_Rule__c.Rule_Name__c}
Sequence: {!Lead_Routing_Rule__c.Sequence__c}
Submitter: {!Lead_Routing_Rule__c.Created_By_User__c}

Thanks
```

### Approval/Rejection Notification Template

```
Subject: Lead Routing Rule {!Lead_Routing_Rule__c.Status__c}: {!Lead_Routing_Rule__c.Rule_Name__c}

Hi there,

Please note that the Lead Routing Rule below has been {!Lead_Routing_Rule__c.Status__c}:

Lead Routing Rule Name: {!Lead_Routing_Rule__c.Rule_Name__c}
Sequence: {!Lead_Routing_Rule__c.Sequence__c}
Status: {!Lead_Routing_Rule__c.Status__c}

Thanks
```
