/**
 * Anonymous Apex Script: Insert CPQ Quotes, QuoteLines, Orders, and OrderItems
 *
 * Prerequisites:
 *   - Opportunity 1: Pinnacle Solutions Group - Training Opportunity (006U800000OK4L0IAL)
 *   - Opportunity 2: Meridian Healthcare Partners - Training Opportunity (006U800000OK4L1IAL)
 *   - Product2 Id: 01tU800000F6NXZIA3  (ProductCode: RA-TRN-VTL-PP)
 *   - Standard PricebookEntry Id: 01uU8000009xa77IAA
 *   - CPQ PricebookEntry Id: 01uU8000009xaALIAY
 *
 * Trigger control strategy (mirrors OrderMainTriggerTest pattern):
 *   1. SBQQ.TriggerControl.disable()            -- disables all CPQ managed-package triggers
 *   2. TriggerControls static booleans           -- disables QuoteTrigger, SBQQ_QuoteLineTrigger
 *   3. TriggerControl static booleans            -- disables OrderItemMain, OrderMainTrigger
 *   4. ShGl_DisableBusinessLogic__c (user-level) -- disables declarative + Apex trigger checks
 *   5. Re-enable everything in a finally block
 */

// ── Known Ids ──────────────────────────────────────────────────────────────────
Id oppId1        = '006U800000OK4L0IAL'; // Pinnacle Solutions Group
Id oppId2        = '006U800000OK4L1IAL'; // Meridian Healthcare Partners
Id productId     = '01tU800000F6NXZIA3'; // RA-TRN-VTL-PP
Id cpqPbeId      = '01uU8000009xaALIAY'; // CPQ PricebookEntry

// ── Disable all triggers before DML ────────────────────────────────────────────
SBQQ.TriggerControl.disable();
TriggerControls.disableQuoteTrigger     = true;
TriggerControls.disableQuoteLineTrigger = true;
TriggerControl.stopOrderTrigger         = true;
TriggerControl.stopOrderItemTrigger     = true;
TriggerControl.stopOrderItemExtensionTrigger = true;

// Insert or update user-level custom setting to disable validation rules & triggers
ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
Boolean dblExisted = (dbl != null && dbl.Id != null);
if (dbl == null) {
    dbl = new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getUserId());
}
dbl.Disable_SBQQ_Quote_Triggers__c              = true;
dbl.Disable_SBQQ_QuoteLine_Triggers__c          = true;
dbl.Disable_SBQQ_Quote_Validation_Rules__c      = true;
dbl.Disable_SBQQ_QuoteLine_Validation_Rules__c  = true;
dbl.Disable_Order_Triggers__c                    = true;
dbl.Disable_Order_Validation_Rules__c            = true;
dbl.Disable_Order_Old_Trigger__c                 = true;
dbl.Disable_OrderItem_Trigger__c                 = true;
dbl.Disable_OrderItemExtension_Trigger__c        = true;
dbl.Disable_Opportunity_Triggers__c              = true;
dbl.Disable_Opportunity_Validation_Rules__c      = true;
dbl.Disable_Entitlement_Validation_Rules__c      = true;
upsert dbl;

