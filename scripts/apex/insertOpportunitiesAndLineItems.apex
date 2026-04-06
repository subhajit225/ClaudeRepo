/**
 * Anonymous Apex script to insert Opportunities and OpportunityLineItems.
 *
 * Prerequisites (must already exist in the org):
 *   - Account: Pinnacle Solutions Group  (001U800000dqAo1IAE)
 *   - Account: Meridian Healthcare Partners (001U800000dqAo2IAE)
 *   - Product: RA-TRN-VTL-PP (01tU800000F6NXZIA3)
 *
 * Dependency order:
 *   1. Query Standard Pricebook
 *   2. Insert PricebookEntry in Standard Pricebook (required before any other PBE)
 *   3. Insert Opportunities (linked to Accounts and Standard Pricebook)
 *   4. Re-query Opportunities to detect trigger-assigned Pricebook changes
 *   5. Ensure PricebookEntry exists in each Opportunity's actual Pricebook
 *   6. Insert OpportunityLineItems using the correct PricebookEntry
 *
 * NOTE: The OpportunityTrigger in this org may reassign the Pricebook2Id
 * (e.g., from Standard to CPQ PriceBook). This script handles that gracefully
 * by re-querying Opportunities after insert and creating PricebookEntries
 * in whatever Pricebook the trigger assigned.
 */

// ── Constants ────────────────────────────────────────────────────────────────
Id accountId1 = '001U800000dqAo1IAE'; // Pinnacle Solutions Group
Id accountId2 = '001U800000dqAo2IAE'; // Meridian Healthcare Partners
Id productId  = '01tU800000F6NXZIA3'; // RA-TRN-VTL-PP

Decimal unitPrice = 5000;
Integer quantity  = 1;
String stageName  = 'Prospecting';
String oppType    = 'New Business';
Date closeDate    = Date.today().addDays(90);

