/**
 * @author Abhishek Mahajan
 * @date 2023-07-20
 * @description Controller to CxRelationshipQuickLinks
 */
public class CxRelatedQuickLinksController {
    private Static final String EXCEPTION_MSG = 'Something went wrong, Please contact Administrator';

    /**
     * Wrapper to be cosumed directly in UI
     */
    public class RelatedQuickLink{
        /** icon name of related object example : standard:account */
        @AuraEnabled
        public String iconName {get; set;}
        /** label of related object */
        @AuraEnabled
        public String label {get; set;}
        /** relationshipApiName of related object */
        @AuraEnabled
        public String relationshipApiName {get; set;}
        /** targetApiName of related object */
        @AuraEnabled
        public String targetApiName {get; set;}
        /** count of total related objects */
        @AuraEnabled
        public String count {get; set;}
        /** sorting order of item in list */
        @AuraEnabled
        public Decimal sortOder {get; set;}

        /** constructor */
        public RelatedQuickLink(String i, String l, String r,String t,String c, Decimal s){
            iconName = i;
            label = l;
            relationshipApiName = r;
            targetApiName = t;
            count = c;
            sortOder = s;
        }
    }

    /**
     * @description Retrieves the API name of an SObject based on the specified record Id.
     * 
     * @param recordId (Input) The Id of the record whose API name needs to be fetched.
     * @return The API name of the SObject associated with the provided record Id.
     * @throws AuraHandledException If an error occurs.
     */
    public static String getSObjectApiNameById(Id recordId) {
        String apiName;
        try {
            SObjectType sObjectType = recordId.getSObjectType();
            apiName = sObjectType.getDescribe().getName();
        } catch (Exception e) {
            throw new AuraHandledException(EXCEPTION_MSG);
        }
        return apiName;
    }

    /**
     * @description Retrieves metadata records of Relationship Quick Links for the specified target object.
     * 
     * @param recordId (Input) The Id of the target object for which metadata records need to be fetched.
     * @return List of CX_Related_Quick_Link__mdt records associated with the target object.
     */
    @AuraEnabled(cacheable=true)
    public static List<CX_Related_Quick_Link__mdt> getMetadataRecordsByTargetObject(Id recordId) {
        String targetApiName = getSObjectApiNameById(recordId);
        return [SELECT iconName__c, Label, relationshipApiName__c, targetApiName__c, Sort_Order__c FROM CX_Related_Quick_Link__mdt WHERE targetApiName__c =:targetApiName ORDER BY Sort_Order__c];
    }

    /**
     * @description Retrieves Related List of specified target object type with count of related objects
     * 
     * @param recordId (Input) The Id of the target object for which related records need to be fetched.
     * @return List of RelatedQuickLink objects containing details of the relationship links.
     * @throws AuraHandledException If an error occurs while querying the database.
     */
    @AuraEnabled(cacheable=true)
    public static List<RelatedQuickLink> getRelatedQuickLinks(Id recordId) {
        String targetApiName = getSObjectApiNameById(recordId);
		List<RelatedQuickLink> relatedQuickLinks = new List<RelatedQuickLink>();
        List<CX_Related_Quick_Link__mdt> configs = getMetadataRecordsByTargetObject(recordId);
        
        if(configs.isEmpty()){
            return relatedQuickLinks;
        }
        
        List<String> relationshipQueries = new List<String>();
        for (CX_Related_Quick_Link__mdt config : configs) {
            String relationShipQuery = '(SELECT Id FROM '+ config.relationshipApiName__c +' LIMIT 11)';
            relationshipQueries.add(relationShipQuery);
        }
        String soqlQuery =  'SELECT '+ String.join(relationshipQueries,',')+' FROM '+targetApiName+' WHERE Id = \''+String.escapeSingleQuotes(recordId)+'\'';

        try{
            List<SObject> sObjects = Database.query(soqlQuery);
            if (!sObjects.isEmpty()) {
                SObject sObj = sObjects[0];
                for (CX_Related_Quick_Link__mdt c : configs) {
                    String count = '0';
                    List<SObject> relatedRecords = sObj.getSObjects(c.relationshipApiName__c);
                    if (relatedRecords != null) {
                        count = relatedRecords.size() <= 10 ? String.valueOf(relatedRecords.size()) : '10+';
                    }
                    relatedQuickLinks.add(new RelatedQuickLink(c.iconName__c,c.Label,c.relationshipApiName__c,c.targetApiName__c,count,c.Sort_Order__c));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(EXCEPTION_MSG);
        }
        
        return relatedQuickLinks;
    }
}