try {
    // ── Step 1: Query Opportunities ────────────────────────────────────────────
    List<Opportunity> opps = [
        SELECT Id, Name, AccountId, Pricebook2Id
        FROM Opportunity
        WHERE Id IN (:oppId1, :oppId2)
    ];

    if (opps.size() != 2) {
        System.debug('ERROR: Expected 2 Opportunities, found ' + opps.size());
        return;
    }

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    for (Opportunity o : opps) {
        oppMap.put(o.Id, o);
    }

    Opportunity opp1 = oppMap.get(oppId1);
    Opportunity opp2 = oppMap.get(oppId2);

    System.debug('Opp1: ' + opp1.Name + ' | AccountId: ' + opp1.AccountId + ' | Pricebook2Id: ' + opp1.Pricebook2Id);
    System.debug('Opp2: ' + opp2.Name + ' | AccountId: ' + opp2.AccountId + ' | Pricebook2Id: ' + opp2.Pricebook2Id);

    Id cpqPricebookId = opp1.Pricebook2Id; // Both Opps should share the CPQ Pricebook

    // ── Step 2: Create 4 SBQQ__Quote__c records (2 per Opportunity) ────────────
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

    // Pinnacle Solutions - Quote 1
    quotes.add(new SBQQ__Quote__c(
        SBQQ__Opportunity2__c   = opp1.Id,
        SBQQ__Account__c        = opp1.AccountId,
        SBQQ__Primary__c        = true,
        SBQQ__Status__c         = 'Draft',
        SBQQ__PricebookId__c    = cpqPricebookId,
        SBQQ__ExpirationDate__c = Date.today().addDays(30),
        SBQQ__StartDate__c      = Date.today(),
        SBQQ__EndDate__c        = Date.today().addDays(365)
    ));

    // Pinnacle Solutions - Quote 2
    quotes.add(new SBQQ__Quote__c(
        SBQQ__Opportunity2__c   = opp1.Id,
        SBQQ__Account__c        = opp1.AccountId,
        SBQQ__Primary__c        = true,
        SBQQ__Status__c         = 'Draft',
        SBQQ__PricebookId__c    = cpqPricebookId,
        SBQQ__ExpirationDate__c = Date.today().addDays(30),
        SBQQ__StartDate__c      = Date.today(),
        SBQQ__EndDate__c        = Date.today().addDays(365)
    ));

    // Meridian Healthcare - Quote 1
    quotes.add(new SBQQ__Quote__c(
        SBQQ__Opportunity2__c   = opp2.Id,
        SBQQ__Account__c        = opp2.AccountId,
        SBQQ__Primary__c        = true,
        SBQQ__Status__c         = 'Draft',
        SBQQ__PricebookId__c    = cpqPricebookId,
        SBQQ__ExpirationDate__c = Date.today().addDays(30),
        SBQQ__StartDate__c      = Date.today(),
        SBQQ__EndDate__c        = Date.today().addDays(365)
    ));

    // Meridian Healthcare - Quote 2
    quotes.add(new SBQQ__Quote__c(
        SBQQ__Opportunity2__c   = opp2.Id,
        SBQQ__Account__c        = opp2.AccountId,
        SBQQ__Primary__c        = true,
        SBQQ__Status__c         = 'Draft',
        SBQQ__PricebookId__c    = cpqPricebookId,
        SBQQ__ExpirationDate__c = Date.today().addDays(30),
        SBQQ__StartDate__c      = Date.today(),
        SBQQ__EndDate__c        = Date.today().addDays(365)
    ));

    List<Database.SaveResult> quoteResults = Database.insert(quotes, false);
    for (Integer i = 0; i < quoteResults.size(); i++) {
        if (quoteResults[i].isSuccess()) {
            System.debug('Quote ' + (i + 1) + ' inserted | Id: ' + quoteResults[i].getId());
        } else {
            System.debug('ERROR Quote ' + (i + 1) + ':');
            for (Database.Error err : quoteResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    // Re-query quotes to get auto-generated Names
    List<SBQQ__Quote__c> insertedQuotes = [
        SELECT Id, Name, SBQQ__Opportunity2__c
        FROM SBQQ__Quote__c
        WHERE Id IN :quotes
        ORDER BY SBQQ__Opportunity2__c, CreatedDate
    ];

    for (SBQQ__Quote__c q : insertedQuotes) {
        System.debug('Quote Name: ' + q.Name + ' | Id: ' + q.Id + ' | OppId: ' + q.SBQQ__Opportunity2__c);
    }

    // ── Step 3: Create 4 SBQQ__QuoteLine__c records (1 per Quote) ─────────────
    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
    for (SBQQ__Quote__c q : insertedQuotes) {
        quoteLines.add(new SBQQ__QuoteLine__c(
            SBQQ__Quote__c            = q.Id,
            SBQQ__Product__c          = productId,
            SBQQ__PricebookEntryId__c = cpqPbeId,
            SBQQ__Quantity__c         = 1,
            SBQQ__ListPrice__c        = 5500,
            SBQQ__NetPrice__c         = 5000,
            SBQQ__CustomerPrice__c    = 5000,
            SBQQ__RegularPrice__c     = 5500,
            SBQQ__Discount__c         = 9.09
        ));
    }

    List<Database.SaveResult> qlResults = Database.insert(quoteLines, false);
    for (Integer i = 0; i < qlResults.size(); i++) {
        if (qlResults[i].isSuccess()) {
            System.debug('QuoteLine ' + (i + 1) + ' inserted | Id: ' + qlResults[i].getId()
                + ' | QuoteId: ' + insertedQuotes[i].Id);
        } else {
            System.debug('ERROR QuoteLine ' + (i + 1) + ':');
            for (Database.Error err : qlResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    // ── Step 4: Create 4 Order records (1 per Quote) ───────────────────────────
    List<Order> orders = new List<Order>();
    for (Integer i = 0; i < insertedQuotes.size(); i++) {
        SBQQ__Quote__c q = insertedQuotes[i];
        Id accountId = (q.SBQQ__Opportunity2__c == oppId1) ? opp1.AccountId : opp2.AccountId;

        orders.add(new Order(
            SBQQ__Quote__c  = q.Id,
            AccountId       = accountId,
            OpportunityId   = q.SBQQ__Opportunity2__c,
            EffectiveDate   = Date.today(),
            EndDate         = Date.today().addDays(365),
            Status          = 'Draft',
            Type            = 'Order',
            Pricebook2Id    = cpqPricebookId
        ));
    }

    List<Database.SaveResult> orderResults = Database.insert(orders, false);
    for (Integer i = 0; i < orderResults.size(); i++) {
        if (orderResults[i].isSuccess()) {
            System.debug('Order ' + (i + 1) + ' inserted | Id: ' + orderResults[i].getId()
                + ' | QuoteId: ' + insertedQuotes[i].Id);
        } else {
            System.debug('ERROR Order ' + (i + 1) + ':');
            for (Database.Error err : orderResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    // ── Step 5: Create 4 OrderItem records (1 per Order) ───────────────────────
    List<OrderItem> orderItems = new List<OrderItem>();
    for (Integer i = 0; i < orders.size(); i++) {
        if (orders[i].Id == null) {
            System.debug('Skipping OrderItem for Order ' + (i + 1) + ' (Order insert failed)');
            continue;
        }
        orderItems.add(new OrderItem(
            OrderId              = orders[i].Id,
            SBQQ__QuoteLine__c   = quoteLines[i].Id,
            Product2Id           = productId,
            PricebookEntryId     = cpqPbeId,
            Quantity             = 1,
            UnitPrice            = 5000
        ));
    }

    List<Database.SaveResult> oiResults = Database.insert(orderItems, false);
    for (Integer i = 0; i < oiResults.size(); i++) {
        if (oiResults[i].isSuccess()) {
            System.debug('OrderItem ' + (i + 1) + ' inserted | Id: ' + oiResults[i].getId()
                + ' | OrderId: ' + orderItems[i].OrderId);
        } else {
            System.debug('ERROR OrderItem ' + (i + 1) + ':');
            for (Database.Error err : oiResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    System.debug('=== ALL INSERTIONS COMPLETE ===');
    System.debug('Quotes inserted:     ' + [SELECT COUNT() FROM SBQQ__Quote__c WHERE Id IN :quotes]);
    System.debug('QuoteLines inserted: ' + [SELECT COUNT() FROM SBQQ__QuoteLine__c WHERE Id IN :quoteLines]);
    System.debug('Orders inserted:     ' + [SELECT COUNT() FROM Order WHERE Id IN :orders]);
    System.debug('OrderItems inserted: ' + [SELECT COUNT() FROM OrderItem WHERE Id IN :orderItems]);

} catch (Exception ex) {
    System.debug('UNHANDLED EXCEPTION: ' + ex.getTypeName() + ' - ' + ex.getMessage());
    System.debug('Stack Trace: ' + ex.getStackTraceString());
} finally {
    // ── Re-enable all triggers ─────────────────────────────────────────────────
    SBQQ.TriggerControl.enable();
    TriggerControls.disableQuoteTrigger     = false;
    TriggerControls.disableQuoteLineTrigger = false;
    TriggerControl.stopOrderTrigger         = false;
    TriggerControl.stopOrderItemTrigger     = false;
    TriggerControl.stopOrderItemExtensionTrigger = false;

    // Reset custom setting to not leave triggers disabled for the user
    ShGl_DisableBusinessLogic__c resetDbl = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if (resetDbl != null && resetDbl.Id != null) {
        resetDbl.Disable_SBQQ_Quote_Triggers__c              = false;
        resetDbl.Disable_SBQQ_QuoteLine_Triggers__c          = false;
        resetDbl.Disable_SBQQ_Quote_Validation_Rules__c      = false;
        resetDbl.Disable_SBQQ_QuoteLine_Validation_Rules__c  = false;
        resetDbl.Disable_Order_Triggers__c                    = false;
        resetDbl.Disable_Order_Validation_Rules__c            = false;
        resetDbl.Disable_Order_Old_Trigger__c                 = false;
        resetDbl.Disable_OrderItem_Trigger__c                 = false;
        resetDbl.Disable_OrderItemExtension_Trigger__c        = false;
        resetDbl.Disable_Opportunity_Triggers__c              = false;
        resetDbl.Disable_Opportunity_Validation_Rules__c      = false;
        resetDbl.Disable_Entitlement_Validation_Rules__c      = false;
        update resetDbl;
        System.debug('ShGl_DisableBusinessLogic__c reset to defaults.');
    }

    System.debug('All trigger controls re-enabled.');
}
