trigger ContentDocumentTrigger on ContentDocument (before delete) {
    //get prefix of Inventory exception record.
    Schema.DescribeSObjectResult inv = Entitlement_Warranty_Details__c.sObjectType.getDescribe();
    String invKeyPrefix = inv.getKeyPrefix();
    
    List<Id> contentDocId = new List<Id>();
    Map<Id, Id> contDocLinkedMap = new Map<Id, Id>();
    if(trigger.IsDelete){
        for(ContentDocument con : Trigger.old){
            System.debug(Trigger.old);
            System.debug(con.Id);
            contentDocId.add(con.Id);
        }
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId,LinkedEntity.Type FROM ContentDocumentLink WHERE ContentDocumentId IN : contentDocId]){
            if (cdl.LinkedEntity.Type == 'Entitlement_Warranty_Details__c') {
               contDocLinkedMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId); 
            }
            
            System.debug('map ' +contDocLinkedMap);
            
            
        }
        
        for(ContentDocument cdoc : Trigger.Old){
            //contDocLinkedMap.get(cdoc.Id) will give the LinkedEntityId
            if(contDocLinkedMap.get(cdoc.Id) != null && invKeyPrefix == String.valueOf(contDocLinkedMap.get(cdoc.Id)).left(3)){
                   cdoc.adderror('can not delete this attachment as it is linked with Entitlement Warranty Record');
               }
            
        }
    }
}