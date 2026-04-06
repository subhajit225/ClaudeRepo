/**
 * Follow-up script: Insert OpportunityLineItems for Opportunities that were
 * reassigned to the CPQ PriceBook by trigger logic.
 *
 * Steps:
 *   1. Query the CPQ PriceBook
 *   2. Insert a PricebookEntry for RA-TRN-VTL-PP in the CPQ PriceBook
 *      (Standard PBE already exists from the prior script)
 *   3. Insert OpportunityLineItems using the CPQ PricebookEntry
 */

Id productId = '01tU800000F6NXZIA3'; // RA-TRN-VTL-PP
Id oppId1    = '006U800000OK4L0IAL'; // Pinnacle Solutions Group - Training Opportunity
Id oppId2    = '006U800000OK4L1IAL'; // Meridian Healthcare Partners - Training Opportunity
Id cpqPbId   = '01s1W0000003MzoQAE'; // CPQ PriceBook

Decimal unitPrice = 5000;
Integer quantity  = 1;

try {
    // ── Step 1: Create PricebookEntry in CPQ PriceBook ───────────────────
    List<PricebookEntry> existingPbes = [
        SELECT Id
        FROM PricebookEntry
        WHERE Product2Id = :productId
          AND Pricebook2Id = :cpqPbId
        LIMIT 1
    ];

    PricebookEntry cpqPbe;
    if (!existingPbes.isEmpty()) {
        cpqPbe = existingPbes[0];
        System.debug('CPQ PricebookEntry already exists. Id: ' + cpqPbe.Id);
    } else {
        cpqPbe = new PricebookEntry(
            Product2Id   = productId,
            Pricebook2Id = cpqPbId,
            UnitPrice    = unitPrice,
            IsActive     = true
        );
        Database.SaveResult pbeSr = Database.insert(cpqPbe, true);
        System.debug('CPQ PricebookEntry inserted. Id: ' + pbeSr.getId());
    }

    // ── Step 2: Insert OpportunityLineItems ──────────────────────────────
    List<Opportunity> opps = [
        SELECT Id, Name FROM Opportunity WHERE Id IN (:oppId1, :oppId2)
    ];

    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    for (Opportunity opp : opps) {
        olis.add(new OpportunityLineItem(
            OpportunityId    = opp.Id,
            PricebookEntryId = cpqPbe.Id,
            Quantity         = quantity,
            UnitPrice        = unitPrice
        ));
    }

    List<Database.SaveResult> oliResults = Database.insert(olis, false);
    for (Integer i = 0; i < oliResults.size(); i++) {
        if (oliResults[i].isSuccess()) {
            System.debug('OpportunityLineItem inserted for Opp: ' + opps[i].Name + ' | OLI Id: ' + oliResults[i].getId());
        } else {
            System.debug('ERROR inserting OpportunityLineItem for Opp: ' + opps[i].Name);
            for (Database.Error err : oliResults[i].getErrors()) {
                System.debug('  ' + err.getStatusCode() + ': ' + err.getMessage());
                System.debug('  Fields: ' + err.getFields());
            }
        }
    }

    System.debug('=== OLI INSERTION COMPLETE ===');

} catch (Exception ex) {
    System.debug('UNHANDLED EXCEPTION: ' + ex.getTypeName() + ' - ' + ex.getMessage());
    System.debug('Stack Trace: ' + ex.getStackTraceString());
}
