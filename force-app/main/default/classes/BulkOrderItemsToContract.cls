/**
 * @description
 * Queueable to process OrderItems for a given Order:
 * 1) Build a Map<OrderItem.Id, SBQQ__RequiredBy__c>
 * 2) Blank SBQQ__RequiredBy__c for ALL OrderItems for the Order
 * 3) For records AFTER the first 200, set SBQQ__Contracted__c = true and update only those
 * 4) At the end, restore original SBQQ__RequiredBy__c for ALL OrderItems and update those
 *
 * Notes:
 * - Uses Database methods with USER_MODE
 * - Bulk-safe (no DML/Queries in loops)
 * - with sharing to respect sharing rules
 * - Returns early on invalid inputs
 *  * Modifications Log
 * Ver   Date           Author          Modification
 * 1.0   12-30-2025        Naveem/Hemant   Initial Version - PRDOPS26-1373
*****************************************************************************************/
public with sharing class BulkOrderItemsToContract implements Queueable {

    private final Id orderId;
    private Map<Id, Id> requiredByMapInternal;
    @TestVisible
    private List<Error_Logs__c> logsToInsert = new List<Error_Logs__c>();

    /**
     * @description Entry constructor. Starts at BUILD_AND_BLANK step.
     * @param orderId Id of the Order to process
     */
    public BulkOrderItemsToContract(Id orderId) {
        this.orderId = orderId;
        this.requiredByMapInternal = new Map<Id, Id>();
    }  
    /**
     * @description Logic for marking contracted.
     * @param context Queueable context.
     */
    public void execute(QueueableContext context) {


        if (orderId == null) {
            return;
        }
        try {
            TriggerControl.stopOrderTrigger = true;
            
            List<OrderItem> orderItems = [
                SELECT Id, SBQQ__RequiredBy__c, SBQQ__Contracted__c
                FROM OrderItem
                WHERE OrderId = :orderId 
            ];
            if (orderItems.isEmpty()) {
                return;
            }

            requiredByMapInternal.clear();
            List<Id> ordereItemIds = new List<Id>();
            List<OrderItem> blankRequiredBy = new List<OrderItem>();
            for (OrderItem oi : orderItems) {
                if(oi.SBQQ__Contracted__c== false){
                    ordereItemIds.add(oi.Id);
                }
                requiredByMapInternal.put(oi.Id, oi.SBQQ__RequiredBy__c);
                if (oi.SBQQ__RequiredBy__c != null) {
                    blankRequiredBy.add(new OrderItem(Id = oi.Id, SBQQ__RequiredBy__c = null));
                }
            }

            if (!blankRequiredBy.isEmpty()) {
                handleDatabaseResults(Database.update(blankRequiredBy, false), 'Blanking RequiredBy');
            }
    
            // 2) Set SBQQ__Contracted__c = true only for records after the first 200
            if (ordereItemIds.size() > 200) {
                List<OrderItem> contractUpdates = new List<OrderItem>();
                for (Integer i = 0; i < 200; i++) {
                    contractUpdates.add(new OrderItem(Id = ordereItemIds[i], SBQQ__Contracted__c = true));
                }
                handleDatabaseResults(Database.update(contractUpdates, false), 'Updating Contracted Flag');
            }

            // 3) Restore SBQQ__RequiredBy__c for ALL OrderItems using the map
            List<OrderItem> restoreList = new List<OrderItem>();
            for (Id oiId : requiredByMapInternal.keySet()) {
                restoreList.add(new OrderItem(Id = oiId, SBQQ__RequiredBy__c = requiredByMapInternal.get(oiId)));
            }
            if (!restoreList.isEmpty()) {
                handleDatabaseResults(Database.update(restoreList, false), 'Restoring RequiredBy');
            }

        } catch (Exception e) {
            logsToInsert.add(
                UtilityClass.createlogExceptionRecord( e, 'BulkOrderItemsToConctract', 'execute', 'OrderItem', orderId, 'Error', false, null)
            );
        } finally {
            TriggerControl.stopOrderTrigger = false;
            
            if (!logsToInsert.isEmpty()) {
                insert logsToInsert;
            }
        }
    }
    
    /**
     * @description Helper to parse Database results and generate log records
     * @param results
     * @param stepContext
     */
    @TestVisible
    private void handleDatabaseResults(Database.SaveResult[] results, String stepContext) {
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                String errors = '';
                for(Database.Error err : sr.getErrors()) {
                    errors += err.getMessage() + '; ';
                }
                
                // Call your logging method for each failure
                logsToInsert.add(
                    UtilityClass.createlogExceptionRecord(null, 'BulkOrderItemsToConctract',  'execute:' + stepContext,'OrderItem',  sr.getId() != null ? sr.getId() : orderId, 'Database Error',  false,  'Step: ' + stepContext + ' - ' + errors
                    )
                );
            }
        }
    }
}