try {
    // ── Step 1: Query Standard Pricebook ─────────────────────────────────
    Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    System.debug('Standard Pricebook Id: ' + stdPb.Id);

    // ── Step 2: Insert PricebookEntry in Standard Pricebook ──────────────
    List<PricebookEntry> existingStdPbes = [
        SELECT Id
        FROM PricebookEntry
        WHERE Product2Id = :productId
          AND Pricebook2Id = :stdPb.Id
        LIMIT 1
    ];

    PricebookEntry stdPbe;
    if (!existingStdPbes.isEmpty()) {
        stdPbe = existingStdPbes[0];
        System.debug('Standard PricebookEntry already exists. Id: ' + stdPbe.Id);
    } else {
        stdPbe = new PricebookEntry(
            Product2Id   = productId,
            Pricebook2Id = stdPb.Id,
            UnitPrice    = unitPrice,
            IsActive     = true
        );
        Database.SaveResult pbeSr = Database.insert(stdPbe, true);
        System.debug('Standard PricebookEntry inserted. Id: ' + pbeSr.getId());
    }

    // ── Step 3: Insert Opportunities ─────────────────────────────────────
    List<Opportunity> opps = new List<Opportunity>();

    opps.add(new Opportunity(
        Name         = 'Pinnacle Solutions Group - Training Opportunity',
        AccountId    = accountId1,
        Pricebook2Id = stdPb.Id,
        StageName    = stageName,
        CloseDate    = closeDate,
        Type         = oppType
    ));

    opps.add(new Opportunity(
        Name         = 'Meridian Healthcare Partners - Training Opportunity',
        AccountId    = accountId2,
        Pricebook2Id = stdPb.Id,
        StageName    = stageName,
        CloseDate    = closeDate,
        Type         = oppType
    ));

    List<Database.SaveResult> oppResults = Database.insert(opps, false);
    Set<Id> insertedOppIds = new Set<Id>();

    for (Integer i = 0; i < oppResults.size(); i++) {
        if (oppResults[i].isSuccess()) {
            System.debug('Opportunity inserted: ' + opps[i].Name + ' | Id: ' + oppResults[i].getId());
            insertedOppIds.add(oppResults[i].getId());
        } else {
            System.debug('ERROR inserting Opportunity: ' + opps[i].Name);
            for (Database.Error err : oppResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
                System.debug('  Fields: ' + err.getFields());
            }
        }
    }

    if (insertedOppIds.isEmpty()) {
        System.debug('No Opportunities were inserted. Skipping OpportunityLineItem creation.');
        return;
    }

    // ── Step 4: Re-query Opps to get actual Pricebook2Id after triggers ──
    List<Opportunity> insertedOpps = [
        SELECT Id, Name, Pricebook2Id
        FROM Opportunity
        WHERE Id IN :insertedOppIds
    ];

    // ── Step 5: Ensure PBE exists in each Opportunity's actual Pricebook ─
    // Collect distinct Pricebook Ids from the inserted Opportunities
    Set<Id> actualPbIds = new Set<Id>();
    for (Opportunity opp : insertedOpps) {
        if (opp.Pricebook2Id != null) {
            actualPbIds.add(opp.Pricebook2Id);
        }
    }

    // Query existing PBEs for this product across all relevant pricebooks
    Map<Id, PricebookEntry> pbeByPricebookId = new Map<Id, PricebookEntry>();
    for (PricebookEntry existingPbe : [
        SELECT Id, Pricebook2Id
        FROM PricebookEntry
        WHERE Product2Id = :productId
          AND Pricebook2Id IN :actualPbIds
    ]) {
        pbeByPricebookId.put(existingPbe.Pricebook2Id, existingPbe);
    }

    // Create missing PBEs for non-standard pricebooks
    List<PricebookEntry> newPbes = new List<PricebookEntry>();
    for (Id pbId : actualPbIds) {
        if (!pbeByPricebookId.containsKey(pbId)) {
            newPbes.add(new PricebookEntry(
                Product2Id   = productId,
                Pricebook2Id = pbId,
                UnitPrice    = unitPrice,
                IsActive     = true
            ));
        }
    }

    if (!newPbes.isEmpty()) {
        Database.SaveResult[] pbeResults = Database.insert(newPbes, true);
        for (Integer i = 0; i < pbeResults.size(); i++) {
            System.debug('Additional PricebookEntry inserted for Pricebook: '
                + newPbes[i].Pricebook2Id + ' | Id: ' + pbeResults[i].getId());
            pbeByPricebookId.put(newPbes[i].Pricebook2Id, newPbes[i]);
        }
    }

    // ── Step 6: Insert OpportunityLineItems ──────────────────────────────
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    for (Opportunity opp : insertedOpps) {
        PricebookEntry matchingPbe = pbeByPricebookId.get(opp.Pricebook2Id);
        if (matchingPbe == null) {
            System.debug('WARNING: No PricebookEntry found for Opp ' + opp.Name
                + ' (Pricebook2Id: ' + opp.Pricebook2Id + '). Skipping OLI.');
            continue;
        }
        olis.add(new OpportunityLineItem(
            OpportunityId    = opp.Id,
            PricebookEntryId = matchingPbe.Id,
            Quantity         = quantity,
            UnitPrice        = unitPrice
        ));
    }

    List<Database.SaveResult> oliResults = Database.insert(olis, false);
    for (Integer i = 0; i < oliResults.size(); i++) {
        if (oliResults[i].isSuccess()) {
            System.debug('OpportunityLineItem inserted for Opp: '
                + insertedOpps[i].Name + ' | OLI Id: ' + oliResults[i].getId());
        } else {
            System.debug('ERROR inserting OpportunityLineItem for Opp: ' + insertedOpps[i].Name);
            for (Database.Error err : oliResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
                System.debug('  Fields: ' + err.getFields());
            }
        }
    }

    // ── Summary ──────────────────────────────────────────────────────────
    System.debug('=== SCRIPT COMPLETE ===');
    System.debug('Standard PricebookEntry Id: ' + stdPbe.Id);
    for (Opportunity opp : insertedOpps) {
        System.debug('Opportunity: ' + opp.Name + ' | Id: ' + opp.Id
            + ' | Pricebook2Id: ' + opp.Pricebook2Id);
    }

} catch (Exception ex) {
    System.debug('UNHANDLED EXCEPTION: ' + ex.getTypeName() + ' - ' + ex.getMessage());
    System.debug('Stack Trace: ' + ex.getStackTraceString());
}
